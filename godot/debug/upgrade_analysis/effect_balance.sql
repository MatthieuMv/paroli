-- Run from this directory with DuckDB. The two file families have different grains:
-- one row per equipped outcome vs. one row per summarized experiment.
SET VARIABLE balance_categories = [
    'high_die', 'pair', 'two_pairs', 'three_of_a_kind', 'short_straight',
    'full_house', 'four_of_a_kind', 'long_straight', 'five_of_a_kind'
];

CREATE OR REPLACE TEMP VIEW balance_detail AS
SELECT replace(parse_filename(filename, true), '_summary', '') AS play_style,
       * EXCLUDE (filename, high_die_input_probability, chance_of_gain_given_high_die)
FROM read_parquet(list_transform(getvariable('balance_categories'), lambda s: s || '_summary.parquet'),
                  filename = true, union_by_name = true);

-- Relative frequencies of selecting each hand size before seeing the dice.
CREATE OR REPLACE TEMP TABLE balance_hand_mix AS
SELECT * FROM (VALUES (1, 1), (2, 1), (3, 1), (4, 1), (5, 1)) AS mix(dice_played, frequency);

CREATE OR REPLACE TEMP TABLE balance_experiments AS
SELECT d.*, m.frequency,
       CASE WHEN state = 'previous_' || play_style THEN 'previous_same_style'
            ELSE state END AS scenario
FROM balance_detail d
JOIN balance_hand_mix m USING (dice_played)
WHERE frequency > 0
-- The support items have a held experiment whenever a die can be held.
QUALIFY row_number() OVER (
    PARTITION BY family, effect, play_style, dice_played, state
    ORDER BY (placement = 'held') DESC
) = 1;

-- Integrate across categories and hand sizes within a specified history only.
CREATE OR REPLACE TEMP VIEW balance_scenarios AS
SELECT family, effect, scenario,
       weighted_avg(mean_score, frequency * input_probability) AS mean_score,
       weighted_avg(mean_gain, frequency * input_probability) AS direct_gain,
       weighted_avg(chance_of_gain_given_input, frequency * input_probability) AS chance_of_gain,
       weighted_avg(mean_coins, frequency * input_probability) AS coins,
       max(extra_plays) AS extra_plays, max(extra_rerolls) AS extra_rerolls,
       max(sell_growth) AS sell_growth
FROM balance_experiments
GROUP BY family, effect, scenario;

-- Conditional mean point gain on the same faces, grouped by the plain input style.
CREATE OR REPLACE TEMP VIEW balance_styles AS
SELECT family, effect, scenario, play_style,
       weighted_avg(mean_gain, frequency * input_probability) AS style_gain,
       sum(frequency * input_probability) / (SELECT sum(frequency) FROM balance_hand_mix) AS style_probability
FROM balance_experiments
GROUP BY family, effect, scenario, play_style;

-- Scores from different hand sizes have denominators 6^n. Rescale before finding
-- the middle physical outcomes, preserving ties and avoiding averages of medians.
CREATE OR REPLACE TEMP VIEW balance_score_distribution AS
WITH outcomes AS (
    SELECT replace(parse_filename(filename, true), '_outcomes', '') AS play_style, *
    FROM read_parquet(list_transform(getvariable('balance_categories'), lambda s: s || '_outcomes.parquet'),
                      filename = true)
    WHERE state = 'fresh'
), weighted AS (
    SELECT family, effect, score,
           frequency::BIGINT * ways * (max(possible) OVER () // possible) AS weight
    FROM outcomes
    JOIN balance_experiments USING (family, effect, play_style, dice_played, state, placement)
), bins AS (
    SELECT family, effect, score, sum(weight) AS weight
    FROM weighted GROUP BY family, effect, score
), ranked AS (
    SELECT *, sum(weight) OVER item AS total,
           sum(weight) OVER (item ORDER BY score ROWS UNBOUNDED PRECEDING) AS through_score
    FROM bins WINDOW item AS (PARTITION BY family, effect)
)
SELECT family, effect, min(score) AS min_score, max(score) AS max_score,
       (min(score) FILTER (WHERE through_score >= (total + 1) // 2)
      + min(score) FILTER (WHERE through_score >= (total + 2) // 2)) / 2 AS median_score
FROM ranked GROUP BY family, effect;

CREATE OR REPLACE TEMP TABLE effect_balance AS
WITH matrix AS (
    PIVOT (SELECT family, effect, play_style, style_gain FROM balance_styles WHERE scenario = 'fresh')
    ON play_style IN ('high_die', 'pair', 'two_pairs', 'three_of_a_kind', 'short_straight',
                      'full_house', 'four_of_a_kind', 'long_straight', 'five_of_a_kind')
    USING first(style_gain)
), baseline AS (
    SELECT mean_score FROM balance_scenarios WHERE family = 'plain' AND scenario = 'fresh'
)
SELECT dense_rank() OVER (ORDER BY round(s.mean_score, 10) DESC) AS score_rank,
       s.family, s.effect, (s.mean_score - baseline.mean_score)::DECIMAL(20,10) AS net_gain,
       s.direct_gain, s.chance_of_gain, s.mean_score, d.median_score, d.min_score, d.max_score,
       matrix.* EXCLUDE (family, effect), s.coins, s.extra_plays, s.extra_rerolls, s.sell_growth
FROM balance_scenarios s
JOIN matrix USING (family, effect)
JOIN balance_score_distribution d USING (family, effect)
CROSS JOIN baseline
WHERE s.scenario = 'fresh' AND s.family <> 'plain';

COPY (SELECT * FROM effect_balance ORDER BY score_rank, effect)
TO 'effect_balance.parquet' (FORMAT PARQUET);
