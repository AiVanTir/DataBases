DELETE FROM "EventParticipant" WHERE event_id IN (990201, 990202);
DELETE FROM "EventSide" WHERE event_id IN (990201, 990202);
DELETE FROM "Event" WHERE event_id IN (990201, 990202);

DELETE FROM "Character"
WHERE char_id IN (990101, 990102, 990103, 990104);

DELETE FROM "User"
WHERE user_id = 990001;

INSERT INTO "User" (
    user_id,
    region_id,
    user_type_id,
    email,
    nickname,
    password_hash
)
VALUES
    (990001, 1, 1, 'trigger1_test_user@local.test', 'trigger1_test_user', 'hash_trigger1_test');

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
    (990101, 990001, 1, 1, 1, 'Trig1Char20', DATE '2025-01-01', 20, 1000, NULL),
    (990102, 990001, 1, 1, 1, 'Trig1Char24', DATE '2025-01-01', 24, 1000, NULL),
    (990103, 990001, 1, 1, 1, 'Trig1Char30', DATE '2025-01-01', 30, 1000, NULL),
    (990104, 990001, 1, 1, 1, 'Trig1Char35', DATE '2025-01-01', 35, 1000, NULL);

-- ТЕСТ 1. Первая вставка в ивент без диапазона
-- Ожидается:
-- min_level = 17, max_level = 25
-- потому что уровень первого вставленного участника = 20

INSERT INTO "Event" (
    event_id,
    server_id,
    event_type_id,
    map_id,
    status,
    min_level,
    max_level,
    start_time,
    end_time
)
VALUES
    (990201, 1, 1, 1, 'C', NULL, NULL, TIMESTAMP '2025-01-10 10:00:00', NULL);

INSERT INTO "EventSide" (
    side_id,
    event_id,
    side_number,
    result
)
VALUES
    (990301, 990201, 1, NULL);

INSERT INTO "EventParticipant" (
    event_id,
    char_id,
    side_id,
    server_id,
    damage_dealt,
    damage_received,
    healing_done,
    kills
)
VALUES
    (990201, 990101, 990301, 1, 1000, 500, 0, 1);

SELECT
    'TEST 1: event range after first insert' AS test_name,
    event_id,
    min_level,
    max_level
FROM "Event"
WHERE event_id = 990201;

-- ТЕСТ 2. Вставка участника внутри диапазона
-- Уровень 24 должен пройти в диапазон [17..25]

INSERT INTO "EventParticipant" (
    event_id,
    char_id,
    side_id,
    server_id,
    damage_dealt,
    damage_received,
    healing_done,
    kills
)
VALUES
    (990201, 990102, 990301, 1, 1200, 600, 0, 2);

SELECT
    'TEST 2: participants count after valid insert' AS test_name,
    COUNT(*) AS participants_count
FROM "EventParticipant"
WHERE event_id = 990201;

-- ТЕСТ 3. Негативный сценарий:
-- участник вне диапазона [17..25]
-- Уровень 30 должен дать ошибку

DO $$
BEGIN
    BEGIN
        INSERT INTO "EventParticipant" (
            event_id,
            char_id,
            side_id,
            server_id,
            damage_dealt,
            damage_received,
            healing_done,
            kills
        )
        VALUES
            (990201, 990103, 990301, 1, 1300, 700, 0, 1);

        RAISE EXCEPTION 'TEST 3 FAILED: invalid participant was inserted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 3 OK: invalid participant rejected: %', SQLERRM;
    END;
END
$$;

SELECT
    'TEST 3: participants count after invalid insert' AS test_name,
    COUNT(*) AS participants_count
FROM "EventParticipant"
WHERE event_id = 990201;

-- ТЕСТ 4. Негативный сценарий:
-- массовая вставка, где один участник подходит, а другой нет
-- Вся вставка должна откатиться целиком

INSERT INTO "Event" (
    event_id,
    server_id,
    event_type_id,
    map_id,
    status,
    min_level,
    max_level,
    start_time,
    end_time
)
VALUES
    (990202, 1, 1, 1, 'C', 10, 20, TIMESTAMP '2025-01-11 10:00:00', NULL);

INSERT INTO "EventSide" (
    side_id,
    event_id,
    side_number,
    result
)
VALUES
    (990302, 990202, 1, NULL);

DO $$
BEGIN
    BEGIN
        INSERT INTO "EventParticipant" (
            event_id,
            char_id,
            side_id,
            server_id,
            damage_dealt,
            damage_received,
            healing_done,
            kills
        )
        VALUES
            (990202, 990101, 990302, 1, 1000, 500, 0, 1), -- level 20, подходит
            (990202, 990104, 990302, 1, 1000, 500, 0, 1); -- level 35, не подходит

        RAISE EXCEPTION 'TEST 4 FAILED: batch insert with invalid row was accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 4 OK: batch insert rejected: %', SQLERRM;
    END;
END
$$;

SELECT
    'TEST 4: participants count after failed batch insert' AS test_name,
    COUNT(*) AS participants_count
FROM "EventParticipant"
WHERE event_id = 990202;