"""
Step 5: migrate_logs_and_misc.py
==================================
Imports logs, queries, notes, controlled vocabularies, and other
miscellaneous data from old DB → new DB.

Tables migrated:
  - queries + query_participants
  - notes
  - event_log + event_log_settings
  - email_log + email_log_users
  - controlled_vocabs + controlled_vocab_entries + controlled_vocab_entry_settings
  - subeditor_submission_group

Prerequisites: Run step1 through step4 first.
"""

import json
import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID, NEW_JOURNAL_ID,
    ASSOC_TYPE_SUBMISSION, ASSOC_TYPE_SUBMISSION_FILE,
    ASSOC_TYPE_PUBLICATION, ASSOC_TYPE_SECTION, ASSOC_TYPE_QUERY,
    get_max_id, print_header, print_step, print_ok, print_warn,
    fix_encoding,
)

MAP_FILE = "merge_id_maps.json"


def load_maps():
    try:
        with open(MAP_FILE, "r") as f:
            data = json.load(f)
        result = {}
        for key, val in data.items():
            if isinstance(val, dict):
                result[key] = {int(k): v for k, v in val.items()}
            else:
                result[key] = val
        return result
    except (FileNotFoundError, json.JSONDecodeError):
        print_warn(f"Could not load {MAP_FILE}. Did you run step4?")
        sys.exit(1)


def save_maps(maps):
    serializable = {}
    for key, val in maps.items():
        if isinstance(val, dict):
            serializable[key] = {str(k): v for k, v in val.items()}
        else:
            serializable[key] = val
    with open(MAP_FILE, "w") as f:
        json.dump(serializable, f, indent=2)
    print_ok(f"Saved ID mappings to {MAP_FILE}")


def migrate_queries(old_cur, new_conn, new_cur, sub_map):
    """Import queries and query_participants."""
    print_step("Migrating queries and query_participants...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    # Queries referencing our submissions (assoc_type=1048585)
    old_cur.execute(
        f"SELECT query_id, assoc_type, assoc_id, stage_id, seq, "
        f"date_posted, date_modified, closed "
        f"FROM queries WHERE assoc_type = {ASSOC_TYPE_SUBMISSION} "
        f"AND assoc_id IN ({placeholders}) ORDER BY query_id",
        old_sub_ids
    )
    old_queries = old_cur.fetchall()

    next_qid = get_max_id(new_cur, "queries", "query_id") + 1
    query_map = {}

    for row in old_queries:
        old_qid = row[0]
        new_qid = next_qid
        new_sub_id = sub_map[row[2]]

        new_cur.execute(
            "INSERT INTO queries (query_id, assoc_type, assoc_id, stage_id, seq, "
            "date_posted, date_modified, closed) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (new_qid, ASSOC_TYPE_SUBMISSION, new_sub_id, row[3], row[4],
             row[5], row[6], row[7])
        )

        query_map[old_qid] = new_qid
        next_qid += 1

    new_conn.commit()
    print_ok(f"Migrated {len(query_map)} queries")

    # Query participants
    if query_map:
        old_qids = tuple(query_map.keys())
        qplaceholders = ",".join(["%s"] * len(old_qids))

        old_cur.execute(
            f"SELECT query_id, user_id FROM query_participants "
            f"WHERE query_id IN ({qplaceholders})",
            old_qids
        )
        qp_count = 0
        for row in old_cur.fetchall():
            new_qid = query_map.get(row[0])
            if new_qid:
                new_cur.execute(
                    "INSERT IGNORE INTO query_participants (query_id, user_id) VALUES (%s, %s)",
                    (new_qid, row[1])
                )
                qp_count += 1
        new_conn.commit()
        print_ok(f"Migrated {qp_count} query_participants")

    return query_map


