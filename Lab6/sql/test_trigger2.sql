BEGIN;

DELETE FROM "EventBoss"
WHERE event_id IN (990601, 990602, 990603, 990604, 990605);

DELETE FROM "EventSide"
WHERE event_id IN (990601, 990602, 990603, 990604, 990605);

DELETE FROM "Event"
WHERE event_id IN (990601, 990602, 990603, 990604, 990605);

DELETE FROM "DungeonBossPool"
WHERE map_id IN (990401, 990402, 990403);

DELETE FROM "Map"
WHERE map_id IN (990401, 990402, 990403);

DELETE FROM "Boss"
WHERE boss_id BETWEEN 990501 AND 990508;

INSERT INTO "Boss" (boss_id, name, level) VALUES
    (990501, 'Test Boss 1', 20),
    (990502, 'Test Boss 2', 21),
    (990503, 'Test Boss 3', 22),
    (990504, 'Test Boss 4', 23),
    (990505, 'Test Boss 5', 24),
    (990506, 'Test Boss 6', 25),
    (990507, 'Test Boss 7', 26),
    (990508, 'Test Boss 8', 27);

-- Подготовка тестовых карт
-- 990401 - dungeon, 5 боссов
-- 990402 - raid, 8 боссов
-- 990403 - raid, только 3 босса (для негативного теста)
INSERT INTO "Map" (map_id, event_type_id, name) VALUES
    (990401, (SELECT event_type_id FROM "EventType" WHERE name = 'dungeon'), 'Test Dungeon Map'),
    (990402, (SELECT event_type_id FROM "EventType" WHERE name = 'raid'), 'Test Raid Map'),
    (990403, (SELECT event_type_id FROM "EventType" WHERE name = 'raid'), 'Test Raid Bad Map');

INSERT INTO "DungeonBossPool" (map_id, boss_id) VALUES
    -- dungeon map: 5 боссов
    (990401, 990501),
    (990401, 990502),
    (990401, 990503),
    (990401, 990504),
    (990401, 990505),

    -- raid map: 8 боссов
    (990402, 990501),
    (990402, 990502),
    (990402, 990503),
    (990402, 990504),
    (990402, 990505),
    (990402, 990506),
    (990402, 990507),
    (990402, 990508),

    -- bad raid map: только 3 босса
    (990403, 990501),
    (990403, 990502),
    (990403, 990503);

-- TEST 1. Позитивный сценарий: dungeon
-- Ожидается:
-- - создаётся side_number = 2
-- - добавляется от 3 до 5 боссов=
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
VALUES (
    990601,
    1,
    (SELECT event_type_id FROM "EventType" WHERE name = 'dungeon'),
    990401,
    'C',
    NULL,
    NULL,
    TIMESTAMP '2025-02-01 10:00:00',
    NULL
);

WITH t AS (
    SELECT
        e.event_id,
        COUNT(DISTINCT es.side_id) FILTER (WHERE es.side_number = 2) AS bot_side_count,
        COUNT(DISTINCT eb.boss_id) AS bosses_count
    FROM "Event" e
    LEFT JOIN "EventSide" es
        ON es.event_id = e.event_id
    LEFT JOIN "EventBoss" eb
        ON eb.event_id = e.event_id
    WHERE e.event_id = 990601
    GROUP BY e.event_id
)
SELECT
    'TEST 1 - dungeon' AS test_name,
    event_id,
    bot_side_count,
    bosses_count,
    CASE
        WHEN bot_side_count = 1 AND bosses_count BETWEEN 3 AND 5 THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM t;

-- TEST 2. Позитивный сценарий: raid
-- Ожидается:
-- - создаётся side_number = 2
-- - добавляется от 4 до 8 боссов
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
VALUES (
    990602,
    1,
    (SELECT event_type_id FROM "EventType" WHERE name = 'raid'),
    990402,
    'C',
    NULL,
    NULL,
    TIMESTAMP '2025-02-02 10:00:00',
    NULL
);

WITH t AS (
    SELECT
        e.event_id,
        COUNT(DISTINCT es.side_id) FILTER (WHERE es.side_number = 2) AS bot_side_count,
        COUNT(DISTINCT eb.boss_id) AS bosses_count
    FROM "Event" e
    LEFT JOIN "EventSide" es
        ON es.event_id = e.event_id
    LEFT JOIN "EventBoss" eb
        ON eb.event_id = e.event_id
    WHERE e.event_id = 990602
    GROUP BY e.event_id
)
SELECT
    'TEST 2 - raid' AS test_name,
    event_id,
    bot_side_count,
    bosses_count,
    CASE
        WHEN bot_side_count = 1 AND bosses_count BETWEEN 4 AND 8 THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM t;

-- TEST 3. Негативный сценарий:
-- raid-карта, где доступно только 3 босса
-- Ожидается ошибка и отсутствие ивента
DO $$
BEGIN
    BEGIN
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
        VALUES (
            990603,
            1,
            (SELECT event_type_id FROM "EventType" WHERE name = 'raid'),
            990403,
            'C',
            NULL,
            NULL,
            TIMESTAMP '2025-02-03 10:00:00',
            NULL
        );

        RAISE EXCEPTION 'TEST 3 FAILED: invalid event was created';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 3 OK: event creation rejected: %', SQLERRM;
    END;
END
$$;

SELECT
    'TEST 3 - insufficient bosses' AS test_name,
    COUNT(*) AS created_events_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM "Event"
WHERE event_id = 990603;

-- TEST 4. Множественная вставка
-- Одним INSERT создаются dungeon и raid
-- Ожидается:
-- - оба ивента обработаны
-- - у dungeon 3..5 боссов
-- - у raid 4..8 боссов

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
    (
        990604,
        1,
        (SELECT event_type_id FROM "EventType" WHERE name = 'dungeon'),
        990401,
        'C',
        NULL,
        NULL,
        TIMESTAMP '2025-02-04 10:00:00',
        NULL
    ),
    (
        990605,
        1,
        (SELECT event_type_id FROM "EventType" WHERE name = 'raid'),
        990402,
        'C',
        NULL,
        NULL,
        TIMESTAMP '2025-02-05 10:00:00',
        NULL
    );

WITH t AS (
    SELECT
        e.event_id,
        et.name AS event_type,
        COUNT(DISTINCT es.side_id) FILTER (WHERE es.side_number = 2) AS bot_side_count,
        COUNT(DISTINCT eb.boss_id) AS bosses_count
    FROM "Event" e
    JOIN "EventType" et
        ON et.event_type_id = e.event_type_id
    LEFT JOIN "EventSide" es
        ON es.event_id = e.event_id
    LEFT JOIN "EventBoss" eb
        ON eb.event_id = e.event_id
    WHERE e.event_id IN (990604, 990605)
    GROUP BY e.event_id, et.name
)
SELECT
    'TEST 4 - multi insert' AS test_name,
    event_id,
    event_type,
    bot_side_count,
    bosses_count,
    CASE
        WHEN event_type = 'dungeon'
             AND bot_side_count = 1
             AND bosses_count BETWEEN 3 AND 5 THEN 'OK'
        WHEN event_type = 'raid'
             AND bot_side_count = 1
             AND bosses_count BETWEEN 4 AND 8 THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM t
ORDER BY event_id;

COMMIT;