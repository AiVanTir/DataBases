import os
import random
from datetime import datetime, timedelta

import psycopg2
from faker import Faker

DB_CONFIG = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": os.getenv("PGPORT", "5432"),
    "dbname": os.getenv("PGDATABASE", "Lab4"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", "HentY12!sql"),
}

USERS_COUNT = 18
CHARACTERS_COUNT = 70
EVENTS_COUNT = 24
BANS_COUNT = 8
RESET_DATA = True
RANDOM_SEED = 42

faker = Faker()
random.seed(RANDOM_SEED)
Faker.seed(RANDOM_SEED)


def get_connection():
    dsn = os.getenv("BANG_DSN")
    if dsn:
        return psycopg2.connect(dsn)
    return psycopg2.connect(**DB_CONFIG)


def fetch_dict(cur, query, params=None):
    cur.execute(query, params or ())
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def reset_data(cur):
    cur.execute('DELETE FROM "Ban";')
    cur.execute('DELETE FROM "EventParticipant";')
    cur.execute('DELETE FROM "EventBoss";')
    cur.execute('DELETE FROM "EventSide";')
    cur.execute('DELETE FROM "Event";')
    cur.execute('DELETE FROM "Character";')
    cur.execute("DELETE FROM \"User\" WHERE email LIKE '%%@autogen.bang.local';")


def load_refs(cur):
    refs = {}

    user_types = fetch_dict(cur, 'SELECT user_type_id, code, name FROM "UserType"')
    refs["user_types"] = {}
    for row in user_types:
        refs["user_types"][row["code"].strip()] = row["user_type_id"]
        refs["user_types"][row["name"].strip().lower()] = row["user_type_id"]

    refs["regions"] = [row["region_id"] for row in fetch_dict(cur, 'SELECT region_id FROM "Region" ORDER BY region_id')]
    refs["servers"] = [row["server_id"] for row in fetch_dict(cur, 'SELECT server_id FROM "Server" ORDER BY server_id')]

    refs["race_class"] = fetch_dict(
        cur,
        '''
        SELECT rca.race_id, rca.class_id, r.name AS role_name
        FROM "RaceClassAvailability" rca
        JOIN "Class" c ON c.class_id = rca.class_id
        JOIN "Role" r ON r.role_id = c.role_id
        ORDER BY rca.race_id, rca.class_id
        '''
    )

    refs["maps"] = fetch_dict(
        cur,
        '''
        SELECT m.map_id, m.event_type_id, et.name AS event_type_name
        FROM "Map" m
        JOIN "EventType" et ON et.event_type_id = m.event_type_id
        ORDER BY m.map_id
        '''
    )

    event_types = fetch_dict(cur, 'SELECT event_type_id, name FROM "EventType"')
    refs["event_types"] = {row["name"]: row["event_type_id"] for row in event_types}

    refs["boss_pool"] = fetch_dict(
        cur,
        '''
        SELECT map_id, boss_id
        FROM "DungeonBossPool"
        ORDER BY map_id, boss_id
        '''
    )

    refs["moderators"] = [
        row["user_id"]
        for row in fetch_dict(
            cur,
            'SELECT user_id FROM "User" WHERE user_type_id = %s ORDER BY user_id',
            (refs["user_types"]["M"],)
        )
    ]

    return refs


def create_users(cur, refs):
    rows = []

    for i in range(USERS_COUNT):
        region_id = refs["regions"][i % len(refs["regions"])]
        nickname = (faker.user_name() + str(i))[:32]
        email = f'user_{i + 1}@autogen.bang.local'
        rows.append((region_id, refs["user_types"]["P"], email, nickname, f'hash_{i + 1}'))

    for row in rows:
        cur.execute(
            '''
            INSERT INTO "User" (region_id, user_type_id, email, nickname, password_hash)
            VALUES (%s, %s, %s, %s, %s)
            ''',
            row,
        )

    return fetch_dict(
        cur,
        '''
        SELECT user_id
        FROM "User"
        WHERE email LIKE '%%@autogen.bang.local'
        ORDER BY user_id
        '''
    )


def create_characters(cur, refs, users):
    options = refs["race_class"]
    server_ids = refs["servers"]
    created = []

    for i in range(CHARACTERS_COUNT):
        user_id = random.choice(users)["user_id"]
        server_id = random.choice(server_ids)
        option = random.choice(options)
        name = f'{faker.first_name()[:10]}_{i + 1}'
        registration_date = faker.date_between(start_date='-2y', end_date='-90d')
        level = random.randint(15, 60)
        gold = random.randint(100, 20000)

        cur.execute(
            '''
            INSERT INTO "Character" (user_id, server_id, race_id, class_id, name, level, gold, avatar)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING char_id, server_id, level
            ''',
            (
                user_id,
                server_id,
                option["race_id"],
                option["class_id"],
                name,
                level,
                gold,
                faker.file_path(depth=1, category='image')[:255],
            ),
        )
        char_id, server_id, level = cur.fetchone()

        created.append(
            {
                "char_id": char_id,
                "server_id": server_id,
                "level": level,
                "role_name": option["role_name"],
            }
        )

    return created


