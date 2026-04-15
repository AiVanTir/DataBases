-- Для каждого участия персонажа в событии считает накопительный итог по текущему и двум предыдущим событиям: урон, лечение, убийства.

WITH char_event_stats AS (
    SELECT
        ch.char_id,
        ch.name AS character_name,
        e.event_id,
        e.end_time,
        ep.damage_dealt,
        ep.healing_done,
        ep.kills
    FROM "EventParticipant" ep
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    JOIN "Event" e
        ON e.event_id = ep.event_id
    WHERE e.status = 'F'
),
rolling_stats AS (
    SELECT
        char_id,
        character_name,
        event_id,
        end_time,
        damage_dealt,
        healing_done,
        kills,
        SUM(damage_dealt) OVER (
            PARTITION BY char_id
            ORDER BY end_time
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS damage_last_3_events,
        SUM(healing_done) OVER (
            PARTITION BY char_id
            ORDER BY end_time
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS healing_last_3_events,
        SUM(kills) OVER (
            PARTITION BY char_id
            ORDER BY end_time
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS kills_last_3_events
    FROM char_event_stats
)
SELECT
    char_id,
    character_name,
    event_id,
    end_time,
    damage_dealt,
    healing_done,
    kills,
    damage_last_3_events,
    healing_last_3_events,
    kills_last_3_events
FROM rolling_stats
ORDER BY character_name, end_time;