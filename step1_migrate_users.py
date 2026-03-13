# NOTES FOR MY SELF, DO NOT DO ANYTHING:
# Some user settings is not migrated!
# Make sure to manually review and migrate any missing user_settings 
# entries for the imported users after running this script.

"""
Step 1: migrate_users.py
========================
Dynamically finds users in the OLD database that are referenced by submission
data but don't exist in the NEW database, then imports them along with their
user_settings and user_user_groups.

Run this FIRST before any other migration step.
"""

import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID, NEW_JOURNAL_ID,
    print_header, print_step, print_ok, print_warn, get_max_id,
    fix_row_encoding,
)


def find_referenced_users(old_cur):
    """Find all user_ids referenced by any submission-related table in old DB."""
    print_step("Finding all user_ids referenced by submission data...")

    queries = [
        "SELECT DISTINCT user_id FROM stage_assignments WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT reviewer_id FROM review_assignments WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT editor_id FROM edit_decisions WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT uploader_user_id FROM submission_files WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT sender_id FROM email_log WHERE assoc_type = 1048585 AND assoc_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT user_id FROM event_log WHERE assoc_type = 1048585 AND assoc_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
        "SELECT DISTINCT user_id FROM event_log WHERE assoc_type = 515 AND assoc_id IN (SELECT file_id FROM submission_files WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s))",
        "SELECT DISTINCT user_id FROM notes WHERE assoc_type = 1048586 AND assoc_id IN (SELECT query_id FROM queries WHERE assoc_type = 1048585 AND assoc_id IN (SELECT submission_id FROM submissions WHERE context_id = %s))",
        "SELECT DISTINCT user_id FROM query_participants WHERE query_id IN (SELECT query_id FROM queries WHERE assoc_type = 1048585 AND assoc_id IN (SELECT submission_id FROM submissions WHERE context_id = %s))",
        "SELECT DISTINCT user_id FROM subeditor_submission_group WHERE context_id = %s",
        "SELECT DISTINCT author_id FROM submission_comments WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)",
    ]

    all_user_ids = set()
    for q in queries:
        old_cur.execute(q, (OLD_JOURNAL_ID,))
        for row in old_cur.fetchall():
            if row[0] is not None:
                all_user_ids.add(row[0])

    # Also include users in user_user_groups for old journal's groups
    old_cur.execute(
        "SELECT DISTINCT user_id FROM user_user_groups "
        "WHERE user_group_id IN (SELECT user_group_id FROM user_groups WHERE context_id = %s)",
        (OLD_JOURNAL_ID,)
    )
    for row in old_cur.fetchall():
        all_user_ids.add(row[0])

    print_ok(f"Found {len(all_user_ids)} unique user_ids referenced by old journal data")
    return all_user_ids


def find_missing_users(new_cur, user_ids):
    """Find which user_ids don't exist in the new database."""
    if not user_ids:
        return set()

    placeholders = ",".join(["%s"] * len(user_ids))
    new_cur.execute(f"SELECT user_id FROM users WHERE user_id IN ({placeholders})", tuple(user_ids))
    existing = {row[0] for row in new_cur.fetchall()}
    missing = user_ids - existing
    print_ok(f"{len(existing)} users already exist in new DB, {len(missing)} need to be imported")
    return missing


def check_conflicts(old_cur, new_cur, missing_ids):
    """Check for username/email conflicts between old missing users and new DB."""
    if not missing_ids:
        return {}

    placeholders = ",".join(["%s"] * len(missing_ids))
    old_cur.execute(
        f"SELECT user_id, username, email FROM users WHERE user_id IN ({placeholders})",
        tuple(missing_ids)
    )
    old_users = old_cur.fetchall()

    conflicts = {}
    for uid, uname, email in old_users:
        new_cur.execute(
            "SELECT user_id, username, email FROM users WHERE (username = %s OR email = %s) AND user_id != %s",
            (uname, email, uid)
        )
        conflict = new_cur.fetchall()
        if conflict:
            conflicts[uid] = (uname, email, conflict)
            print_warn(f"CONFLICT: old user_id={uid} ({uname}, {email}) conflicts with new user(s): {conflict}")

    if not conflicts:
        print_ok("No username/email conflicts found — safe to import")
    return conflicts


