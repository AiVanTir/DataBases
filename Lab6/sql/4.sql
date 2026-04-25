--4. Наибольшая непрерывная серия побед для заданного персонажа

WITH params AS (
    SELECT 900001::int AS target_char_id
),
ordered_battles AS (
    SELECT
        e.event_id,
        e.end_time AS event_date,
        es.result,
        SUM(
            CASE
                WHEN es.result = 'W' THEN 0
                ELSE 1
            END
        ) OVER (
            ORDER BY e.end_time, e.event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS streak_group
    FROM "EventParticipant" ep
    JOIN "Event" e
        ON e.event_id = ep.event_id
    JOIN "EventSide" es
        ON es.event_id = ep.event_id
       AND es.side_id = ep.side_id
    WHERE ep.char_id = (SELECT target_char_id FROM params)
      AND e.status = 'F'
),
win_battles AS (
    SELECT
        event_id,
        event_date,
        streak_group
    FROM ordered_battles
    WHERE result = 'W'
),
wins_numbered AS (
    SELECT
        event_id,
        event_date,
        streak_group,
        COUNT(*) OVER (
            PARTITION BY streak_group
        ) AS battles_count,
        ROW_NUMBER() OVER (
            PARTITION BY streak_group
            ORDER BY event_date, event_id
        ) AS rn_from_start,
        ROW_NUMBER() OVER (
            PARTITION BY streak_group
            ORDER BY event_date DESC, event_id DESC
        ) AS rn_from_end
    FROM win_battles
),
streaks AS (
    SELECT
        streak_group,
        MAX(CASE WHEN rn_from_start = 1 THEN event_id END) AS first_event_id,
        MAX(CASE WHEN rn_from_start = 1 THEN event_date END) AS first_event_date,
        MAX(battles_count) AS battles_count,
        MAX(CASE WHEN rn_from_end = 1 THEN event_id END) AS last_event_id,
        MAX(CASE WHEN rn_from_end = 1 THEN event_date END) AS last_event_date
    FROM wins_numbered
    GROUP BY streak_group
),
ranked_streaks AS (
    SELECT
        first_event_id,
        first_event_date,
        battles_count,
        last_event_id,
        last_event_date,
        ROW_NUMBER() OVER (
            ORDER BY battles_count DESC, first_event_date, first_event_id
        ) AS rn
    FROM streaks
)
SELECT
    first_event_id,
    first_event_date,
    battles_count,
    last_event_id,
    last_event_date
FROM ranked_streaks
WHERE rn = 1;