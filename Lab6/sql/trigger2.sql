DROP TRIGGER IF EXISTS trg_event_add_pve_bosses
ON "Event";

DROP FUNCTION IF EXISTS trg_fn_event_add_pve_bosses();

CREATE OR REPLACE FUNCTION trg_fn_event_add_pve_bosses()
RETURNS TRIGGER
AS $$
DECLARE
    v_event_id INTEGER;
    v_map_id INTEGER;
    v_event_type_name TEXT;
    v_desired_count INTEGER;
    v_available_count INTEGER;
    v_bot_side_id INTEGER;
BEGIN
    FOR v_event_id, v_map_id, v_event_type_name IN
        SELECT
            ie.event_id,
            ie.map_id,
            et.name
        FROM inserted_events ie
        JOIN "EventType" et
            ON et.event_type_id = ie.event_type_id
        WHERE et.name IN ('dungeon', 'raid')
    LOOP
        IF v_event_type_name = 'dungeon' THEN
            v_desired_count := FLOOR(RANDOM() * 3)::int + 3; -- 3..5
        ELSE
            v_desired_count := FLOOR(RANDOM() * 5)::int + 4; -- 4..8
        END IF;

        SELECT COUNT(*)
        INTO v_available_count
        FROM "DungeonBossPool" dbp
        WHERE dbp.map_id = v_map_id;

        IF v_available_count < v_desired_count THEN
            RAISE EXCEPTION
                'Cannot create % event % on map %: required % bosses, but only % available',
                v_event_type_name,
                v_event_id,
                v_map_id,
                v_desired_count,
                v_available_count;
        END IF;

        INSERT INTO "EventSide" (
            event_id,
            side_number,
            result
        )
        SELECT
            v_event_id,
            2,
            NULL
        WHERE NOT EXISTS (
            SELECT 1
            FROM "EventSide" es
            WHERE es.event_id = v_event_id
              AND es.side_number = 2
        );

        SELECT es.side_id
        INTO v_bot_side_id
        FROM "EventSide" es
        WHERE es.event_id = v_event_id
          AND es.side_number = 2;

        INSERT INTO "EventBoss" (
            event_id,
            boss_id,
            side_id,
            map_id
        )
        SELECT
            v_event_id,
            src.boss_id,
            v_bot_side_id,
            v_map_id
        FROM (
            SELECT dbp.boss_id
            FROM "DungeonBossPool" dbp
            WHERE dbp.map_id = v_map_id
            ORDER BY RANDOM()
            LIMIT v_desired_count
        ) AS src;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_event_add_pve_bosses
AFTER INSERT
ON "Event"
REFERENCING NEW TABLE AS inserted_events
FOR EACH STATEMENT
EXECUTE FUNCTION trg_fn_event_add_pve_bosses();