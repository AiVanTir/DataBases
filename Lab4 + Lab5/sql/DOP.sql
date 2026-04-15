WITH damage_by_character AS (
    SELECT
        s.name AS server_name,
        ch.char_id,
        ch.name AS character_name,
        cl.name AS class_name,
        SUM(ep.damage_dealt) AS total_damage,
        SUM(ep.kills) AS total_kills,
        COUNT(DISTINCT ep.event_id) AS events_count
    FROM "EventParticipant" ep
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    JOIN "Server" s
        ON s.server_id = ch.server_id
    JOIN "Class" cl
        ON cl.class_id = ch.class_id
    GROUP BY
        s.name,
        ch.char_id,
        ch.name,
        cl.name
),
ranked AS (
    SELECT
        server_name,
        char_id,
        character_name,
        class_name,
        total_damage,
        total_kills,
        events_count,
        DENSE_RANK() OVER (
            PARTITION BY server_name
            ORDER BY total_damage DESC
        ) AS damage_rank_on_server
    FROM damage_by_character
)
SELECT
    server_name,
    damage_rank_on_server,
    char_id,
    character_name,
    class_name,
    total_damage,
    total_kills,
    events_count
FROM ranked
WHERE damage_rank_on_server <= 3
ORDER BY server_name, damage_rank_on_server, character_name;