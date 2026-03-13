"""
Step 3: migrate_submissions.py
================================
Imports submissions and all directly related data from old DB → new DB.

Tables migrated:
  - submissions
  - publications
  - authors + author_settings
  - citations
  - publication_settings
  - submission_files + submission_file_settings + submission_supplementary_files
  - stage_assignments
  - edit_decisions
  - submission_comments

All IDs are dynamically remapped to be sequential after the new DB's max IDs.
Mappings are saved to merge_id_maps.json for subsequent steps.

Prerequisites: Run step1 and step2 first.
"""

import json
import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID, NEW_JOURNAL_ID,
    get_max_id, print_header, print_step, print_ok, print_warn,
    fix_encoding,
)

MAP_FILE = "merge_id_maps.json"


def load_maps():
    try:
        with open(MAP_FILE, "r") as f:
            data = json.load(f)
        # Convert string keys back to int
        result = {}
        for key, val in data.items():
            if isinstance(val, dict):
                result[key] = {int(k): v for k, v in val.items()}
            else:
                result[key] = val
        return result
    except (FileNotFoundError, json.JSONDecodeError):
        print_warn(f"Could not load {MAP_FILE}. Did you run step2?")
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


def migrate_submissions(old_cur, new_conn, new_cur, maps):
    """Import submissions with new sequential IDs."""
    print_step("Migrating submissions...")

    section_map = maps["section_map"]

    old_cur.execute(
        "SELECT submission_id, locale, section_id, date_last_activity, date_submitted, "
        "last_modified, stage_id, status, submission_progress, work_type "
        "FROM submissions WHERE context_id = %s ORDER BY submission_id",
        (OLD_JOURNAL_ID,)
    )
    old_submissions = old_cur.fetchall()

    next_sub_id = get_max_id(new_cur, "submissions", "submission_id") + 1
    sub_map = {}

    for row in old_submissions:
        old_sub_id = row[0]
        new_sub_id = next_sub_id

        # Remap section_id
        old_section_id = row[2]
        new_section_id = section_map.get(old_section_id, old_section_id)

        new_cur.execute(
            "INSERT INTO submissions (submission_id, locale, context_id, section_id, "
            "current_publication_id, date_last_activity, date_submitted, last_modified, "
            "stage_id, status, submission_progress, work_type) "
            "VALUES (%s, %s, %s, %s, NULL, %s, %s, %s, %s, %s, %s, %s)",
            (new_sub_id, row[1], NEW_JOURNAL_ID, new_section_id,
             row[3], row[4], row[5], row[6], row[7], row[8], row[9])
        )

        sub_map[old_sub_id] = new_sub_id
        next_sub_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(sub_map)} submissions (new IDs: {min(sub_map.values())}-{max(sub_map.values())})")
    return sub_map


def migrate_publications(old_cur, new_conn, new_cur, maps, sub_map):
    """Import publications with new sequential IDs, update submissions.current_publication_id."""
    print_step("Migrating publications...")

    section_map = maps["section_map"]

    old_cur.execute(
        "SELECT publication_id, access_status, date_published, last_modified, locale, "
        "primary_contact_id, section_id, seq, submission_id, status, url_path, version "
        "FROM publications WHERE submission_id IN (%s) ORDER BY publication_id"
        % ",".join(["%s"] * len(sub_map)),
        tuple(sub_map.keys())
    )
    old_pubs = old_cur.fetchall()

    next_pub_id = get_max_id(new_cur, "publications", "publication_id") + 1
    pub_map = {}

    # Track which publication is the current one for each submission
    # (from old DB: submissions.current_publication_id)
    old_cur.execute(
        "SELECT submission_id, current_publication_id FROM submissions WHERE context_id = %s",
        (OLD_JOURNAL_ID,)
    )
    old_current_pub = {row[0]: row[1] for row in old_cur.fetchall()}

    for row in old_pubs:
        old_pub_id = row[0]
        new_pub_id = next_pub_id
        old_sub_id = row[8]
        new_sub_id = sub_map[old_sub_id]

        old_section_id = row[6]
        new_section_id = section_map.get(old_section_id, old_section_id)

        # primary_contact_id will be updated after authors are migrated
        new_cur.execute(
            "INSERT INTO publications (publication_id, access_status, date_published, "
            "last_modified, locale, primary_contact_id, section_id, seq, submission_id, "
            "status, url_path, version) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (new_pub_id, row[1], row[2], row[3], row[4],
             None,  # primary_contact_id — updated later
             new_section_id, row[7], new_sub_id, row[9], row[10], row[11])
        )

        pub_map[old_pub_id] = new_pub_id
        next_pub_id += 1

    new_conn.commit()

    # Update submissions.current_publication_id
    for old_sub_id, old_pub_id in old_current_pub.items():
        if old_sub_id in sub_map and old_pub_id in pub_map:
            new_cur.execute(
                "UPDATE submissions SET current_publication_id = %s WHERE submission_id = %s",
                (pub_map[old_pub_id], sub_map[old_sub_id])
            )
    new_conn.commit()

    print_ok(f"Migrated {len(pub_map)} publications (new IDs: {min(pub_map.values())}-{max(pub_map.values())})")
    return pub_map


