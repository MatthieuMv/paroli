-- Run from upgrade_analysis after generating the pair reports.
CREATE TEMP VIEW pair_rows AS SELECT * FROM 'pair_outcomes.parquet';

-- A plain pair uses two equal faces. For [1,1,6], the equipped 1 permits
-- two orders for the remaining dice, while the equipped 6 permits just one.
WITH expected(effect, played_faces, equipped_face, ways, possible) AS (
    VALUES ('plain', [1,1], NULL, 1, 36),
           ('plain', [1,1,6], NULL, 3, 216),
           ('jackpot', [1,1], 1, 5, 36),
           ('jackpot', [1,1,6], 1, 10, 216),
           ('jackpot', [1,1,6], 6, 1, 216)
), actual AS (
    SELECT effect, played_faces, equipped_face, ways, possible FROM pair_rows
    WHERE effect IN ('plain', 'jackpot') AND played_faces IN ([1,1], [1,1,6])
), missing AS (FROM expected EXCEPT ALL FROM actual),
unexpected AS (FROM actual EXCEPT ALL FROM expected)
SELECT CASE WHEN EXISTS (FROM missing) OR EXISTS (FROM unexpected)
            THEN error('Wrong Pair placement weights') ELSE 'Pair placement weights passed' END;

-- With [1,1] played, each of the three held dice matches on exactly one side.
-- Enumerating all 6^3 held rolls gives weights 125, 75, 15, and 1.
SELECT CASE WHEN list(ways ORDER BY held_matches) = [125,75,15,1]
                 AND min(possible) = 7776 AND max(possible) = 7776
            THEN 'Held match weights passed' ELSE error('Wrong held match weights') END
FROM pair_rows WHERE effect = 'bench-warmers' AND played_faces = [1,1];
