BEGIN;

INSERT INTO "Region" (region_id, code, name) VALUES
    (1, 'RU', 'Russia'),
    (2, 'GB', 'Great Britain'),
    (3, 'DE', 'Germany'),
    (4, 'EK', 'East'),
    (5, 'NE', 'North')
ON CONFLICT (region_id) DO NOTHING;

INSERT INTO "UserType" (user_type_id, name) VALUES
    (1, 'player'),
    (2, 'moderator'),
    (3, 'admin')
ON CONFLICT (user_type_id) DO NOTHING;

INSERT INTO "ServerType" (server_type_id, name) VALUES
    (1, 'PvP'),
    (2, 'PvE'),
    (3, 'RP')
ON CONFLICT (server_type_id) DO NOTHING;

INSERT INTO "Role" (role_id, name) VALUES
    (1, 'tank'),
    (2, 'dps'),
    (3, 'heal')
ON CONFLICT (role_id) DO NOTHING;

INSERT INTO "Faction" (faction_id, name) VALUES
    (1, 'Seven Nations'),
    (2, 'Abyss Order')
ON CONFLICT (faction_id) DO NOTHING;

INSERT INTO "EventType" (event_type_id, name) VALUES
    (1, 'dungeon'),
    (2, 'raid'),
    (3, 'battleground')
ON CONFLICT (event_type_id) DO NOTHING;

INSERT INTO "Class" (class_id, role_id, name) VALUES
    (1, 1, 'Geo Guardian'),
    (2, 1, 'Cryo Vanguard'),
    (3, 2, 'Pyro Duelist'),
    (4, 2, 'Electro Ranger'),
    (5, 3, 'Hydro Healer'),
    (6, 3, 'Dendro Sage')
ON CONFLICT (class_id) DO NOTHING;

INSERT INTO "Race" (race_id, faction_id, name) VALUES
    (1, 1, 'Mondstadter'),
    (2, 1, 'Liyuean'),
    (3, 1, 'Inazuman'),
    (4, 1, 'Fontainian'),
    (5, 2, 'Khaenriahn'),
    (6, 2, 'Hilichurl'),
    (7, 2, 'Abyss Mage'),
    (8, 2, 'Shadowy Husk')
ON CONFLICT (race_id) DO NOTHING;

INSERT INTO "RaceClassAvailability" (race_id, class_id) VALUES
    -- Mondstadter
    (1, 1), (1, 3), (1, 4), (1, 5),

    -- Liyuean
    (2, 1), (2, 3), (2, 5), (2, 6),

    -- Inazuman
    (3, 1), (3, 3), (3, 4), (3, 6),

    -- Fontainian
    (4, 1), (4, 4), (4, 5), (4, 6),

    -- Khaenriahn
    (5, 1), (5, 2), (5, 3), (5, 4),

    -- Hilichurl
    (6, 1), (6, 2), (6, 3), (6, 6),

    -- Abyss Mage
    (7, 2), (7, 3), (7, 4), (7, 6),

    -- Shadowy Husk
    (8, 1), (8, 2), (8, 4), (8, 6)
ON CONFLICT DO NOTHING;

INSERT INTO "Map" (map_id, event_type_id, name) VALUES
    -- dungeons
    (1, 1, 'Temple of the Four Winds'),
    (2, 1, 'The Chasm Mines'),
    (3, 1, 'Enkanomiya Ruins'),

    -- raids
    (4, 2, 'Golden House'),
    (5, 2, 'Stormterror''s Lair'),

    -- battlegrounds
    (6, 3, 'Guyun Stone Forest'),
    (7, 3, 'Tatarasuna Front')
ON CONFLICT (map_id) DO NOTHING;

