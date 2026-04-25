DROP TRIGGER IF EXISTS trg_eventparticipant_check_level
ON "EventParticipant";

DROP FUNCTION IF EXISTS trg_fn_eventparticipant_check_level();

CREATE OR REPLACE FUNCTION trg_fn_eventparticipant_check_level()
RETURNS TRIGGER
AS $$
DECLARE
    v_event_id INTEGER;
    v_min_level SMALLINT;
    v_max_level SMALLINT;
    v_existing_count INTEGER;
    v_batch_min_level SMALLINT;
    v_batch_max_level SMALLINT;
    v_bad_char_name VARCHAR(32);
    v_bad_char_level SMALLINT;
BEGIN
    FOR v_event_id IN
        SELECT DISTINCT event_id
        FROM inserted_rows
    LOOP
        SELECT
            e.min_level,
            e.max_level
        INTO
            v_min_level,
            v_max_level
        FROM "Event" e
        WHERE e.event_id = v_event_id
        FOR UPDATE;

        SELECT COUNT(*)
        INTO v_existing_count
        FROM "EventParticipant" ep
        WHERE ep.event_id = v_event_id
          AND NOT EXISTS (
              SELECT 1
              FROM inserted_rows ir
              WHERE ir.event_id = ep.event_id
                AND ir.char_id = ep.char_id
          );

        IF v_min_level IS NULL AND v_max_level IS NULL THEN
            SELECT
                MIN(c.level),
                MAX(c.level)
            INTO
                v_batch_min_level,
                v_batch_max_level
            FROM inserted_rows ir
            JOIN "Character" c
                ON c.char_id = ir.char_id
            WHERE ir.event_id = v_event_id;

            UPDATE "Event"
            SET
                min_level = GREATEST(1, v_batch_min_level - 3),
                max_level = v_batch_max_level + 5
            WHERE event_id = v_event_id;

            SELECT
                e.min_level,
                e.max_level
            INTO
                v_min_level,
                v_max_level
            FROM "Event" e
            WHERE e.event_id = v_event_id;
        END IF;

        SELECT
            c.name,
            c.level
        INTO
            v_bad_char_name,
            v_bad_char_level
        FROM inserted_rows ir
        JOIN "Character" c
            ON c.char_id = ir.char_id
        WHERE ir.event_id = v_event_id
          AND (c.level < v_min_level OR c.level > v_max_level)
        LIMIT 1;

        IF v_bad_char_name IS NOT NULL THEN
            RAISE EXCEPTION
                'Character "%" with level % does not fit event % level range [%..%]',
                v_bad_char_name,
                v_bad_char_level,
                v_event_id,
                v_min_level,
                v_max_level;
        END IF;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_eventparticipant_check_level
AFTER INSERT
ON "EventParticipant"
REFERENCING NEW TABLE AS inserted_rows
FOR EACH STATEMENT
EXECUTE FUNCTION trg_fn_eventparticipant_check_level();