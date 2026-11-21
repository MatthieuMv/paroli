-- Cross-check the rebuilt category files against the shipped balance changes.
WITH examples AS (
    SELECT effect, state, gain FROM 'two_pairs_outcomes.parquet'
    WHERE state = 'fresh' AND played_faces = [2,2,3,3,6]
      AND (effect IN ('double-date', 'matchmaker') OR (effect = 'house-builder' AND equipped_face = 2))
)
SELECT CASE WHEN count(*) = 3 AND
       max(gain) FILTER (WHERE effect = 'double-date') = 255 AND
       max(gain) FILTER (WHERE effect = 'matchmaker') = 180 AND
       max(gain) FILTER (WHERE effect = 'house-builder') = 18.75
       THEN 'Two Pairs rewards passed' ELSE error('Wrong Two Pairs payouts') END
FROM examples;

-- The original play is measured after any growth was earned, never retroactively.
SELECT CASE WHEN list(gain ORDER BY state) = [30,40,80]
       THEN 'High Die clearing history passed' ELSE error('Wrong One-man Band history') END
FROM 'high_die_outcomes.parquet' WHERE effect = 'one-man-band' AND played_faces = [6];
