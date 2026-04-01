BEGIN;

INSERT INTO "User" (user_id, region_id, user_type_id, email, nickname, password_hash)
VALUES
(100, 1, 1, 'manual_player_100@example.com', 'manual_player_100', 'hash_100'),
(101, 1, 1, 'manual_player_101@example.com', 'manual_player_101', 'hash_101'),
(102, 2, 1, 'manual_player_102@example.com', 'manual_player_102', 'hash_102'),
(103, 2, 1, 'manual_player_103@example.com', 'manual_player_103', 'hash_103'),
(104, 3, 1, 'manual_player_104@example.com', 'manual_player_104', 'hash_104'),
(105, 3, 1, 'manual_player_105@example.com', 'manual_player_105', 'hash_105'),
(106, 1, 2, 'manual_moderator_106@example.com', 'manual_moderator_106', 'hash_106')
ON CONFLICT DO NOTHING;

INSERT INTO "Character" (char_id, user_id, server_id, race_id, class_id, name, level, gold, avatar)
VALUES
(200, 100, 1, 1, 1, 'PVP_Tank_A', 40, 1200, 'avatar_200.png'),
(201, 101, 1, 5, 2, 'PVP_Tank_B', 42, 1100, 'avatar_201.png'),

(202, 102, 1, 1, 5, 'PVP_Healer_A', 39, 900, 'avatar_202.png'),
(203, 103, 1, 2, 6, 'PVP_Healer_B', 41, 950, 'avatar_203.png'),

(204, 100, 1, 1, 3, 'PVP_Dps_A', 43, 1400, 'avatar_204.png'),
(205, 101, 1, 3, 4, 'PVP_Dps_B', 44, 1500, 'avatar_205.png'),
(206, 102, 1, 5, 3, 'PVP_Dps_C', 38, 1300, 'avatar_206.png'),
(207, 103, 1, 7, 4, 'PVP_Dps_D', 37, 1250, 'avatar_207.png'),
(208, 104, 1, 6, 3, 'PVP_Dps_E', 36, 1150, 'avatar_208.png'),
(209, 105, 1, 8, 4, 'PVP_Dps_F', 45, 1600, 'avatar_209.png')
ON CONFLICT DO NOTHING;

INSERT INTO "Character" (char_id, user_id, server_id, race_id, class_id, name, level, gold, avatar)
VALUES
(210, 100, 2, 2, 1, 'PVE_Tank_A', 46, 1700, 'avatar_210.png'),
(211, 101, 2, 6, 2, 'PVE_Tank_B', 47, 1800, 'avatar_211.png'),

(212, 102, 2, 4, 5, 'PVE_Healer_A', 44, 1400, 'avatar_212.png'),
(213, 103, 2, 7, 6, 'PVE_Healer_B', 43, 1350, 'avatar_213.png'),

(214, 104, 2, 2, 3, 'PVE_Dps_A', 48, 1900, 'avatar_214.png'),
(215, 105, 2, 3, 4, 'PVE_Dps_B', 49, 2000, 'avatar_215.png'),
(216, 100, 2, 5, 3, 'PVE_Dps_C', 41, 1250, 'avatar_216.png'),
(217, 101, 2, 4, 4, 'PVE_Dps_D', 42, 1300, 'avatar_217.png'),
(218, 102, 2, 6, 3, 'PVE_Dps_E', 40, 1200, 'avatar_218.png'),
(219, 103, 2, 7, 4, 'PVE_Dps_F', 39, 1150, 'avatar_219.png')
ON CONFLICT DO NOTHING;

