-- Находит персонажей, у которых отсутствуют записи в таблице Ban

WITH character_bans AS (
    SELECT
        ch.char_id,
        ch.name AS character_name,
        s.name AS server_name,
        r.name AS race_name,
        cl.name AS class_name,
        ch.level,
        b.ban_id
    FROM "Character" ch
    JOIN "Server" s
        ON s.server_id = ch.server_id
    JOIN "Race" r
        ON r.race_id = ch.race_id
    JOIN "Class" cl
        ON cl.class_id = ch.class_id
    LEFT JOIN "Ban" b
        ON b.char_id = ch.char_id
),
not_banned AS (
    SELECT
        char_id,
        character_name,
        server_name,
        race_name,
        class_name,
        level
    FROM character_bans
    WHERE ban_id IS NULL
)
SELECT
    char_id,
    character_name,
    server_name,
    race_name,
    class_name,
    level
FROM not_banned
ORDER BY server_name, level DESC, character_name;