def choose_party(characters, server_id, event_type_name):
    same_server = [c for c in characters if c["server_id"] == server_id]

    if event_type_name == "dungeon":
        size = 5
    else:
        size = 10

    if len(same_server) < size:
        return []

    return random.sample(same_server, size)


def add_event_participant(cur, event_id, side_id, server_id, ch):
    cur.execute(
        '''
        INSERT INTO "EventParticipant"
            (event_id, char_id, side_id, server_id, damage_dealt, damage_received, healing_done, kills)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ''',
        (
            event_id,
            ch["char_id"],
            side_id,
            server_id,
            random.randint(1000, 15000),
            random.randint(500, 10000),
            random.randint(0, 8000) if ch["role_name"] == "heal" else random.randint(0, 1500),
            random.randint(0, 20),
        ),
    )


def create_events(cur, refs, characters):
    maps_by_type = {"dungeon": [], "raid": [], "battleground": []}
    for row in refs["maps"]:
        maps_by_type[row["event_type_name"]].append(row)

    event_ids = []
    types_cycle = ["dungeon", "raid", "battleground"]
    now = datetime.now()

    for i in range(EVENTS_COUNT):
        event_type = types_cycle[i % 3]
        server_id = random.choice(refs["servers"])
        event_map = random.choice(maps_by_type[event_type])
        participants = choose_party(characters, server_id, event_type)

        if not participants:
            continue

        min_level = max(1, min(c["level"] for c in participants) - 5)
        max_level = max(c["level"] for c in participants)
        start_time = now - timedelta(days=random.randint(1, 60), hours=random.randint(1, 20))
        end_time = start_time + timedelta(minutes=random.randint(20, 90))
        status = "F"

        cur.execute(
            '''
            INSERT INTO "Event" (server_id, event_type_id, map_id, status, min_level, max_level, start_time, end_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING event_id
            ''',
            (
                server_id,
                refs["event_types"][event_type],
                event_map["map_id"],
                status,
                min_level,
                max_level,
                start_time,
                end_time,
            ),
        )
        event_id = cur.fetchone()[0]
        event_ids.append(event_id)

        if event_type == "battleground":
            side1_result = random.choices(['W', 'L', 'D'], weights=[35, 35, 30], k=1)[0]
        else:
            side1_result = 'W'

        cur.execute(
            '''
            INSERT INTO "EventSide" (event_id, side_number, result)
            VALUES (%s, 1, %s)
            RETURNING side_id
            ''',
            (event_id, side1_result),
        )
        side1_id = cur.fetchone()[0]

        side2_id = None
        if event_type == "battleground":
            side2_result = 'L' if side1_result == 'W' else 'W'
            cur.execute(
                '''
                INSERT INTO "EventSide" (event_id, side_number, result)
                VALUES (%s, 2, %s)
                RETURNING side_id
                ''',
                (event_id, side2_result),
            )
            side2_id = cur.fetchone()[0]
        else:
            cur.execute(
                '''
                UPDATE "EventSide"
                SET result = 'L'
                WHERE event_id = %s
                  AND side_number = 2
                ''',
                (event_id,),
            )

        if event_type == "battleground":
            team1 = participants[:5]
            team2 = participants[5:10]

            for ch in team1:
                add_event_participant(cur, event_id, side1_id, server_id, ch)

            for ch in team2:
                add_event_participant(cur, event_id, side2_id, server_id, ch)
        else:
            for ch in participants:
                add_event_participant(cur, event_id, side1_id, server_id, ch)

    return event_ids


def create_bans(cur, refs, characters):
    moderators = refs["moderators"]
    if not moderators or not characters:
        return 0

    reasons = ["CHT", "ABU", "AVA", "OTH"]
    count = min(BANS_COUNT, len(characters))

    for ch in random.sample(characters, count):
        moderator_id = random.choice(moderators)
        start_time = datetime.now() - timedelta(days=random.randint(1, 30))
        end_time = start_time + timedelta(days=random.randint(1, 14))

        cur.execute(
            '''
            INSERT INTO "Ban" (char_id, moderator_user_id, moderator_user_type_id, reason, start_time, end_time)
            VALUES (%s, %s, 2, %s, %s, %s)
            ''',
            (ch["char_id"], moderator_id, random.choice(reasons), start_time, end_time),
        )

    return count


def main():
    conn = get_connection()
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            if RESET_DATA:
                reset_data(cur)

            refs = load_refs(cur)
            users = create_users(cur, refs)
            characters = create_characters(cur, refs, users)
            events = create_events(cur, refs, characters)
            bans = create_bans(cur, refs, characters)

        conn.commit()
        print('Готово.')
        print(f'Пользователи: {len(users)}')
        print(f'Персонажи: {len(characters)}')
        print(f'События: {len(events)}')
        print(f'Баны: {bans}')
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == '__main__':
    main()