INSERT INTO "Event" (event_id, server_id, event_type_id, map_id, status, start_time, end_time)
VALUES
(300, 2, 1, 1, 'finished', '2026-03-20 10:00:00', '2026-03-20 10:35:00'),
(301, 2, 2, 4, 'finished', '2026-03-21 18:00:00', '2026-03-21 19:10:00'),
(302, 1, 3, 6, 'finished', '2026-03-22 20:00:00', '2026-03-22 20:25:00'),
(303, 2, 1, 2, 'running',  '2026-03-24 16:00:00', NULL),
(304, 2, 1, 3, 'created',  '2026-03-25 12:00:00', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO "EventSide" (side_id, event_id, side_number, result)
VALUES
(400, 300, 1, 'win'),
(401, 300, 2, 'lose'),

(402, 301, 1, 'win'),
(403, 301, 2, 'lose'),

(404, 302, 1, 'win'),
(405, 302, 2, 'lose'),

(406, 303, 1, NULL),
(407, 303, 2, NULL),

(408, 304, 1, NULL),
(409, 304, 2, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO "EventParticipant"
(event_id, char_id, side_id, damage_dealt, damage_received, healing_done, kills)
VALUES
(300, 210, 400, 850, 4200, 0, 1),
(300, 212, 400, 250, 900, 5100, 0),
(300, 214, 400, 4700, 700, 0, 4),
(300, 215, 400, 4300, 650, 0, 3),
(300, 216, 400, 3900, 800, 0, 2)
ON CONFLICT DO NOTHING;

INSERT INTO "EventParticipant"
(event_id, char_id, side_id, damage_dealt, damage_received, healing_done, kills)
VALUES
(301, 210, 402, 900, 5000, 0, 1),
(301, 211, 402, 950, 5300, 0, 1),

(301, 212, 402, 300, 1200, 6200, 0),
(301, 213, 402, 280, 1100, 5900, 0),

(301, 214, 402, 5200, 900, 0, 5),
(301, 215, 402, 5600, 850, 0, 6),
(301, 216, 402, 4800, 950, 0, 4),
(301, 217, 402, 5000, 880, 0, 5),
(301, 218, 402, 4700, 910, 0, 4),
(301, 219, 402, 5300, 870, 0, 5)
ON CONFLICT DO NOTHING;

INSERT INTO "EventParticipant"
(event_id, char_id, side_id, damage_dealt, damage_received, healing_done, kills)
VALUES
(302, 200, 404, 700, 3900, 0, 1),
(302, 202, 404, 250, 1100, 4600, 0),
(302, 204, 404, 4100, 1000, 0, 4),
(302, 205, 404, 4400, 900, 0, 5),
(302, 206, 404, 3900, 950, 0, 3),

(302, 201, 405, 750, 4100, 0, 1),
(302, 203, 405, 230, 1050, 4300, 0),
(302, 207, 405, 4200, 980, 0, 4),
(302, 208, 405, 4000, 920, 0, 3),
(302, 209, 405, 4600, 870, 0, 5)
ON CONFLICT DO NOTHING;

INSERT INTO "EventParticipant"
(event_id, char_id, side_id, damage_dealt, damage_received, healing_done, kills)
VALUES
(303, 210, 406, 300, 1800, 0, 0),
(303, 212, 406, 120, 500, 1600, 0),
(303, 214, 406, 2100, 400, 0, 1)
ON CONFLICT DO NOTHING;

INSERT INTO "EventBoss" (event_id, boss_id, side_id)
VALUES
(300, 1, 401),
(300, 2, 401),
(300, 10, 401),

(301, 5, 403),
(301, 7, 403),
(301, 8, 403),
(301, 9, 403),

(303, 3, 407),
(303, 9, 407),
(303, 10, 407)
ON CONFLICT DO NOTHING;

INSERT INTO "Ban" (ban_id, char_id, moderator_user_id, reason, start_time, end_time)
VALUES
(500, 205, 2, 'abusive language', '2026-03-10 14:00:00', '2026-03-17 14:00:00'),
(501, 214, 106, 'cheating suspicion', '2026-03-18 09:00:00', '2026-03-28 09:00:00'),
(502, 207, 2, 'exploit abuse', '2026-03-23 12:00:00', NULL)
ON CONFLICT DO NOTHING;


SELECT setval(pg_get_serial_sequence('"User"', 'user_id'),
    COALESCE((SELECT MAX(user_id) FROM "User"), 1), true);

SELECT setval(pg_get_serial_sequence('"Character"', 'char_id'),
    COALESCE((SELECT MAX(char_id) FROM "Character"), 1), true);

SELECT setval(pg_get_serial_sequence('"Event"', 'event_id'),
    COALESCE((SELECT MAX(event_id) FROM "Event"), 1), true);

SELECT setval(pg_get_serial_sequence('"EventSide"', 'side_id'),
    COALESCE((SELECT MAX(side_id) FROM "EventSide"), 1), true);

SELECT setval(pg_get_serial_sequence('"Ban"', 'ban_id'),
    COALESCE((SELECT MAX(ban_id) FROM "Ban"), 1), true);

COMMIT;