def migrate_authors(old_cur, new_conn, new_cur, maps, pub_map, sub_map):
    """Import authors and author_settings, then update publications.primary_contact_id."""
    print_step("Migrating authors and author_settings...")

    user_group_map = maps["user_group_map"]

    old_pub_ids = tuple(pub_map.keys())
    placeholders = ",".join(["%s"] * len(old_pub_ids))

    old_cur.execute(
        f"SELECT author_id, email, include_in_browse, publication_id, submission_id, "
        f"seq, user_group_id FROM authors WHERE publication_id IN ({placeholders}) ORDER BY author_id",
        old_pub_ids
    )
    old_authors = old_cur.fetchall()

    next_author_id = get_max_id(new_cur, "authors", "author_id") + 1
    author_map = {}

    for row in old_authors:
        old_author_id = row[0]
        new_author_id = next_author_id

        old_pub_id = row[3]
        new_pub_id = pub_map.get(old_pub_id, old_pub_id)

        old_sub_id = row[4]
        new_sub_id = sub_map.get(old_sub_id, old_sub_id)

        old_group_id = row[6]
        new_group_id = user_group_map.get(old_group_id, old_group_id)

        new_cur.execute(
            "INSERT INTO authors (author_id, email, include_in_browse, publication_id, "
            "submission_id, seq, user_group_id) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (new_author_id, row[1], row[2], new_pub_id, new_sub_id, row[5], new_group_id)
        )

        author_map[old_author_id] = new_author_id
        next_author_id += 1

    new_conn.commit()

    # Import author_settings
    old_author_ids = tuple(author_map.keys())
    if old_author_ids:
        placeholders = ",".join(["%s"] * len(old_author_ids))
        old_cur.execute(
            f"SELECT author_id, locale, setting_name, setting_value, setting_type "
            f"FROM author_settings WHERE author_id IN ({placeholders})",
            old_author_ids
        )
        settings_count = 0
        for row in old_cur.fetchall():
            new_cur.execute(
                "INSERT IGNORE INTO author_settings "
                "(author_id, locale, setting_name, setting_value, setting_type) "
                "VALUES (%s, %s, %s, %s, %s)",
                (author_map[row[0]], row[1], row[2], fix_encoding(row[3]), row[4])
            )
            settings_count += 1
        new_conn.commit()
        print_ok(f"  Inserted {settings_count} author_settings rows")

    # Update publications.primary_contact_id
    print_step("Updating publications.primary_contact_id...")
    old_cur.execute(
        f"SELECT publication_id, primary_contact_id FROM publications "
        f"WHERE publication_id IN ({','.join(['%s']*len(pub_map))}) AND primary_contact_id IS NOT NULL",
        tuple(pub_map.keys())
    )
    updated_pci = 0
    for old_pub_id, old_contact_id in old_cur.fetchall():
        new_pub_id = pub_map.get(old_pub_id)
        new_contact_id = author_map.get(old_contact_id)
        if new_pub_id and new_contact_id:
            new_cur.execute(
                "UPDATE publications SET primary_contact_id = %s WHERE publication_id = %s",
                (new_contact_id, new_pub_id)
            )
            updated_pci += 1
    new_conn.commit()
    print_ok(f"  Updated {updated_pci} primary_contact_id references")

    print_ok(f"Migrated {len(author_map)} authors")
    return author_map


