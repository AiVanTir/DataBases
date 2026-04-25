DROP PROCEDURE IF EXISTS create_dungeon_event(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE PROCEDURE create_dungeon_event(
    IN p_char_name_1 VARCHAR,
    IN p_char_name_2 VARCHAR,
    IN p_char_name_3 VARCHAR,
    IN p_char_name_4 VARCHAR,
    IN p_char_name_5 VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_event_id INTEGER;
    v_player_side_id INTEGER;
    v_server_id INTEGER;
    v_min_char_level SMALLINT;
    v_max_char_level SMALLINT;
    v_map_id INTEGER;
    v_event_type_id INTEGER;
    v_distinct_input_count INTEGER;
    v_found_count INTEGER;
BEGIN
    -- 1. Проверка, что все 5 имён различны
    SELECT COUNT(DISTINCT name_value)
    INTO v_distinct_input_count
    FROM (
        VALUES
            (p_char_name_1),
            (p_char_name_2),
            (p_char_name_3),
            (p_char_name_4),
            (p_char_name_5)
    ) AS input_names(name_value);

    IF v_distinct_input_count <> 5 THEN
        RAISE EXCEPTION 'Character names must be distinct';
    END IF;

    -- 2. Проверка существования всех 5 персонажей
    SELECT COUNT(*)
    INTO v_found_count
    FROM "Character" ch
    WHERE ch.name IN (
        p_char_name_1,
        p_char_name_2,
        p_char_name_3,
        p_char_name_4,
        p_char_name_5
    );

    IF v_found_count <> 5 THEN
        RAISE EXCEPTION 'One or more characters do not exist';
    END IF;

    -- 3. Проверка, что все персонажи на одном сервере
    SELECT
        MIN(ch.server_id),
        COUNT(DISTINCT ch.server_id),
        MIN(ch.level),
        MAX(ch.level)
    INTO
        v_server_id,
        v_found_count,
        v_min_char_level,
        v_max_char_level
    FROM "Character" ch
    WHERE ch.name IN (
        p_char_name_1,
        p_char_name_2,
        p_char_name_3,
        p_char_name_4,
        p_char_name_5
    );

    IF v_found_count <> 1 THEN
        RAISE EXCEPTION 'All characters must be on the same server';
    END IF;

    -- 4. Проверка разброса уровней
    IF v_max_char_level - v_min_char_level > 5 THEN
        RAISE EXCEPTION
            'Level spread is too high: min level = %, max level = %',
            v_min_char_level,
            v_max_char_level;
    END IF;

    -- 5. Получение типа события dungeon
    SELECT et.event_type_id
    INTO v_event_type_id
    FROM "EventType" et
    WHERE et.name = 'dungeon';

    IF v_event_type_id IS NULL THEN
        RAISE EXCEPTION 'Event type "dungeon" does not exist';
    END IF;

    -- 6. Случайный выбор карты dungeon
    SELECT m.map_id
    INTO v_map_id
    FROM "Map" m
    WHERE m.event_type_id = v_event_type_id
    ORDER BY RANDOM()
    LIMIT 1;

    IF v_map_id IS NULL THEN
        RAISE EXCEPTION 'No dungeon map available';
    END IF;

    -- 7. Создание ивента
    -- min_level и max_level оставляем NULL:
    -- trigger1 сам выставит диапазон по первой массовой вставке участников
    INSERT INTO "Event" (
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
        v_server_id,
        v_event_type_id,
        v_map_id,
        'C',
        NULL,
        NULL,
        CURRENT_TIMESTAMP,
        NULL
    )
    RETURNING event_id INTO v_event_id;

    -- 8. Создание стороны игроков
    INSERT INTO "EventSide" (
        event_id,
        side_number,
        result
    )
    VALUES (
        v_event_id,
        1,
        NULL
    )
    RETURNING side_id INTO v_player_side_id;

    -- 9. Добавление участников одной массовой вставкой
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
    SELECT
        v_event_id,
        ch.char_id,
        v_player_side_id,
        v_server_id,
        0,
        0,
        0,
        0
    FROM "Character" ch
    WHERE ch.name IN (
        p_char_name_1,
        p_char_name_2,
        p_char_name_3,
        p_char_name_4,
        p_char_name_5
    );

    RAISE NOTICE
        'Dungeon event % successfully created on server %, map %',
        v_event_id,
        v_server_id,
        v_map_id;
END;
$$;