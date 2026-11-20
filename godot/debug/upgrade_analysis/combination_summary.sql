WITH ranked AS (
    SELECT *,
           sum(ways) OVER experiment AS total,
           sum(ways) OVER (experiment ORDER BY score RANGE UNBOUNDED PRECEDING) AS through_score,
           max(score) OVER experiment AS best
    FROM outcomes
    WINDOW experiment AS (PARTITION BY family, effect, state, placement, dice_played)
)
SELECT family, effect, state, placement, dice_played,
       sum(ways)::DOUBLE / max(possible) AS input_probability,
       sum(ways * score) / max(total) AS mean_score,
       (min(score) FILTER (WHERE through_score >= (total + 1) // 2) +
        min(score) FILTER (WHERE through_score >= (total + 2) // 2)) / 2 AS median_score,
       min(score) AS min_score, max(score) AS max_score,
       sum(ways * (score - plain_score)) / max(total) AS mean_gain,
       sum(CASE WHEN score > plain_score THEN ways ELSE 0 END)::DOUBLE / max(total) AS chance_of_gain_given_input,
       sum(CASE WHEN score = best THEN ways ELSE 0 END)::DOUBLE / max(possible) AS chance_of_best_per_roll,
       sum(ways * coins)::DOUBLE / max(total) AS mean_coins,
       max(extra_plays) AS extra_plays, max(extra_rerolls) AS extra_rerolls,
       max(sell_growth) AS sell_growth
FROM ranked
GROUP BY family, effect, state, placement, dice_played
ORDER BY dice_played, placement, state, mean_gain DESC, effect