def migrate_citations(old_cur, new_conn, new_cur, pub_map):
    """Import citations."""
    print_step("Migrating citations...")

    old_pub_ids = tuple(pub_map.keys())
    placeholders = ",".join(["%s"] * len(old_pub_ids))

    old_cur.execute(
        f"SELECT citation_id, publication_id, raw_citation, seq "
        f"FROM citations WHERE publication_id IN ({placeholders}) ORDER BY citation_id",
        old_pub_ids
    )
    old_citations = old_cur.fetchall()

    next_cid = get_max_id(new_cur, "citations", "citation_id") + 1
    count = 0
    for row in old_citations:
        new_pub_id = pub_map[row[1]]
        new_cur.execute(
            "INSERT INTO citations (citation_id, publication_id, raw_citation, seq) "
            "VALUES (%s, %s, %s, %s)",
            (next_cid, new_pub_id, fix_encoding(row[2]), row[3])
        )
        next_cid += 1
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} citations")


def migrate_publication_settings(old_cur, new_conn, new_cur, pub_map):
    """Import publication_settings."""
    print_step("Migrating publication_settings...")

    old_pub_ids = tuple(pub_map.keys())
    placeholders = ",".join(["%s"] * len(old_pub_ids))

    old_cur.execute(
        f"SELECT publication_id, locale, setting_name, setting_value "
        f"FROM publication_settings WHERE publication_id IN ({placeholders})",
        old_pub_ids
    )
    count = 0
    for row in old_cur.fetchall():
        new_pub_id = pub_map[row[0]]
        new_cur.execute(
            "INSERT IGNORE INTO publication_settings "
            "(publication_id, locale, setting_name, setting_value) "
            "VALUES (%s, %s, %s, %s)",
            (new_pub_id, row[1], row[2], fix_encoding(row[3]))
        )
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} publication_settings rows")