def migrate_notes(old_cur, new_conn, new_cur, query_map):
    """Import notes referencing our queries."""
    print_step("Migrating notes...")

    if not query_map:
        print_ok("No notes to migrate (no queries)")
        return

    old_qids = tuple(query_map.keys())
    placeholders = ",".join(["%s"] * len(old_qids))

    # Notes have assoc_type=1048586 (QUERY) and assoc_id=query_id
    old_cur.execute(
        f"SELECT note_id, assoc_type, assoc_id, user_id, date_created, "
        f"date_modified, title, contents "
        f"FROM notes WHERE assoc_type = {ASSOC_TYPE_QUERY} "
        f"AND assoc_id IN ({placeholders}) ORDER BY note_id",
        old_qids
    )
    old_notes = old_cur.fetchall()

    next_nid = get_max_id(new_cur, "notes", "note_id") + 1
    count = 0

    for row in old_notes:
        new_qid = query_map.get(row[2])
        if not new_qid:
            continue

        new_cur.execute(
            "INSERT INTO notes (note_id, assoc_type, assoc_id, user_id, date_created, "
            "date_modified, title, contents) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (next_nid, ASSOC_TYPE_QUERY, new_qid, row[3], row[4], row[5],
             fix_encoding(row[6]), fix_encoding(row[7]))
        )
        next_nid += 1
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} notes")


def migrate_event_log(old_cur, new_conn, new_cur, sub_map, file_map):
    """Import event_log and event_log_settings for our submissions and files."""
    print_step("Migrating event_log and event_log_settings...")

    old_sub_ids = tuple(sub_map.keys())
    old_file_ids = tuple(file_map.keys())

    # Collect event_log rows for submissions (assoc_type=1048585)
    sub_placeholders = ",".join(["%s"] * len(old_sub_ids))
    old_cur.execute(
        f"SELECT log_id, assoc_type, assoc_id, user_id, date_logged, event_type, "
        f"message, is_translated FROM event_log "
        f"WHERE assoc_type = {ASSOC_TYPE_SUBMISSION} AND assoc_id IN ({sub_placeholders}) "
        f"ORDER BY log_id",
        old_sub_ids
    )
    sub_logs = old_cur.fetchall()

    # Collect event_log rows for submission files (assoc_type=515)
    file_logs = []
    if old_file_ids:
        file_placeholders = ",".join(["%s"] * len(old_file_ids))
        old_cur.execute(
            f"SELECT log_id, assoc_type, assoc_id, user_id, date_logged, event_type, "
            f"message, is_translated FROM event_log "
            f"WHERE assoc_type = {ASSOC_TYPE_SUBMISSION_FILE} AND assoc_id IN ({file_placeholders}) "
            f"ORDER BY log_id",
            old_file_ids
        )
        file_logs = old_cur.fetchall()

    all_logs = sub_logs + file_logs
    next_log_id = get_max_id(new_cur, "event_log", "log_id") + 1
    log_map = {}  # old_log_id → new_log_id

    for row in all_logs:
        old_log_id = row[0]
        assoc_type = row[1]
        old_assoc_id = row[2]

        # Remap assoc_id
        if assoc_type == ASSOC_TYPE_SUBMISSION:
            new_assoc_id = sub_map.get(old_assoc_id, old_assoc_id)
        elif assoc_type == ASSOC_TYPE_SUBMISSION_FILE:
            new_assoc_id = file_map.get(old_assoc_id, old_assoc_id)
        else:
            new_assoc_id = old_assoc_id

        new_cur.execute(
            "INSERT INTO event_log (log_id, assoc_type, assoc_id, user_id, date_logged, "
            "event_type, message, is_translated) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (next_log_id, assoc_type, new_assoc_id, row[3], row[4], row[5], row[6], row[7])
        )

        log_map[old_log_id] = next_log_id
        next_log_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(log_map)} event_log rows ({len(sub_logs)} submission + {len(file_logs)} file)")

    # event_log_settings
    if log_map:
        old_log_ids = tuple(log_map.keys())
        lplaceholders = ",".join(["%s"] * len(old_log_ids))

        old_cur.execute(
            f"SELECT log_id, setting_name, setting_value, setting_type "
            f"FROM event_log_settings WHERE log_id IN ({lplaceholders})",
            old_log_ids
        )
        els_count = 0
        for row in old_cur.fetchall():
            new_log_id = log_map.get(row[0])
            if new_log_id:
                new_cur.execute(
                    "INSERT IGNORE INTO event_log_settings "
                    "(log_id, setting_name, setting_value, setting_type) "
                    "VALUES (%s, %s, %s, %s)",
                    (new_log_id, row[1], fix_encoding(row[2]), row[3])
                )
                els_count += 1
        new_conn.commit()
        print_ok(f"Migrated {els_count} event_log_settings rows")


