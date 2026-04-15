-- Показывает завершённые события, их сервер, тип, карту, число участников, средний уровень персонажей, общий урон, лечение и убийства.
-- Используется соединение 6 таблиц и фильтрация только тех событий, где было не менее 5 участников

WITH event_report AS (
    SELECT
        e.event_id,
        s.name AS server_name,
        et.name AS event_type,
        m.name AS map_name,
        COUNT(DISTINCT ep.char_id) AS participants_count,
        ROUND(AVG(ch.level)::numeric, 2) AS avg_character_level,
        SUM(ep.damage_dealt) AS total_damage,
        SUM(ep.healing_done) AS total_healing,
        SUM(ep.kills) AS total_kills
    FROM "Event" e
    JOIN "Server" s
        ON s.server_id = e.server_id
    JOIN "EventType" et
        ON et.event_type_id = e.event_type_id
    JOIN "Map" m
        ON m.map_id = e.map_id
    JOIN "EventParticipant" ep
        ON ep.event_id = e.event_id
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    WHERE e.status = 'F'
      AND et.name IN ('dungeon', 'raid', 'battleground')
    GROUP BY
        e.event_id,
        s.name,
        et.name,
        m.name
    HAVING COUNT(DISTINCT ep.char_id) >= 5
)
SELECT
    event_id,
    server_name,
    event_type,
    map_name,
    participants_count,
    avg_character_level,
    total_damage,
    total_healing,
    total_kills
FROM event_report
ORDER BY total_damage DESC, event_id;