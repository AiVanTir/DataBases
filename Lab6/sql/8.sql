--8. Рейтинг

WITH base_stats AS (
    SELECT
        u.nickname AS user_name,
        ch.name AS character_name,
        r.name AS race_name,
        COUNT(*) AS bc,
        COUNT(*) FILTER (WHERE es.result = 'W')::numeric / NULLIF(COUNT(*), 0) AS win,
        COUNT(*) FILTER (
            WHERE ep.damage_received < ep.damage_dealt + ep.healing_done
        )::numeric / NULLIF(COUNT(*), 0) AS surv
    FROM "EventParticipant" ep
    JOIN "Character" ch
        ON ch.char_id = ep.char_id
    JOIN "User" u
        ON u.user_id = ch.user_id
    JOIN "Race" r
        ON r.race_id = ch.race_id
    JOIN "EventSide" es
        ON es.event_id = ep.event_id
       AND es.side_id = ep.side_id
    GROUP BY
        u.nickname,
        ch.name,
        r.name
),
rated AS (
    SELECT
        user_name,
        character_name,
        race_name,
        win,
        surv,
        bc,
        (
            540
            * power(bc::numeric, 0.37)
            * tanh(
                0.00163
                * power(bc::numeric, -0.37)
                * (
                    3500 / (1 + exp(16 - 31 * win))
                    +
                    1400 / (1 + exp(8 - 27 * surv))
                )
            )
        )::numeric AS rbr
    FROM base_stats
)
SELECT
    user_name,
    character_name,
    race_name,
    ROUND(win::numeric, 4) AS win,
    ROUND(surv::numeric, 4) AS surv,
    bc,
    ROUND(rbr, 4) AS rbr
FROM rated
ORDER BY rbr DESC, bc DESC, character_name;