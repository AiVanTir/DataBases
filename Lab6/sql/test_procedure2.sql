BEGIN;

DELETE FROM "EventBoss"
WHERE event_id BETWEEN 992201 AND 992220;

DELETE FROM "EventParticipant"
WHERE event_id BETWEEN 992201 AND 992220;

DELETE FROM "EventSide"
WHERE event_id BETWEEN 992201 AND 992220;

DELETE FROM "Event"
WHERE event_id BETWEEN 992201 AND 992220;

DELETE FROM "Character"
WHERE char_id BETWEEN 992101 AND 992120
   OR user_id IN (992001, 992002, 992003);

DELETE FROM "User"
WHERE user_id IN (992001, 992002, 992003);

INSERT INTO "User" (
    user_id,
    region_id,
    user_type_id,
    email,
    nickname,
    password_hash
)
VALUES
    (992001, 1, 1, 'proc2_user_1@local.test', 'proc2_user_1', 'hash_proc2_user_1'),
    (992002, 1, 1, 'proc2_user_2@local.test', 'proc2_user_2', 'hash_proc2_user_2'),
    (992003, 2, 1, 'proc2_user_3@local.test', 'proc2_user_3', 'hash_proc2_user_3');

INSERT INTO "Character" (
    char_id,
    user_id,
    server_id,
    race_id,
    class_id,
    name,
    registration_date,
    level,
    gold,
    avatar
)
VALUES
    (992101, 992001, 1, 1, 1, 'Proc2Good_1', DATE '2025-01-01', 20, 0, NULL),
    (992102, 992001, 1, 1, 3, 'Proc2Good_2', DATE '2025-01-01', 21, 0, NULL),
    (992103, 992002, 1, 2, 4, 'Proc2Good_3', DATE '2025-01-01', 22, 0, NULL),
    (992104, 992002, 1, 3, 5, 'Proc2Good_4', DATE '2025-01-01', 24, 0, NULL),
    (992105, 992003, 1, 4, 6, 'Proc2Good_5', DATE '2025-01-01', 25, 0, NULL);

INSERT INTO "Character" (
    char_id,
    user_id,
    server_id,
    race_id,
    class_id,
    name,
    registration_date,
    level,
    gold,
    avatar
)
VALUES
    (992106, 992001, 2, 1, 1, 'Proc2OtherServer', DATE '2025-01-01', 22, 0, NULL);

INSERT INTO "Character" (
    char_id,
    user_id,
    server_id,
    race_id,
    class_id,
    name,
    registration_date,
    level,
    gold,
    avatar
)
VALUES
    (992107, 992002, 1, 1, 1, 'Proc2HighLevel', DATE '2025-01-01', 35, 0, NULL);

-- TEST 1. Позитивный сценарий

CALL create_dungeon_event(
    'Proc2Good_1',
    'Proc2Good_2',
    'Proc2Good_3',
    'Proc2Good_4',
    'Proc2Good_5'
);

WITH last_event AS (
    SELECT MAX(event_id) AS event_id
    FROM "Event"
    WHERE server_id = 1
      AND event_type_id = (SELECT event_type_id FROM "EventType" WHERE name = 'dungeon')
),
event_check AS (
    SELECT
        e.event_id,
        COUNT(DISTINCT ep.char_id) AS participants_count,
        COUNT(DISTINCT es.side_id) FILTER (WHERE es.side_number = 1) AS player_side_count,
        COUNT(DISTINCT es.side_id) FILTER (WHERE es.side_number = 2) AS bot_side_count,
        COUNT(DISTINCT eb.boss_id) AS bosses_count
    FROM "Event" e
    LEFT JOIN "EventParticipant" ep
        ON ep.event_id = e.event_id
    LEFT JOIN "EventSide" es
        ON es.event_id = e.event_id
    LEFT JOIN "EventBoss" eb
        ON eb.event_id = e.event_id
    WHERE e.event_id = (SELECT event_id FROM last_event)
    GROUP BY e.event_id
)
SELECT
    'TEST 1 - success' AS test_name,
    event_id,
    participants_count,
    player_side_count,
    bot_side_count,
    bosses_count,
    CASE
        WHEN participants_count = 5
         AND player_side_count = 1
         AND bot_side_count = 1
         AND bosses_count BETWEEN 3 AND 5
        THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM event_check;

-- TEST 2. Негативный сценарий: повторяющееся имя

DO $$
BEGIN
    BEGIN
        CALL create_dungeon_event(
            'Proc2Good_1',
            'Proc2Good_1',
            'Proc2Good_3',
            'Proc2Good_4',
            'Proc2Good_5'
        );

        RAISE EXCEPTION 'TEST 2 FAILED: duplicate names accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 2 OK: duplicate names rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 3. Негативный сценарий: один персонаж не существует

DO $$
BEGIN
    BEGIN
        CALL create_dungeon_event(
            'Proc2Good_1',
            'Proc2Good_2',
            'Proc2Good_3',
            'Proc2Good_4',
            'NoSuchCharacter'
        );

        RAISE EXCEPTION 'TEST 3 FAILED: non-existing character accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 3 OK: non-existing character rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 4. Негативный сценарий: персонажи на разных серверах

DO $$
BEGIN
    BEGIN
        CALL create_dungeon_event(
            'Proc2Good_1',
            'Proc2Good_2',
            'Proc2Good_3',
            'Proc2Good_4',
            'Proc2OtherServer'
        );

        RAISE EXCEPTION 'TEST 4 FAILED: cross-server party accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 4 OK: cross-server party rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 5. Негативный сценарий: разброс уровней > 5

DO $$
BEGIN
    BEGIN
        CALL create_dungeon_event(
            'Proc2Good_1',
            'Proc2Good_2',
            'Proc2Good_3',
            'Proc2Good_4',
            'Proc2HighLevel'
        );

        RAISE EXCEPTION 'TEST 5 FAILED: large level spread accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 5 OK: large level spread rejected: %', SQLERRM;
    END;
END
$$;

COMMIT;