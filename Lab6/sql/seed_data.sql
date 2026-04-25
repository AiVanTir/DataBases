BEGIN;

INSERT INTO "Region" (region_id, code, name) VALUES
    (1, 'RU', 'Russia'),
    (2, 'GB', 'Great Britain'),
    (3, 'DE', 'Germany'),
    (4, 'BK', 'Balkans'),
    (5, 'NE', 'Northern Europe')
ON CONFLICT (region_id) DO NOTHING;

INSERT INTO "UserType" (user_type_id, code, name) VALUES
    (1, 'P', 'player'),
    (2, 'M', 'moderator'),
    (3, 'A', 'admin')
ON CONFLICT (user_type_id) DO NOTHING;

INSERT INTO "ServerType" (server_type_id, name) VALUES
    (1, 'PvP'),
    (2, 'PvE'),
    (3, 'RP')
ON CONFLICT (server_type_id) DO NOTHING;

INSERT INTO "Role" (role_id, name, description) VALUES
    (1, 'tank', 'Absorbs damage and protects the group'),
    (2, 'dps', 'Deals the main damage to enemies'),
    (3, 'heal', 'Restores health and supports allies')
ON CONFLICT (role_id) DO NOTHING;

INSERT INTO "Faction" (faction_id, name, short_description, full_description) VALUES
    (1, 'Alliance', 'Order faction', 'A union of kingdoms and free peoples focused on order and defense'),
    (2, 'Horde', 'War faction', 'A union of clans and tribes focused on force, survival and conquest')
ON CONFLICT (faction_id) DO NOTHING;

INSERT INTO "EventType" (event_type_id, name, description) VALUES
    (1, 'dungeon', 'Group activity against several bosses selected from the location pool'),
    (2, 'raid', 'Large group activity against multiple bosses with stricter requirements'),
    (3, 'battleground', 'PvP battle between two teams on a dedicated combat map')
ON CONFLICT (event_type_id) DO NOTHING;

INSERT INTO "Class" (class_id, role_id, name, description) VALUES
    (1, 1, 'Guardian', 'Heavy defender with high survivability'),
    (2, 1, 'Berserker', 'Aggressive front-line fighter with tank role'),
    (3, 2, 'Swordsman', 'Melee damage dealer'),
    (4, 2, 'Archer', 'Ranged damage dealer'),
    (5, 3, 'Priest', 'Classic healer and support class'),
    (6, 3, 'Shaman', 'Healer with ritual and elemental support')
ON CONFLICT (class_id) DO NOTHING;

INSERT INTO "Race" (race_id, faction_id, name, description) VALUES
    (1, 1, 'Human', 'Balanced race of the Alliance'),
    (2, 1, 'Elf', 'Agile race of the Alliance'),
    (3, 1, 'Dwarf', 'Durable race of the Alliance'),
    (4, 1, 'Gnome', 'Technical race of the Alliance'),
    (5, 2, 'Orc', 'Strong race of the Horde'),
    (6, 2, 'Troll', 'Swift race of the Horde'),
    (7, 2, 'Goblin', 'Cunning race of the Horde'),
    (8, 2, 'Undead', 'Dark race of the Horde')
ON CONFLICT (race_id) DO NOTHING;

INSERT INTO "RaceClassAvailability" (race_id, class_id) VALUES
    -- Alliance: class 2 (Berserker) is unavailable for the whole faction
    -- Human
    (1, 1), (1, 3), (1, 4), (1, 5),
    -- Elf
    (2, 1), (2, 3), (2, 4), (2, 6),
    -- Dwarf
    (3, 1), (3, 3), (3, 5), (3, 6),
    -- Gnome
    (4, 1), (4, 4), (4, 5), (4, 6),

    -- Horde: class 5 (Priest) is unavailable for the whole faction
    -- Orc
    (5, 1), (5, 2), (5, 3), (5, 6),
    -- Troll
    (6, 2), (6, 3), (6, 4), (6, 6),
    -- Goblin
    (7, 1), (7, 2), (7, 4), (7, 6),
    -- Undead
    (8, 1), (8, 2), (8, 3), (8, 4)
ON CONFLICT DO NOTHING;

INSERT INTO "Map" (map_id, event_type_id, name) VALUES
    -- dungeons
    (1, 1, 'Forgotten Crypt'),
    (2, 1, 'Crystal Caverns'),
    (3, 1, 'Ashen Catacombs'),

    -- raids
    (4, 2, 'Dragon Citadel'),
    (5, 2, 'Temple of Storms'),

    -- battlegrounds
    (6, 3, 'Twin River Valley'),
    (7, 3, 'Iron Pass')
ON CONFLICT (map_id) DO NOTHING;

INSERT INTO "Boss" (boss_id, name, level) VALUES
    (1, 'Crypt Keeper', 12),
    (2, 'Bone Devourer', 11),
    (3, 'Stone Behemoth', 13),
    (4, 'Storm Herald', 14),
    (5, 'Ancient Dragon', 25),
    (6, 'Thunder Titan', 27),
    (7, 'Warlord Karg', 24),
    (8, 'Iron Queen', 26),
    (9, 'Void Prophet', 23),
    (10, 'Blade Phantom', 15)
ON CONFLICT (boss_id) DO NOTHING;

INSERT INTO "DungeonBossPool" (map_id, boss_id) VALUES
    -- Forgotten Crypt (dungeon) -> 5 bosses
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 10),

    -- Crystal Caverns (dungeon) -> 5 bosses
    (2, 1), (2, 3), (2, 5), (2, 9), (2, 10),

    -- Ashen Catacombs (dungeon) -> 5 bosses
    (3, 2), (3, 4), (3, 6), (3, 9), (3, 10),

    -- Dragon Citadel (raid) -> 8 bosses
    (4, 1), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9),

    -- Temple of Storms (raid) -> 8 bosses
    (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 10)
ON CONFLICT DO NOTHING;

INSERT INTO "Server" (server_id, region_id, server_type_id, name) VALUES
    (1, 1, 1, 'RU1'),
    (2, 1, 2, 'RU2'),
    (3, 1, 3, 'RU3'),

    (4, 2, 1, 'GB1'),
    (5, 2, 2, 'GB2'),

    (6, 3, 1, 'DE1'),
    (7, 3, 2, 'DE2'),

    (8, 4, 1, 'BK1'),
    (9, 5, 2, 'NE1')
ON CONFLICT (server_id) DO NOTHING;

INSERT INTO "User" (user_id, region_id, user_type_id, email, nickname, password_hash) VALUES
    (1, 1, 3, 'admin@bang.local', 'admin_ru', 'hash_admin_ru'),
    (2, 2, 2, 'moderator@bang.local', 'mod_gb', 'hash_mod_gb'),
    (3, 3, 1, 'player1@bang.local', 'player_de_1', 'hash_player_de_1')
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