def migrate_submission_files(old_cur, new_conn, new_cur, sub_map, maps):
    """Import submission_files, submission_file_settings, submission_supplementary_files."""
    print_step("Migrating submission_files...")

    genre_map = maps["genre_map"]

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT file_id, revision, source_file_id, source_revision, submission_id, "
        f"file_type, genre_id, file_size, original_file_name, file_stage, "
        f"direct_sales_price, sales_type, viewable, date_uploaded, date_modified, "
        f"uploader_user_id, assoc_type, assoc_id "
        f"FROM submission_files WHERE submission_id IN ({placeholders}) ORDER BY file_id, revision",
        old_sub_ids
    )
    old_files = old_cur.fetchall()

    next_file_id = get_max_id(new_cur, "submission_files", "file_id") + 1
    file_map = {}  # old_file_id → new_file_id

    # First pass: assign new file_ids
    for row in old_files:
        old_fid = row[0]
        if old_fid not in file_map:
            file_map[old_fid] = next_file_id
            next_file_id += 1

    # Second pass: insert with remapped IDs
    count = 0
    for row in old_files:
        old_fid = row[0]
        new_fid = file_map[old_fid]
        new_sub_id = sub_map[row[4]]

        # Remap source_file_id
        old_source_fid = row[2]
        new_source_fid = file_map.get(old_source_fid, old_source_fid) if old_source_fid else None

        # Remap genre_id
        old_genre_id = row[6]
        new_genre_id = genre_map.get(old_genre_id, old_genre_id) if old_genre_id else None

        # Remap assoc_id based on assoc_type
        assoc_type = row[16]
        assoc_id = row[17]
        # assoc_type 520 (REPRESENTATION/galley) - galleys don't exist, keep as-is or null
        # assoc_type 517 (REVIEW_ROUND) - will be remapped in step4
        # For now, set non-null assoc_ids to 0 for types we can't remap yet
        if assoc_type == 520:
            assoc_id = None  # galleys don't exist
        # assoc_type 517 will be handled in step4

        new_cur.execute(
            "INSERT INTO submission_files (file_id, revision, source_file_id, source_revision, "
            "submission_id, file_type, genre_id, file_size, original_file_name, file_stage, "
            "direct_sales_price, sales_type, viewable, date_uploaded, date_modified, "
            "uploader_user_id, assoc_type, assoc_id) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (new_fid, row[1], new_source_fid, row[3], new_sub_id,
             row[5], new_genre_id, row[7], row[8], row[9],
             row[10], row[11], row[12], row[13], row[14],
             row[15], assoc_type, assoc_id)
        )
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} submission_files rows ({len(file_map)} unique files)")

    # submission_file_settings
    print_step("Migrating submission_file_settings...")
    old_file_ids = tuple(file_map.keys())
    fplaceholders = ",".join(["%s"] * len(old_file_ids))

    old_cur.execute(
        f"SELECT file_id, locale, setting_name, setting_value, setting_type "
        f"FROM submission_file_settings WHERE file_id IN ({fplaceholders})",
        old_file_ids
    )
    sfs_count = 0
    for row in old_cur.fetchall():
        new_cur.execute(
            "INSERT IGNORE INTO submission_file_settings "
            "(file_id, locale, setting_name, setting_value, setting_type) "
            "VALUES (%s, %s, %s, %s, %s)",
            (file_map[row[0]], row[1], row[2], fix_encoding(row[3]), row[4])
        )
        sfs_count += 1
    new_conn.commit()
    print_ok(f"Migrated {sfs_count} submission_file_settings rows")

    # submission_supplementary_files
    print_step("Migrating submission_supplementary_files...")
    old_cur.execute(
        f"SELECT file_id, revision FROM submission_supplementary_files "
        f"WHERE file_id IN ({fplaceholders})",
        old_file_ids
    )
    ssf_count = 0
    for row in old_cur.fetchall():
        new_fid = file_map.get(row[0])
        if new_fid:
            new_cur.execute(
                "INSERT IGNORE INTO submission_supplementary_files (file_id, revision) "
                "VALUES (%s, %s)",
                (new_fid, row[1])
            )
            ssf_count += 1
    new_conn.commit()
    print_ok(f"Migrated {ssf_count} submission_supplementary_files rows")

    return file_map


def migrate_stage_assignments(old_cur, new_conn, new_cur, sub_map, maps):
    """Import stage_assignments."""
    print_step("Migrating stage_assignments...")

    user_group_map = maps["user_group_map"]

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT stage_assignment_id, submission_id, user_group_id, user_id, "
        f"date_assigned, recommend_only, can_change_metadata "
        f"FROM stage_assignments WHERE submission_id IN ({placeholders}) ORDER BY stage_assignment_id",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    next_sa_id = get_max_id(new_cur, "stage_assignments", "stage_assignment_id") + 1
    count = 0
    for row in old_rows:
        new_sub_id = sub_map[row[1]]
        old_group_id = row[2]
        new_group_id = user_group_map.get(old_group_id, old_group_id)

        new_cur.execute(
            "INSERT INTO stage_assignments (stage_assignment_id, submission_id, user_group_id, "
            "user_id, date_assigned, recommend_only, can_change_metadata) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (next_sa_id, new_sub_id, new_group_id, row[3], row[4], row[5], row[6])
        )
        next_sa_id += 1
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} stage_assignments")


def migrate_edit_decisions(old_cur, new_conn, new_cur, sub_map):
    """Import edit_decisions. review_round_id will be updated in step4."""
    print_step("Migrating edit_decisions...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT edit_decision_id, submission_id, review_round_id, stage_id, round, "
        f"editor_id, decision, date_decided "
        f"FROM edit_decisions WHERE submission_id IN ({placeholders}) ORDER BY edit_decision_id",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    next_ed_id = get_max_id(new_cur, "edit_decisions", "edit_decision_id") + 1
    ed_map = {}  # old → new (for reference)
    # Also store old review_round_id for later remapping
    ed_round_refs = {}  # new_ed_id → old_review_round_id

    for row in old_rows:
        old_ed_id = row[0]
        new_ed_id = next_ed_id
        new_sub_id = sub_map[row[1]]

        # review_round_id is stored but will be remapped in step4
        new_cur.execute(
            "INSERT INTO edit_decisions (edit_decision_id, submission_id, review_round_id, "
            "stage_id, round, editor_id, decision, date_decided) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (new_ed_id, new_sub_id, None, row[3], row[4], row[5], row[6], row[7])
        )

        ed_map[old_ed_id] = new_ed_id
        if row[2] is not None:
            ed_round_refs[new_ed_id] = row[2]
        next_ed_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(ed_map)} edit_decisions (review_round_id to be set in step4)")
    return ed_map, ed_round_refs