def import_users(old_cur, new_conn, new_cur, missing_ids):
    """Import missing users, their settings, and user_user_groups."""
    if not missing_ids:
        print_ok("No users to import")
        return

    placeholders = ",".join(["%s"] * len(missing_ids))

    # --- Import users ---
    print_step(f"Importing {len(missing_ids)} users...")
    old_cur.execute(f"SELECT * FROM users WHERE user_id IN ({placeholders})", tuple(missing_ids))
    rows = old_cur.fetchall()
    old_cur.execute(f"DESCRIBE users")
    cols = [c[0] for c in old_cur.fetchall()]

    col_list = ", ".join(cols)
    val_placeholders = ", ".join(["%s"] * len(cols))
    inserted_users = 0
    for row in rows:
        try:
            new_cur.execute(f"INSERT IGNORE INTO users ({col_list}) VALUES ({val_placeholders})", row)
            if new_cur.rowcount > 0:
                inserted_users += 1
        except Exception as e:
            print_warn(f"  Failed to insert user_id={row[0]}: {e}")
    new_conn.commit()
    print_ok(f"Inserted {inserted_users} users")

    # --- Import user_settings ---
    print_step("Importing user_settings for missing users...")
    old_cur.execute(f"SELECT * FROM user_settings WHERE user_id IN ({placeholders})", tuple(missing_ids))
    rows = old_cur.fetchall()
    old_cur.execute("DESCRIBE user_settings")
    cols = [c[0] for c in old_cur.fetchall()]

    col_list = ", ".join(cols)
    val_placeholders = ", ".join(["%s"] * len(cols))
    inserted_settings = 0
    for row in rows:
        try:
            new_cur.execute(f"INSERT IGNORE INTO user_settings ({col_list}) VALUES ({val_placeholders})", fix_row_encoding(row))
            if new_cur.rowcount > 0:
                inserted_settings += 1
        except Exception as e:
            pass  # Duplicate settings are fine to skip
    new_conn.commit()
    print_ok(f"Inserted {inserted_settings} user_settings rows")

    # --- Import user_user_groups (remap user_group_id from old to new) ---
    print_step("Importing user_user_groups (with group remapping)...")

    # Build user_group mapping: old (context_id=27) → new (context_id=1) by role_id + position
    old_cur.execute(
        "SELECT user_group_id, role_id FROM user_groups WHERE context_id = %s ORDER BY user_group_id",
        (OLD_JOURNAL_ID,)
    )
    old_groups = old_cur.fetchall()

    new_cur.execute(
        "SELECT user_group_id, role_id FROM user_groups WHERE context_id = %s ORDER BY user_group_id",
        (NEW_JOURNAL_ID,)
    )
    new_groups = new_cur.fetchall()

    # Match by role_id in order
    group_map = {}
    new_by_role = {}
    for gid, rid in new_groups:
        new_by_role.setdefault(rid, []).append(gid)

    old_by_role = {}
    for gid, rid in old_groups:
        old_by_role.setdefault(rid, []).append(gid)

    for role_id, old_gids in old_by_role.items():
        new_gids = new_by_role.get(role_id, [])
        for i, old_gid in enumerate(old_gids):
            if i < len(new_gids):
                group_map[old_gid] = new_gids[i]
            else:
                print_warn(f"  No matching new group for old group_id={old_gid} role_id={role_id}")

    print_ok(f"User group mapping: {group_map}")

    # Now import user_user_groups for our missing users
    old_cur.execute(
        f"SELECT user_group_id, user_id FROM user_user_groups "
        f"WHERE user_id IN ({placeholders}) AND user_group_id IN "
        f"(SELECT user_group_id FROM user_groups WHERE context_id = %s)",
        tuple(missing_ids) + (OLD_JOURNAL_ID,)
    )
    uug_rows = old_cur.fetchall()

    inserted_uug = 0
    for old_gid, uid in uug_rows:
        new_gid = group_map.get(old_gid)
        if new_gid:
            try:
                new_cur.execute(
                    "INSERT IGNORE INTO user_user_groups (user_group_id, user_id) VALUES (%s, %s)",
                    (new_gid, uid)
                )
                if new_cur.rowcount > 0:
                    inserted_uug += 1
            except Exception as e:
                pass
    new_conn.commit()
    print_ok(f"Inserted {inserted_uug} user_user_groups rows")

    return group_map


def import_existing_user_groups(old_cur, new_conn, new_cur, all_user_ids, missing_ids, group_map):
    """
    For users that ALREADY exist in new DB, make sure they also have
    the correct user_user_groups entries for the old journal's roles.
    """
    existing_ids = all_user_ids - missing_ids
    if not existing_ids:
        return

    placeholders = ",".join(["%s"] * len(existing_ids))
    print_step(f"Ensuring user_user_groups for {len(existing_ids)} existing users...")

    old_cur.execute(
        f"SELECT user_group_id, user_id FROM user_user_groups "
        f"WHERE user_id IN ({placeholders}) AND user_group_id IN "
        f"(SELECT user_group_id FROM user_groups WHERE context_id = %s)",
        tuple(existing_ids) + (OLD_JOURNAL_ID,)
    )
    uug_rows = old_cur.fetchall()

    inserted = 0
    for old_gid, uid in uug_rows:
        new_gid = group_map.get(old_gid)
        if new_gid:
            try:
                new_cur.execute(
                    "INSERT IGNORE INTO user_user_groups (user_group_id, user_id) VALUES (%s, %s)",
                    (new_gid, uid)
                )
                if new_cur.rowcount > 0:
                    inserted += 1
            except Exception as e:
                pass
    new_conn.commit()
    print_ok(f"Inserted {inserted} additional user_user_groups rows for existing users")


def main():
    print_header("STEP 1: MIGRATE USERS")

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    new_cur.execute("SET SQL_SAFE_UPDATES = 0")

    # 1) Find all referenced users
    all_user_ids = find_referenced_users(old_cur)

    # 2) Find which are missing
    missing_ids = find_missing_users(new_cur, all_user_ids)

    # 3) Check for conflicts
    conflicts = check_conflicts(old_cur, new_cur, missing_ids)
    if conflicts:
        print_warn("CONFLICTS FOUND! Review above and resolve before continuing.")
        print_warn("Aborting to prevent data corruption.")
        sys.exit(1)

    # 4) Import missing users + settings + groups
    group_map = import_users(old_cur, new_conn, new_cur, missing_ids)

    # 5) Ensure existing users also have the right group mappings
    if group_map:
        import_existing_user_groups(old_cur, new_conn, new_cur, all_user_ids, missing_ids, group_map)

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    new_conn.commit()

    print_header("STEP 1 COMPLETE")
    print_ok(f"Total users referenced: {len(all_user_ids)}")
    print_ok(f"Users imported: {len(missing_ids)}")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()
