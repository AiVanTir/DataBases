-- 1. Получить статистику пользователя с заданным id по всем его персонажам:
-- Каждая строка результата содержит: имя пользователя, имя персонажа,
-- id персонажа, дату регистрации персонажа на сервере, номер и регион сервера,
-- название расы, название фракции, общее количество боёв персонажа,
-- общее число поражений, общее число побед, общее число ничьих,
-- общий процент побед персонажа, а также эту же статистику
-- (число боев, побед, поражений, ничьих, % побед в каждом из трех типов боев).
-- Общее число строк равно числу персонажей пользователя.

WITH params AS (
    SELECT 5::int AS target_user_id
),
user_characters AS (
    SELECT
        u.user_id,
        u.nickname AS user_name,
        ch.char_id,
        ch.name AS character_name,
        ch.registration_date,
        s.server_id,
        s.name AS server_name,
        rg.name AS server_region,
        r.name AS race_name,
        f.name AS faction_name
    FROM "User" u
    JOIN "Character" ch
        ON ch.user_id = u.user_id
    JOIN "Server" s
        ON s.server_id = ch.server_id
    JOIN "Region" rg
        ON rg.region_id = s.region_id
    JOIN "Race" r
        ON r.race_id = ch.race_id
    JOIN "Faction" f
        ON f.faction_id = r.faction_id
    WHERE u.user_id = (SELECT target_user_id FROM params)
),
character_stats AS (
    SELECT
        ep.char_id,

        COUNT(*) AS total_battles,
        COUNT(*) FILTER (WHERE es.result = 'W') AS total_wins,
        COUNT(*) FILTER (WHERE es.result = 'L') AS total_losses,
        COUNT(*) FILTER (WHERE es.result = 'D') AS total_draws,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (WHERE es.result = 'W')
                / NULLIF(COUNT(*), 0)
            )::numeric,
            2
        ) AS total_win_pct,

        COUNT(*) FILTER (WHERE et.name = 'dungeon') AS dungeon_battles,
        COUNT(*) FILTER (WHERE et.name = 'dungeon' AND es.result = 'W') AS dungeon_wins,
        COUNT(*) FILTER (WHERE et.name = 'dungeon' AND es.result = 'L') AS dungeon_losses,
        COUNT(*) FILTER (WHERE et.name = 'dungeon' AND es.result = 'D') AS dungeon_draws,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (WHERE et.name = 'dungeon' AND es.result = 'W')
                / NULLIF(COUNT(*) FILTER (WHERE et.name = 'dungeon'), 0)
            )::numeric,
            2
        ) AS dungeon_win_pct,

        COUNT(*) FILTER (WHERE et.name = 'raid') AS raid_battles,
        COUNT(*) FILTER (WHERE et.name = 'raid' AND es.result = 'W') AS raid_wins,
        COUNT(*) FILTER (WHERE et.name = 'raid' AND es.result = 'L') AS raid_losses,
        COUNT(*) FILTER (WHERE et.name = 'raid' AND es.result = 'D') AS raid_draws,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (WHERE et.name = 'raid' AND es.result = 'W')
                / NULLIF(COUNT(*) FILTER (WHERE et.name = 'raid'), 0)
            )::numeric,
            2
        ) AS raid_win_pct,

        COUNT(*) FILTER (WHERE et.name = 'battleground') AS battleground_battles,
        COUNT(*) FILTER (WHERE et.name = 'battleground' AND es.result = 'W') AS battleground_wins,
        COUNT(*) FILTER (WHERE et.name = 'battleground' AND es.result = 'L') AS battleground_losses,
        COUNT(*) FILTER (WHERE et.name = 'battleground' AND es.result = 'D') AS battleground_draws,
        ROUND(
            (
                100.0 * COUNT(*) FILTER (WHERE et.name = 'battleground' AND es.result = 'W')
                / NULLIF(COUNT(*) FILTER (WHERE et.name = 'battleground'), 0)
            )::numeric,
            2
        ) AS battleground_win_pct
    FROM "EventParticipant" ep
    JOIN "Event" e
        ON e.event_id = ep.event_id
    JOIN "EventType" et
        ON et.event_type_id = e.event_type_id
    JOIN "EventSide" es
        ON es.event_id = ep.event_id
       AND es.side_id = ep.side_id
    GROUP BY ep.char_id
)
SELECT
    uc.user_name,
    uc.character_name,
    uc.char_id,
    uc.registration_date,
    uc.server_id,
    uc.server_region,
    uc.race_name,
    uc.faction_name,

    COALESCE(cs.total_battles, 0) AS total_battles,
    COALESCE(cs.total_losses, 0) AS total_losses,
    COALESCE(cs.total_wins, 0) AS total_wins,
    COALESCE(cs.total_draws, 0) AS total_draws,
    COALESCE(cs.total_win_pct, 0) AS total_win_pct,

    COALESCE(cs.dungeon_battles, 0) AS dungeon_battles,
    COALESCE(cs.dungeon_wins, 0) AS dungeon_wins,
    COALESCE(cs.dungeon_losses, 0) AS dungeon_losses,
    COALESCE(cs.dungeon_draws, 0) AS dungeon_draws,
    COALESCE(cs.dungeon_win_pct, 0) AS dungeon_win_pct,

    COALESCE(cs.raid_battles, 0) AS raid_battles,
    COALESCE(cs.raid_wins, 0) AS raid_wins,
    COALESCE(cs.raid_losses, 0) AS raid_losses,
    COALESCE(cs.raid_draws, 0) AS raid_draws,
    COALESCE(cs.raid_win_pct, 0) AS raid_win_pct,

    COALESCE(cs.battleground_battles, 0) AS battleground_battles,
    COALESCE(cs.battleground_wins, 0) AS battleground_wins,
    COALESCE(cs.battleground_losses, 0) AS battleground_losses,
    COALESCE(cs.battleground_draws, 0) AS battleground_draws,
    COALESCE(cs.battleground_win_pct, 0) AS battleground_win_pct
FROM user_characters uc
LEFT JOIN character_stats cs
    ON cs.char_id = uc.char_id
ORDER BY uc.char_id;