INSERT INTO "Boss" (boss_id, name, level) VALUES
    (1, 'Anemo Hypostasis', 12),
    (2, 'Cryo Regisvine', 11),
    (3, 'Primo Geovishap', 13),
    (4, 'Thunder Manifestation', 14),
    (5, 'Stormterror Dvalin', 25),
    (6, 'Azhdaha', 27),
    (7, 'Tartaglia', 24),
    (8, 'Raiden Puppet', 26),
    (9, 'Iniquitous Baptist', 23),
    (10, 'Maguu Kenki', 15)
ON CONFLICT (boss_id) DO NOTHING;

INSERT INTO "DungeonBossPool" (map_id, boss_id) VALUES
    -- Temple of the Four Winds
    (1, 1), (1, 2), (1, 10),

    -- The Chasm Mines
    (2, 3), (2, 9), (2, 10),

    -- Enkanomiya Ruins
    (3, 2), (3, 4), (3, 9),

    -- Golden House
    (4, 7), (4, 8), (4, 9),

    -- Stormterror's Lair
    (5, 5), (5, 6), (5, 8)
ON CONFLICT DO NOTHING;

INSERT INTO "Server" (server_id, region_id, server_type_id, name) VALUES
    (1, 1, 1, 'RU1'),
    (2, 1, 2, 'RU2'),
    (3, 1, 3, 'RU3'),

    (4, 2, 1, 'GB1'),
    (5, 2, 2, 'GB2'),

    (6, 3, 1, 'DE1'),
    (7, 3, 2, 'DE2'),

    (8, 4, 1, 'EK1'),
    (9, 5, 2, 'NE1')
ON CONFLICT (server_id) DO NOTHING;

INSERT INTO "User" (user_id, region_id, user_type_id, email, nickname, password_hash) VALUES
    (1, 1, 3, 'admin@teyvat.local', 'heavenly_admin', 'hash_heavenly_admin'),
    (2, 2, 2, 'moderator@teyvat.local', 'knights_mod', 'hash_knights_mod'),
    (3, 3, 1, 'player1@teyvat.local', 'traveler_one', 'hash_traveler_one')
ON CONFLICT (user_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('"Region"', 'region_id'),
              COALESCE((SELECT MAX(region_id) FROM "Region"), 1), true);

SELECT setval(pg_get_serial_sequence('"UserType"', 'user_type_id'),
              COALESCE((SELECT MAX(user_type_id) FROM "UserType"), 1), true);

SELECT setval(pg_get_serial_sequence('"ServerType"', 'server_type_id'),
              COALESCE((SELECT MAX(server_type_id) FROM "ServerType"), 1), true);

SELECT setval(pg_get_serial_sequence('"Faction"', 'faction_id'),
              COALESCE((SELECT MAX(faction_id) FROM "Faction"), 1), true);

SELECT setval(pg_get_serial_sequence('"Role"', 'role_id'),
              COALESCE((SELECT MAX(role_id) FROM "Role"), 1), true);

SELECT setval(pg_get_serial_sequence('"EventType"', 'event_type_id'),
              COALESCE((SELECT MAX(event_type_id) FROM "EventType"), 1), true);

SELECT setval(pg_get_serial_sequence('"Boss"', 'boss_id'),
              COALESCE((SELECT MAX(boss_id) FROM "Boss"), 1), true);

SELECT setval(pg_get_serial_sequence('"User"', 'user_id'),
              COALESCE((SELECT MAX(user_id) FROM "User"), 1), true);

SELECT setval(pg_get_serial_sequence('"Server"', 'server_id'),
              COALESCE((SELECT MAX(server_id) FROM "Server"), 1), true);

SELECT setval(pg_get_serial_sequence('"Class"', 'class_id'),
              COALESCE((SELECT MAX(class_id) FROM "Class"), 1), true);

SELECT setval(pg_get_serial_sequence('"Race"', 'race_id'),
              COALESCE((SELECT MAX(race_id) FROM "Race"), 1), true);

SELECT setval(pg_get_serial_sequence('"Map"', 'map_id'),
              COALESCE((SELECT MAX(map_id) FROM "Map"), 1), true);

COMMIT;