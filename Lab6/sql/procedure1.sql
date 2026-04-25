DROP PROCEDURE IF EXISTS register_new_character(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE PROCEDURE register_new_character(
    IN p_user_nickname VARCHAR,
    IN p_character_name VARCHAR,
    IN p_role_name VARCHAR,
    IN p_race_name VARCHAR,
    IN p_class_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    v_user_region_id INTEGER;

    v_role_id INTEGER;
    v_race_id INTEGER;
    v_class_id INTEGER;
    v_class_role_id INTEGER;

    v_total_chars INTEGER;
    v_target_server_id INTEGER;
BEGIN
    SELECT
        u.user_id,
        u.region_id
    INTO
        v_user_id,
        v_user_region_id
    FROM "User" u
    WHERE u.nickname = p_user_nickname;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User with nickname "%" does not exist', p_user_nickname;
    END IF;

    SELECT r.role_id
    INTO v_role_id
    FROM "Role" r
    WHERE r.name = p_role_name;

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Role "%" does not exist', p_role_name;
    END IF;

    SELECT r.race_id
    INTO v_race_id
    FROM "Race" r
    WHERE r.name = p_race_name;

    IF v_race_id IS NULL THEN
        RAISE EXCEPTION 'Race "%" does not exist', p_race_name;
    END IF;

    SELECT
        c.class_id,
        c.role_id
    INTO
        v_class_id,
        v_class_role_id
    FROM "Class" c
    WHERE c.name = p_class_name;

    IF v_class_id IS NULL THEN
        RAISE EXCEPTION 'Class "%" does not exist', p_class_name;
    END IF;

    IF v_class_role_id <> v_role_id THEN
        RAISE EXCEPTION
            'Class "%" does not belong to role "%"',
            p_class_name,
            p_role_name;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM "RaceClassAvailability" rca
        WHERE rca.race_id = v_race_id
          AND rca.class_id = v_class_id
    ) THEN
        RAISE EXCEPTION
            'Combination of race "%" and class "%" is not allowed',
            p_race_name,
            p_class_name;
    END IF;

    SELECT COUNT(*)
    INTO v_total_chars
    FROM "Character" ch
    WHERE ch.user_id = v_user_id;

    IF v_total_chars >= 10 THEN
        RAISE EXCEPTION
            'User "%" already has 10 characters',
            p_user_nickname;
    END IF;

    SELECT s.server_id
    INTO v_target_server_id
    FROM "Server" s
    WHERE s.region_id = v_user_region_id
      AND NOT EXISTS (
          SELECT 1
          FROM "Character" ch
          WHERE ch.user_id = v_user_id
            AND ch.server_id = s.server_id
      )
    ORDER BY s.server_id DESC
    LIMIT 1;

    IF v_target_server_id IS NULL THEN
        SELECT t.server_id
        INTO v_target_server_id
        FROM (
            SELECT
                s.server_id,
                COUNT(ch.char_id) AS chars_on_server
            FROM "Server" s
            LEFT JOIN "Character" ch
                ON ch.server_id = s.server_id
               AND ch.user_id = v_user_id
            WHERE s.region_id = v_user_region_id
            GROUP BY s.server_id
            HAVING COUNT(ch.char_id) BETWEEN 1 AND 2
            ORDER BY s.server_id DESC
            LIMIT 1
        ) AS t;
    END IF;

    IF v_target_server_id IS NULL THEN
        SELECT s.server_id
        INTO v_target_server_id
        FROM "Server" s
        WHERE s.region_id <> v_user_region_id
        ORDER BY s.server_id DESC
        LIMIT 1;
    END IF;

    IF v_target_server_id IS NULL THEN
        RAISE EXCEPTION 'No suitable server found for user "%"', p_user_nickname;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "Character" ch
        WHERE ch.server_id = v_target_server_id
          AND ch.name = p_character_name
    ) THEN
        RAISE EXCEPTION
            'Character name "%" already exists on server %',
            p_character_name,
            v_target_server_id;
    END IF;

    INSERT INTO "Character" (
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
    VALUES (
        v_user_id,
        v_target_server_id,
        v_race_id,
        v_class_id,
        p_character_name,
        CURRENT_DATE,
        1,
        0,
        NULL
    );

    RAISE NOTICE
        'Character "%" successfully created for user "%" on server %',
        p_character_name,
        p_user_nickname,
        v_target_server_id;
END;
$$;