def migrate_email_log(old_cur, new_conn, new_cur, sub_map):
    """Import email_log and email_log_users for our submissions."""
    print_step("Migrating email_log and email_log_users...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT log_id, assoc_type, assoc_id, sender_id, date_sent, event_type, "
        f"from_address, recipients, cc_recipients, bcc_recipients, subject, body "
        f"FROM email_log WHERE assoc_type = {ASSOC_TYPE_SUBMISSION} "
        f"AND assoc_id IN ({placeholders}) ORDER BY log_id",
        old_sub_ids
    )
    old_logs = old_cur.fetchall()

    next_log_id = get_max_id(new_cur, "email_log", "log_id") + 1
    email_log_map = {}

    for row in old_logs:
        old_log_id = row[0]
        new_log_id = next_log_id
        new_sub_id = sub_map.get(row[2], row[2])

        new_cur.execute(
            "INSERT INTO email_log (log_id, assoc_type, assoc_id, sender_id, date_sent, "
            "event_type, from_address, recipients, cc_recipients, bcc_recipients, "
            "subject, body) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (new_log_id, ASSOC_TYPE_SUBMISSION, new_sub_id, row[3], row[4], row[5],
             row[6], row[7], row[8], row[9], fix_encoding(row[10]), fix_encoding(row[11]))
        )

        email_log_map[old_log_id] = new_log_id
        next_log_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(email_log_map)} email_log rows")

    # email_log_users
    if email_log_map:
        old_log_ids = tuple(email_log_map.keys())
        lplaceholders = ",".join(["%s"] * len(old_log_ids))

        old_cur.execute(
            f"SELECT email_log_id, user_id FROM email_log_users "
            f"WHERE email_log_id IN ({lplaceholders})",
            old_log_ids
        )
        elu_count = 0
        for row in old_cur.fetchall():
            new_log_id = email_log_map.get(row[0])
            if new_log_id:
                try:
                    new_cur.execute(
                        "INSERT IGNORE INTO email_log_users (email_log_id, user_id) "
                        "VALUES (%s, %s)",
                        (new_log_id, row[1])
                    )
                    elu_count += 1
                except Exception:
                    pass
        new_conn.commit()
        print_ok(f"Migrated {elu_count} email_log_users rows")


def migrate_controlled_vocabs(old_cur, new_conn, new_cur, pub_map):
    """Import controlled_vocabs, entries, and entry_settings for our publications."""
    print_step("Migrating controlled_vocabs (keywords, subjects, etc.)...")

    if not pub_map:
        print_ok("No controlled_vocabs to migrate")
        return

    old_pub_ids = tuple(pub_map.keys())
    placeholders = ",".join(["%s"] * len(old_pub_ids))

    # Get controlled_vocabs for our publications
    old_cur.execute(
        f"SELECT controlled_vocab_id, symbolic, assoc_type, assoc_id "
        f"FROM controlled_vocabs WHERE assoc_type = {ASSOC_TYPE_PUBLICATION} "
        f"AND assoc_id IN ({placeholders}) ORDER BY controlled_vocab_id",
        old_pub_ids
    )
    old_vocabs = old_cur.fetchall()

    next_cv_id = get_max_id(new_cur, "controlled_vocabs", "controlled_vocab_id") + 1
    cv_map = {}

    for row in old_vocabs:
        old_cv_id = row[0]
        new_pub_id = pub_map[row[3]]

        new_cur.execute(
            "INSERT INTO controlled_vocabs (controlled_vocab_id, symbolic, assoc_type, assoc_id) "
            "VALUES (%s, %s, %s, %s)",
            (next_cv_id, row[1], ASSOC_TYPE_PUBLICATION, new_pub_id)
        )

        cv_map[old_cv_id] = next_cv_id
        next_cv_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(cv_map)} controlled_vocabs")

    # Controlled vocab entries
    if cv_map:
        old_cv_ids = tuple(cv_map.keys())
        cv_placeholders = ",".join(["%s"] * len(old_cv_ids))

        old_cur.execute(
            f"SELECT controlled_vocab_entry_id, controlled_vocab_id, seq "
            f"FROM controlled_vocab_entries WHERE controlled_vocab_id IN ({cv_placeholders}) "
            f"ORDER BY controlled_vocab_entry_id",
            old_cv_ids
        )
        old_entries = old_cur.fetchall()

        next_cve_id = get_max_id(new_cur, "controlled_vocab_entries", "controlled_vocab_entry_id") + 1
        cve_map = {}

        for row in old_entries:
            old_cve_id = row[0]
            new_cv_id = cv_map[row[1]]

            new_cur.execute(
                "INSERT INTO controlled_vocab_entries "
                "(controlled_vocab_entry_id, controlled_vocab_id, seq) "
                "VALUES (%s, %s, %s)",
                (next_cve_id, new_cv_id, row[2])
            )

            cve_map[old_cve_id] = next_cve_id
            next_cve_id += 1

        new_conn.commit()
        print_ok(f"Migrated {len(cve_map)} controlled_vocab_entries")

        # Entry settings
        if cve_map:
            old_cve_ids = tuple(cve_map.keys())
            cve_placeholders = ",".join(["%s"] * len(old_cve_ids))

            old_cur.execute(
                f"SELECT controlled_vocab_entry_id, setting_name, setting_value, setting_type "
                f"FROM controlled_vocab_entry_settings "
                f"WHERE controlled_vocab_entry_id IN ({cve_placeholders})",
                old_cve_ids
            )
            cves_count = 0
            for row in old_cur.fetchall():
                new_cve_id = cve_map.get(row[0])
                if new_cve_id:
                    new_cur.execute(
                        "INSERT IGNORE INTO controlled_vocab_entry_settings "
                        "(controlled_vocab_entry_id, setting_name, setting_value, setting_type) "
                        "VALUES (%s, %s, %s, %s)",
                        (new_cve_id, row[1], fix_encoding(row[2]), row[3])
                    )
                    cves_count += 1
            new_conn.commit()
            print_ok(f"Migrated {cves_count} controlled_vocab_entry_settings rows")