def migrate_submission_comments(old_cur, new_conn, new_cur, sub_map):
    """Import submission_comments."""
    print_step("Migrating submission_comments...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT comment_id, comment_type, role_id, submission_id, assoc_id, author_id, "
        f"comment_title, comments, date_posted, date_modified, viewable "
        f"FROM submission_comments WHERE submission_id IN ({placeholders}) ORDER BY comment_id",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    next_cid = get_max_id(new_cur, "submission_comments", "comment_id") + 1
    count = 0
    for row in old_rows:
        new_sub_id = sub_map[row[3]]
        new_cur.execute(
            "INSERT INTO submission_comments (comment_id, comment_type, role_id, submission_id, "
            "assoc_id, author_id, comment_title, comments, date_posted, date_modified, viewable) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (next_cid, row[1], row[2], new_sub_id, row[4], row[5],
             fix_encoding(row[6]), fix_encoding(row[7]), row[8], row[9], row[10])
        )
        next_cid += 1
        count += 1

    new_conn.commit()
    print_ok(f"Migrated {count} submission_comments")


def main():
    print_header("STEP 3: MIGRATE SUBMISSIONS & RELATED DATA")

    maps = load_maps()

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    new_cur.execute("SET SQL_SAFE_UPDATES = 0")

    # 1) Submissions
    sub_map = migrate_submissions(old_cur, new_conn, new_cur, maps)

    # 2) Publications
    pub_map = migrate_publications(old_cur, new_conn, new_cur, maps, sub_map)

    # 3) Authors + author_settings
    author_map = migrate_authors(old_cur, new_conn, new_cur, maps, pub_map, sub_map)

    # 4) Citations
    migrate_citations(old_cur, new_conn, new_cur, pub_map)

    # 5) Publication settings
    migrate_publication_settings(old_cur, new_conn, new_cur, pub_map)

    # 6) Submission files + settings + supplementary
    file_map = migrate_submission_files(old_cur, new_conn, new_cur, sub_map, maps)

    # 7) Stage assignments
    migrate_stage_assignments(old_cur, new_conn, new_cur, sub_map, maps)

    # 8) Edit decisions
    ed_map, ed_round_refs = migrate_edit_decisions(old_cur, new_conn, new_cur, sub_map)

    # 9) Submission comments
    migrate_submission_comments(old_cur, new_conn, new_cur, sub_map)

    # Save all new mappings
    maps["submission_map"] = {str(k): v for k, v in sub_map.items()}
    maps["publication_map"] = {str(k): v for k, v in pub_map.items()}
    maps["author_map"] = {str(k): v for k, v in author_map.items()}
    maps["file_map"] = {str(k): v for k, v in file_map.items()}
    maps["edit_decision_map"] = {str(k): v for k, v in ed_map.items()}
    maps["edit_decision_round_refs"] = {str(k): v for k, v in ed_round_refs.items()}

    # Convert int keys back to str for JSON
    serializable = {}
    for key, val in maps.items():
        if isinstance(val, dict):
            serializable[key] = {str(k): v for k, v in val.items()}
        else:
            serializable[key] = val
    with open(MAP_FILE, "w") as f:
        json.dump(serializable, f, indent=2)
    print_ok(f"Saved ID mappings to {MAP_FILE}")

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    new_conn.commit()

    print_header("STEP 3 COMPLETE")
    print_ok(f"Submissions: {len(sub_map)} ({min(sub_map.values())}-{max(sub_map.values())})")
    print_ok(f"Publications: {len(pub_map)} ({min(pub_map.values())}-{max(pub_map.values())})")
    print_ok(f"Authors: {len(author_map)}")
    print_ok(f"Files: {len(file_map)}")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()
