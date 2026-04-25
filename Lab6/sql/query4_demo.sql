BEGIN;

-- Демонстрационный пользователь
INSERT INTO "User" (
    user_id,
    region_id,
    user_type_id,
    email,
    nickname,
    password_hash
)
VALUES
    (900001, 1, 1, 'query4_demo_user@local.test', 'query4_demo_user', 'hash_query4_demo')
ON CONFLICT DO NOTHING;

-- Демонстрационный персонаж
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
    (900001, 900001, 1, 1, 1, 'Query4DemoChar', DATE '2024-09-01', 50, 5000, NULL)
ON CONFLICT DO NOTHING;

-- 8 событий с контролируемой последовательностью результатов:
-- 900101 W
-- 900102 W
-- 900103 L
-- 900104 W
-- 900105 W
-- 900106 W
-- 900107 D
-- 900108 W

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
    (900101, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-01 10:00:00', TIMESTAMP '2025-01-01 10:30:00'),
    (900102, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-02 10:00:00', TIMESTAMP '2025-01-02 10:30:00'),
    (900103, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-03 10:00:00', TIMESTAMP '2025-01-03 10:30:00'),
    (900104, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-04 10:00:00', TIMESTAMP '2025-01-04 10:30:00'),
    (900105, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-05 10:00:00', TIMESTAMP '2025-01-05 10:30:00'),
    (900106, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-06 10:00:00', TIMESTAMP '2025-01-06 10:30:00'),
    (900107, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-07 10:00:00', TIMESTAMP '2025-01-07 10:30:00'),
    (900108, 1, 1, 1, 'F', 1, 60, TIMESTAMP '2025-01-08 10:00:00', TIMESTAMP '2025-01-08 10:30:00')
ON CONFLICT DO NOTHING;

INSERT INTO "EventSide" (
    side_id,
    event_id,
    side_number,
    result
)
VALUES
    (910101, 900101, 1, 'W'),
    (910102, 900102, 1, 'W'),
    (910103, 900103, 1, 'L'),
    (910104, 900104, 1, 'W'),
    (910105, 900105, 1, 'W'),
    (910106, 900106, 1, 'W'),
    (910107, 900107, 1, 'D'),
    (910108, 900108, 1, 'W')
ON CONFLICT DO NOTHING;

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
    (900101, 900001, 910101, 1, 3000, 1000, 0, 2),
    (900102, 900001, 910102, 1, 3200, 1200, 0, 1),
    (900103, 900001, 910103, 1, 2100, 2500, 0, 0),
    (900104, 900001, 910104, 1, 3500, 1100, 0, 3),
    (900105, 900001, 910105, 1, 3600, 900, 0, 2),
    (900106, 900001, 910106, 1, 3400, 1000, 0, 2),
    (900107, 900001, 910107, 1, 1800, 1800, 0, 1),
    (900108, 900001, 910108, 1, 3300, 1000, 0, 2)
ON CONFLICT DO NOTHING;

COMMIT;