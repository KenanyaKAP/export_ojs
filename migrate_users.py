"""
migrate_users.py
================
Copies the 66 missing users (and their user_settings) from the OLD OJS database
to the NEW OJS database.

Run this BEFORE executing migration_fix.sql Steps 2-5.

Old DB: 127.0.0.1:3386, root / ITSjournals123!#, dbname: journals
New DB: 127.0.0.1:3376, root / rootpassword,      dbname: ojs
"""

import mysql.connector
from mysql.connector import Error

# ============================================================
# CONFIGURATION
# ============================================================
OLD_DB = {
    "host": "127.0.0.1",
    "port": 3386,
    "user": "root",
    "password": "ITSjournals123!#",
    "database": "journals",
}

NEW_DB = {
    "host": "127.0.0.1",
    "port": 3376,
    "user": "root",
    "password": "rootpassword",
    "database": "ojs",
}

# These 66 user IDs exist in old DB but are missing from new DB.
# They are referenced by stage_assignments, review_assignments, edit_decisions, etc.
MISSING_USER_IDS = [
    497, 3063, 3064, 3456, 3482, 3525, 3545, 3552, 3558, 3560,
    3563, 3564, 3567, 3568, 3570, 3584, 3589, 3594, 3598, 3602,
    3612, 3621, 3624, 3626, 3635, 3636, 3649, 3665, 3674, 3675,
    3679, 3680, 3683, 3686, 3699, 3719, 3723, 3737, 3740, 3746,
    3753, 3754, 3756, 3758, 3760, 3777, 3835, 3883, 3886, 3927,
    3949, 4093, 4252, 4264, 4270, 4284, 4296, 4403, 4407, 4413,
    4451, 4500, 4529, 4537, 4577, 4585,
]
# ============================================================


def get_connection(config):
    return mysql.connector.connect(**config)


def fetch_users(old_cursor, user_ids):
    """Fetch user rows from old DB."""
    placeholders = ",".join(["%s"] * len(user_ids))
    old_cursor.execute(f"SELECT * FROM users WHERE user_id IN ({placeholders})", user_ids)
    columns = [desc[0] for desc in old_cursor.description]
    rows = old_cursor.fetchall()
    return columns, rows


def fetch_user_settings(old_cursor, user_ids):
    """Fetch user_settings rows from old DB."""
    placeholders = ",".join(["%s"] * len(user_ids))
    old_cursor.execute(f"SELECT * FROM user_settings WHERE user_id IN ({placeholders})", user_ids)
    columns = [desc[0] for desc in old_cursor.description]
    rows = old_cursor.fetchall()
    return columns, rows


def insert_rows(new_cursor, table_name, columns, rows):
    """Insert rows into new DB, skipping duplicates."""
    if not rows:
        print(f"  No rows to insert into {table_name}.")
        return 0

    placeholders = ",".join(["%s"] * len(columns))
    col_names = ",".join([f"`{c}`" for c in columns])
    sql = f"INSERT IGNORE INTO `{table_name}` ({col_names}) VALUES ({placeholders})"

    count = 0
    for row in rows:
        try:
            new_cursor.execute(sql, row)
            if new_cursor.rowcount > 0:
                count += 1
        except Exception as e:
            print(f"  [WARN] Skipped row in {table_name}: {e}")
    return count


def verify_users(new_cursor, user_ids):
    """Verify all users now exist in new DB."""
    placeholders = ",".join(["%s"] * len(user_ids))
    new_cursor.execute(f"SELECT user_id FROM users WHERE user_id IN ({placeholders})", user_ids)
    found = {row[0] for row in new_cursor.fetchall()}
    missing = set(user_ids) - found
    return missing


def main():
    print("=" * 60)
    print("OJS User Migration: Old DB → New DB")
    print("=" * 60)

    try:
        print("\n[1/5] Connecting to OLD database...")
        old_conn = get_connection(OLD_DB)
        old_cursor = old_conn.cursor()
        print(f"  Connected to {OLD_DB['host']}:{OLD_DB['port']}/{OLD_DB['database']}")

        print("\n[2/5] Connecting to NEW database...")
        new_conn = get_connection(NEW_DB)
        new_cursor = new_conn.cursor()
        new_cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        print(f"  Connected to {NEW_DB['host']}:{NEW_DB['port']}/{NEW_DB['database']}")

        # --- Fetch from old DB ---
        print(f"\n[3/5] Fetching {len(MISSING_USER_IDS)} users from old DB...")
        user_cols, user_rows = fetch_users(old_cursor, MISSING_USER_IDS)
        print(f"  Found {len(user_rows)} user rows.")

        us_cols, us_rows = fetch_user_settings(old_cursor, MISSING_USER_IDS)
        print(f"  Found {len(us_rows)} user_settings rows.")

        # --- Insert into new DB ---
        print(f"\n[4/5] Inserting into new DB...")
        u_count = insert_rows(new_cursor, "users", user_cols, user_rows)
        print(f"  Inserted {u_count} users.")

        us_count = insert_rows(new_cursor, "user_settings", us_cols, us_rows)
        print(f"  Inserted {us_count} user_settings rows.")

        new_conn.commit()

        # --- Verify ---
        print(f"\n[5/5] Verifying...")
        missing = verify_users(new_cursor, MISSING_USER_IDS)
        if missing:
            print(f"  [ERROR] Still missing {len(missing)} users: {sorted(missing)}")
        else:
            print(f"  [OK] All {len(MISSING_USER_IDS)} users now exist in new DB!")

        new_cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        new_conn.commit()

    except Error as e:
        print(f"\n[ERROR] MySQL error: {e}")

    finally:
        for c in ["old_cursor", "new_cursor"]:
            if c in dir() and locals().get(c):
                locals()[c].close()
        for c in [("old_conn", old_conn), ("new_conn", new_conn)]:
            try:
                if c[1].is_connected():
                    c[1].close()
            except:
                pass

    print("\n" + "=" * 60)
    print("User migration complete.")
    print("Now run migration_fix.sql Steps 2-5 on the new DB.")
    print("=" * 60)


if __name__ == "__main__":
    main()
