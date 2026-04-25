-- 9. Относительное распределение персонажей по расам на разных серверах

CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH server_totals AS (
    SELECT
        s.server_id,
        rg.name AS region_name,
        COUNT(ch.char_id) AS total_players
    FROM "Server" s
    JOIN "Region" rg
        ON rg.region_id = s.region_id
    LEFT JOIN "Character" ch
        ON ch.server_id = s.server_id
    GROUP BY
        s.server_id,
        rg.name
),
race_pivot AS (
    SELECT *
    FROM crosstab(
        $$
        SELECT
            s.server_id,
            r.name AS race_name,
            COUNT(ch.char_id)::int AS race_count
        FROM "Server" s
        CROSS JOIN "Race" r
        LEFT JOIN "Character" ch
            ON ch.server_id = s.server_id
           AND ch.race_id = r.race_id
        GROUP BY
            s.server_id,
            r.race_id,
            r.name
        ORDER BY
            s.server_id,
            r.race_id
        $$,
        $$
        SELECT name
        FROM "Race"
        ORDER BY race_id
        $$
    ) AS ct(
        server_id integer,
        "Human" integer,
        "Elf" integer,
        "Dwarf" integer,
        "Gnome" integer,
        "Orc" integer,
        "Troll" integer,
        "Goblin" integer,
        "Undead" integer
    )
)
SELECT
    st.server_id,
    st.region_name,
    st.total_players,

    COALESCE(ROUND((100.0 * rp."Human"  / NULLIF(st.total_players, 0))::numeric, 2), 0) AS human_pct,
    COALESCE(ROUND((100.0 * rp."Elf"    / NULLIF(st.total_players, 0))::numeric, 2), 0) AS elf_pct,
    COALESCE(ROUND((100.0 * rp."Dwarf"  / NULLIF(st.total_players, 0))::numeric, 2), 0) AS dwarf_pct,
    COALESCE(ROUND((100.0 * rp."Gnome"  / NULLIF(st.total_players, 0))::numeric, 2), 0) AS gnome_pct,
    COALESCE(ROUND((100.0 * rp."Orc"    / NULLIF(st.total_players, 0))::numeric, 2), 0) AS orc_pct,
    COALESCE(ROUND((100.0 * rp."Troll"  / NULLIF(st.total_players, 0))::numeric, 2), 0) AS troll_pct,
    COALESCE(ROUND((100.0 * rp."Goblin" / NULLIF(st.total_players, 0))::numeric, 2), 0) AS goblin_pct,
    COALESCE(ROUND((100.0 * rp."Undead" / NULLIF(st.total_players, 0))::numeric, 2), 0) AS undead_pct
FROM server_totals st
LEFT JOIN race_pivot rp
    ON rp.server_id = st.server_id
ORDER BY st.server_id;