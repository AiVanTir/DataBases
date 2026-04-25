--Статистика по используемым типам боссов

WITH boss_events AS (
    SELECT
        b.boss_id,
        b.name AS boss_name,
        eb.event_id,
        eb.side_id AS boss_side_id
    FROM "Boss" b
    JOIN "EventBoss" eb
        ON eb.boss_id = b.boss_id
),
event_results AS (
    SELECT
        be.boss_id,
        be.boss_name,
        be.event_id,
        be.boss_side_id,
        es.result AS boss_side_result
    FROM boss_events be
    JOIN "EventSide" es
        ON es.event_id = be.event_id
       AND es.side_id = be.boss_side_id
),
survival_stats AS (
    SELECT
        be.boss_id,
        be.event_id,
        AVG(
            CASE
                WHEN ep.damage_received < ep.damage_dealt + ep.healing_done THEN 1.0
                ELSE 0.0
            END
        ) AS avg_survival_rate
    FROM boss_events be
    JOIN "EventParticipant" ep
        ON ep.event_id = be.event_id
    GROUP BY
        be.boss_id,
        be.event_id
),
opponent_levels AS (
    SELECT
        be.boss_id,
        be.event_id,
        AVG(ch.level::numeric) AS avg_opponent_level
    FROM boss_events be
    JOIN "EventParticipant" ep
        ON ep.event_id = be.event_id
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    JOIN "EventSide" es
        ON es.event_id = ep.event_id
       AND es.side_id = ep.side_id
    WHERE ep.side_id <> be.boss_side_id
       OR NOT EXISTS (
            SELECT 1
            FROM "EventParticipant" ep2
            WHERE ep2.event_id = be.event_id
              AND ep2.side_id <> be.boss_side_id
       )
    GROUP BY
        be.boss_id,
        be.event_id
),
ally_boss_levels AS (
    SELECT
        eb1.boss_id,
        eb1.event_id,
        AVG(b2.level::numeric) AS avg_ally_boss_level
    FROM "EventBoss" eb1
    JOIN "EventBoss" eb2
        ON eb2.event_id = eb1.event_id
       AND eb2.side_id = eb1.side_id
       AND eb2.boss_id <> eb1.boss_id
    JOIN "Boss" b2
        ON b2.boss_id = eb2.boss_id
    GROUP BY
        eb1.boss_id,
        eb1.event_id
),
boss_report AS (
    SELECT
        er.boss_name,
        COUNT(DISTINCT er.event_id) AS battles_count,
        COUNT(DISTINCT er.event_id) FILTER (WHERE er.boss_side_result = 'W') AS wins_count,
        AVG(ss.avg_survival_rate) AS avg_survival_rate,
        AVG(ol.avg_opponent_level) AS avg_opponent_level,
        AVG(COALESCE(abl.avg_ally_boss_level, 0)) AS avg_ally_boss_level
    FROM event_results er
    LEFT JOIN survival_stats ss
        ON ss.boss_id = er.boss_id
       AND ss.event_id = er.event_id
    LEFT JOIN opponent_levels ol
        ON ol.boss_id = er.boss_id
       AND ol.event_id = er.event_id
    LEFT JOIN ally_boss_levels abl
        ON abl.boss_id = er.boss_id
       AND abl.event_id = er.event_id
    GROUP BY er.boss_name
)
SELECT
    boss_name,
    battles_count,
    wins_count,
    ROUND(avg_survival_rate::numeric * 100, 2) AS avg_survival_pct,
    ROUND(avg_opponent_level::numeric, 2) AS avg_opponent_level,
    ROUND(avg_ally_boss_level::numeric, 2) AS avg_ally_boss_level
FROM boss_report
ORDER BY avg_survival_pct DESC, battles_count DESC, boss_name;