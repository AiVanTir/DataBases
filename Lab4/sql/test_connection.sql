SELECT b.ban_id, c.name AS character_name, u.nickname AS moderator_nickname, b.reason, b.start_time, b.end_time
FROM "Ban" b
JOIN "Character" c ON c.char_id = b.char_id
JOIN "User" u ON u.user_id = b.moderator_user_id
ORDER BY b.ban_id;