def migrate_subeditor_submission_group(old_cur, new_conn, new_cur, maps):
    """Import subeditor_submission_group entries."""
    print_step("Migrating subeditor_submission_group...")

    section_map = maps["section_map"]

    old_cur.execute(
        "SELECT context_id, assoc_id, user_id, assoc_type "
        "FROM subeditor_submission_group WHERE context_id = %s",
        (OLD_JOURNAL_ID,)
    )
    old_rows = old_cur.fetchall()

    count = 0
    for row in old_rows:
        # assoc_type = 530 (SECTION), assoc_id = section_id
        old_assoc_id = row[1]
        assoc_type = row[3]

        if assoc_type == ASSOC_TYPE_SECTION:
            new_assoc_id = section_map.get(old_assoc_id, old_assoc_id)
        else:
            new_assoc_id = old_assoc_id

        try:
            new_cur.execute(
                "INSERT IGNORE INTO subeditor_submission_group "
                "(context_id, assoc_id, user_id, assoc_type) VALUES (%s, %s, %s, %s)",
                (NEW_JOURNAL_ID, new_assoc_id, row[2], assoc_type)
            )
            count += 1
        except Exception as e:
            print_warn(f"  Failed: {e}")

    new_conn.commit()
    print_ok(f"Migrated {count} subeditor_submission_group rows")


def main():
    print_header("STEP 5: MIGRATE LOGS & MISCELLANEOUS DATA")

    maps = load_maps()
    sub_map = maps["submission_map"]
    pub_map = maps["publication_map"]
    file_map = maps["file_map"]

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    new_cur.execute("SET SQL_SAFE_UPDATES = 0")

    # 1) Queries + participants
    query_map = migrate_queries(old_cur, new_conn, new_cur, sub_map)

    # 2) Notes
    migrate_notes(old_cur, new_conn, new_cur, query_map)

    # 3) Event log + settings
    migrate_event_log(old_cur, new_conn, new_cur, sub_map, file_map)

    # 4) Email log + users
    migrate_email_log(old_cur, new_conn, new_cur, sub_map)

    # 5) Controlled vocabularies
    migrate_controlled_vocabs(old_cur, new_conn, new_cur, pub_map)

    # 6) Subeditor submission group
    migrate_subeditor_submission_group(old_cur, new_conn, new_cur, maps)

    # Save query map
    maps["query_map"] = {str(k): v for k, v in query_map.items()}
    save_maps(maps)

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    new_conn.commit()

    print_header("STEP 5 COMPLETE")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()
