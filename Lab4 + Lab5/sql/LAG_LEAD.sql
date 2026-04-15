-- Для каждого участия персонажа в событии показывает:
--текущий урон
--урон в предыдущем событии
--урон в следующем событии
--изменение урона относительно предыдущего участия

WITH participation AS (
    SELECT
        ch.char_id,
        ch.name AS character_name,
        et.name AS event_type,
        e.event_id,
        e.end_time,
        ep.damage_dealt,
        ep.kills
    FROM "EventParticipant" ep
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    JOIN "Event" e
        ON e.event_id = ep.event_id
    JOIN "EventType" et
        ON et.event_type_id = e.event_type_id
    WHERE e.status = 'F'
),
with_shift AS (
    SELECT
        char_id,
        character_name,
        event_type,
        event_id,
        end_time,
        damage_dealt,
        kills,
        LAG(damage_dealt) OVER (
            PARTITION BY char_id
            ORDER BY end_time
        ) AS prev_damage,
        LEAD(damage_dealt) OVER (
            PARTITION BY char_id
            ORDER BY end_time
        ) AS next_damage
    FROM participation
)
SELECT
    char_id,
    character_name,
    event_type,
    event_id,
    end_time,
    damage_dealt,
    prev_damage,
    next_damage,
    damage_dealt - prev_damage AS damage_change_from_prev
FROM with_shift
WHERE prev_damage IS NOT NULL
ORDER BY character_name, end_time;