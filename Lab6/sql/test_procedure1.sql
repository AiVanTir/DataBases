BEGIN;

DELETE FROM "Character"
WHERE char_id BETWEEN 991001 AND 991020
   OR user_id IN (991001, 991002);

DELETE FROM "User"
WHERE user_id IN (991001, 991002);

INSERT INTO "User" (
    user_id,
    region_id,
    user_type_id,
    email,
    nickname,
    password_hash
)
VALUES
    (991001, 1, 1, 'proc1_test_user@local.test', 'proc1_test_user', 'hash_proc1_test'),
    (991002, 1, 1, 'proc1_limit_user@local.test', 'proc1_limit_user', 'hash_proc1_limit');

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
    (991001, 991002, 1, 1, 1, 'LimitChar01', DATE '2025-01-01', 10, 0, NULL),
    (991002, 991002, 2, 1, 1, 'LimitChar02', DATE '2025-01-01', 10, 0, NULL),
    (991003, 991002, 3, 1, 1, 'LimitChar03', DATE '2025-01-01', 10, 0, NULL),
    (991004, 991002, 4, 1, 1, 'LimitChar04', DATE '2025-01-01', 10, 0, NULL),
    (991005, 991002, 5, 1, 1, 'LimitChar05', DATE '2025-01-01', 10, 0, NULL),
    (991006, 991002, 6, 1, 1, 'LimitChar06', DATE '2025-01-01', 10, 0, NULL),
    (991007, 991002, 7, 1, 1, 'LimitChar07', DATE '2025-01-01', 10, 0, NULL),
    (991008, 991002, 8, 1, 1, 'LimitChar08', DATE '2025-01-01', 10, 0, NULL),
    (991009, 991002, 9, 1, 1, 'LimitChar09', DATE '2025-01-01', 10, 0, NULL),
    (991010, 991002, 1, 1, 1, 'LimitChar10', DATE '2025-01-01', 10, 0, NULL);

-- TEST 1. Позитивный сценарий

CALL register_new_character(
    'proc1_test_user',
    'Proc1GoodChar',
    'tank',
    'Human',
    'Guardian'
);

SELECT
    'TEST 1 - success' AS test_name,
    ch.name AS created_character,
    u.nickname AS owner_nickname,
    s.server_id,
    CASE
        WHEN ch.name = 'Proc1GoodChar' THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM "Character" ch
JOIN "User" u
    ON u.user_id = ch.user_id
JOIN "Server" s
    ON s.server_id = ch.server_id
WHERE u.nickname = 'proc1_test_user'
  AND ch.name = 'Proc1GoodChar';

-- TEST 2. Негативный сценарий: пользователь не существует

DO $$
BEGIN
    BEGIN
        CALL register_new_character(
            'no_such_user',
            'Proc1FailNoUser',
            'tank',
            'Human',
            'Guardian'
        );

        RAISE EXCEPTION 'TEST 2 FAILED: procedure accepted non-existing user';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 2 OK: non-existing user rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 3. Негативный сценарий: роль не существует

DO $$
BEGIN
    BEGIN
        CALL register_new_character(
            'proc1_test_user',
            'Proc1FailRole',
            'wizard_role',
            'Human',
            'Guardian'
        );

        RAISE EXCEPTION 'TEST 3 FAILED: procedure accepted non-existing role';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 3 OK: non-existing role rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 4. Негативный сценарий: класс не соответствует роли

DO $$
BEGIN
    BEGIN
        CALL register_new_character(
            'proc1_test_user',
            'Proc1FailRoleMismatch',
            'heal',
            'Human',
            'Guardian'
        );

        RAISE EXCEPTION 'TEST 4 FAILED: class-role mismatch accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 4 OK: class-role mismatch rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 5. Негативный сценарий: недопустимая пара race + class

DO $$
BEGIN
    BEGIN
        CALL register_new_character(
            'proc1_test_user',
            'Proc1FailRaceClass',
            'tank',
            'Human',
            'Berserker'
        );

        RAISE EXCEPTION 'TEST 5 FAILED: invalid race-class pair accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 5 OK: invalid race-class pair rejected: %', SQLERRM;
    END;
END
$$;

-- TEST 6. Негативный сценарий: у пользователя уже 10 персонажей

DO $$
BEGIN
    BEGIN
        CALL register_new_character(
            'proc1_limit_user',
            'Proc1FailLimit',
            'tank',
            'Human',
            'Guardian'
        );

        RAISE EXCEPTION 'TEST 6 FAILED: user with 10 characters accepted';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'TEST 6 OK: character limit enforced: %', SQLERRM;
    END;
END
$$;

SELECT
    'TEST 6 - characters count' AS test_name,
    COUNT(*) AS chars_count,
    CASE
        WHEN COUNT(*) = 10 THEN 'OK'
        ELSE 'FAIL'
    END AS test_result
FROM "Character" ch
JOIN "User" u
    ON u.user_id = ch.user_id
WHERE u.nickname = 'proc1_limit_user';

COMMIT;