"""
Step 2: migrate_sections_and_reviewforms.py
============================================
Imports sections (and section_settings) from the old DB into the new DB.
Also imports the review form (review_forms, review_form_elements,
review_form_element_settings, review_form_settings) that is referenced
by the old sections and review_assignments.

Outputs:
  - section_map:     {old_section_id: new_section_id}
  - review_form_map: {old_review_form_id: new_review_form_id}
  - review_form_element_map: {old_element_id: new_element_id}

These mappings are saved to merge_id_maps.json for subsequent steps.
"""

import json
import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID, NEW_JOURNAL_ID,
    ASSOC_TYPE_JOURNAL, get_max_id,
    print_header, print_step, print_ok, print_warn,
    fix_encoding,
)

MAP_FILE = "merge_id_maps.json"


def load_maps():
    """Load existing maps or return empty dict."""
    try:
        with open(MAP_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_maps(maps):
    """Save maps to JSON file."""
    with open(MAP_FILE, "w") as f:
        json.dump(maps, f, indent=2)
    print_ok(f"Saved ID mappings to {MAP_FILE}")


def migrate_sections(old_cur, new_conn, new_cur):
    """Import sections from old DB. Maps old 'Articles' section to existing new one."""
    print_step("Migrating sections...")

    # Get old sections for our journal
    old_cur.execute(
        "SELECT section_id, review_form_id, seq, editor_restricted, meta_indexed, "
        "meta_reviewed, abstracts_not_required, hide_title, hide_author, abstract_word_count "
        "FROM sections WHERE journal_id = %s ORDER BY section_id",
        (OLD_JOURNAL_ID,)
    )
    old_sections = old_cur.fetchall()

    # Get old section settings to identify which is "Articles"
    old_cur.execute(
        "SELECT section_id, setting_value FROM section_settings "
        "WHERE section_id IN (SELECT section_id FROM sections WHERE journal_id = %s) "
        "AND setting_name = 'title' AND locale = 'en_US'",
        (OLD_JOURNAL_ID,)
    )
    old_titles = {row[0]: row[1] for row in old_cur.fetchall()}

    # New DB already has section_id=1 = "Articles"
    new_cur.execute("SELECT section_id FROM sections WHERE journal_id = %s", (NEW_JOURNAL_ID,))
    existing_sections = [row[0] for row in new_cur.fetchall()]

    # Get existing new section titles
    new_cur.execute(
        "SELECT section_id, setting_value FROM section_settings "
        "WHERE setting_name = 'title' AND locale = 'en_US'"
    )
    new_titles = {row[1]: row[0] for row in new_cur.fetchall()}  # title → section_id

    section_map = {}
    next_id = get_max_id(new_cur, "sections", "section_id") + 1

    for old_sec in old_sections:
        old_sid = old_sec[0]
        old_title = old_titles.get(old_sid, "")
        old_review_form_id = old_sec[1]

        # Check if a section with this title already exists in new DB
        if old_title in new_titles:
            section_map[old_sid] = new_titles[old_title]
            print_ok(f"  Section '{old_title}' (old={old_sid}) → existing new={new_titles[old_title]}")
        else:
            # Insert new section (review_form_id will be updated later)
            new_cur.execute(
                "INSERT INTO sections (section_id, journal_id, review_form_id, seq, "
                "editor_restricted, meta_indexed, meta_reviewed, abstracts_not_required, "
                "hide_title, hide_author, abstract_word_count) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (next_id, NEW_JOURNAL_ID, 0,  # review_form_id set to 0, updated later
                 old_sec[2], old_sec[3], old_sec[4], old_sec[5],
                 old_sec[6], old_sec[7], old_sec[8], old_sec[9])
            )
            section_map[old_sid] = next_id
            print_ok(f"  Section '{old_title}' (old={old_sid}) → new={next_id}")

            # Copy section_settings
            old_cur.execute(
                "SELECT locale, setting_name, setting_value, setting_type "
                "FROM section_settings WHERE section_id = %s",
                (old_sid,)
            )
            for ss_row in old_cur.fetchall():
                new_cur.execute(
                    "INSERT IGNORE INTO section_settings "
                    "(section_id, locale, setting_name, setting_value, setting_type) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (next_id, ss_row[0], ss_row[1], fix_encoding(ss_row[2]), ss_row[3])
                )

            next_id += 1

    new_conn.commit()
    print_ok(f"Section mapping complete: {len(section_map)} sections")
    return section_map


def migrate_review_forms(old_cur, new_conn, new_cur):
    """Import review forms, elements, and their settings."""
    print_step("Migrating review forms...")

    # Get review forms used by old journal (via sections or review_assignments)
    old_cur.execute(
        "SELECT DISTINCT review_form_id FROM review_assignments "
        "WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s) "
        "AND review_form_id IS NOT NULL",
        (OLD_JOURNAL_ID,)
    )
    used_form_ids = [row[0] for row in old_cur.fetchall()]

    # Also check sections
    old_cur.execute(
        "SELECT DISTINCT review_form_id FROM sections WHERE journal_id = %s AND review_form_id > 0",
        (OLD_JOURNAL_ID,)
    )
    for row in old_cur.fetchall():
        if row[0] not in used_form_ids:
            used_form_ids.append(row[0])

    if not used_form_ids:
        print_ok("No review forms to migrate")
        return {}, {}

    review_form_map = {}
    review_form_element_map = {}

    for old_form_id in used_form_ids:
        # Get the review form
        old_cur.execute(
            "SELECT seq, is_active FROM review_forms WHERE review_form_id = %s",
            (old_form_id,)
        )
        form_data = old_cur.fetchone()
        if not form_data:
            print_warn(f"  Review form {old_form_id} not found in old DB")
            continue

        # Insert into new DB
        new_form_id = get_max_id(new_cur, "review_forms", "review_form_id") + 1
        new_cur.execute(
            "INSERT INTO review_forms (review_form_id, assoc_type, assoc_id, seq, is_active) "
            "VALUES (%s, %s, %s, %s, %s)",
            (new_form_id, ASSOC_TYPE_JOURNAL, NEW_JOURNAL_ID, form_data[0], form_data[1])
        )
        review_form_map[old_form_id] = new_form_id
        print_ok(f"  Review form old={old_form_id} → new={new_form_id}")

        # Copy review_form_settings
        old_cur.execute(
            "SELECT locale, setting_name, setting_value, setting_type "
            "FROM review_form_settings WHERE review_form_id = %s",
            (old_form_id,)
        )
        for rfs in old_cur.fetchall():
            new_cur.execute(
                "INSERT IGNORE INTO review_form_settings "
                "(review_form_id, locale, setting_name, setting_value, setting_type) "
                "VALUES (%s, %s, %s, %s, %s)",
                (new_form_id, rfs[0], rfs[1], fix_encoding(rfs[2]), rfs[3])
            )

        # Copy review_form_elements
        old_cur.execute(
            "SELECT review_form_element_id, seq, element_type, required, included "
            "FROM review_form_elements WHERE review_form_id = %s ORDER BY review_form_element_id",
            (old_form_id,)
        )
        old_elements = old_cur.fetchall()

        for elem in old_elements:
            old_elem_id = elem[0]
            new_elem_id = get_max_id(new_cur, "review_form_elements", "review_form_element_id") + 1

            new_cur.execute(
                "INSERT INTO review_form_elements "
                "(review_form_element_id, review_form_id, seq, element_type, required, included) "
                "VALUES (%s, %s, %s, %s, %s, %s)",
                (new_elem_id, new_form_id, elem[1], elem[2], elem[3], elem[4])
            )
            review_form_element_map[old_elem_id] = new_elem_id

            # Copy element settings
            old_cur.execute(
                "SELECT locale, setting_name, setting_value, setting_type "
                "FROM review_form_element_settings WHERE review_form_element_id = %s",
                (old_elem_id,)
            )
            for es in old_cur.fetchall():
                new_cur.execute(
                    "INSERT IGNORE INTO review_form_element_settings "
                    "(review_form_element_id, locale, setting_name, setting_value, setting_type) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (new_elem_id, es[0], es[1], fix_encoding(es[2]), es[3])
                )

    new_conn.commit()
    print_ok(f"Review form mapping: {review_form_map}")
    print_ok(f"Review form element mapping: {len(review_form_element_map)} elements")
    return review_form_map, review_form_element_map


def update_section_review_forms(new_conn, new_cur, section_map, review_form_map):
    """Update sections to reference the new review_form_id."""
    if not review_form_map:
        return

    print_step("Updating sections with new review_form_ids...")

    # We need the old section → old review_form_id mapping
    old_conn = get_old_conn()
    old_cur = old_conn.cursor()

    old_cur.execute(
        "SELECT section_id, review_form_id FROM sections WHERE journal_id = %s AND review_form_id > 0",
        (OLD_JOURNAL_ID,)
    )
    for old_sid, old_rfid in old_cur.fetchall():
        new_sid = section_map.get(old_sid)
        new_rfid = review_form_map.get(old_rfid)
        if new_sid and new_rfid:
            new_cur.execute(
                "UPDATE sections SET review_form_id = %s WHERE section_id = %s",
                (new_rfid, new_sid)
            )
            print_ok(f"  Section {new_sid} → review_form_id={new_rfid}")

    new_conn.commit()
    old_cur.close()
    old_conn.close()


def migrate_genre_map(old_cur, new_cur):
    """Build genre mapping from old → new (matched by position/sort order)."""
    print_step("Building genre mapping...")

    old_cur.execute(
        "SELECT genre_id FROM genres WHERE context_id = %s ORDER BY genre_id",
        (OLD_JOURNAL_ID,)
    )
    old_genres = [row[0] for row in old_cur.fetchall()]

    new_cur.execute(
        "SELECT genre_id FROM genres WHERE context_id = %s ORDER BY genre_id",
        (NEW_JOURNAL_ID,)
    )
    new_genres = [row[0] for row in new_cur.fetchall()]

    genre_map = {}
    for i, old_gid in enumerate(old_genres):
        if i < len(new_genres):
            genre_map[old_gid] = new_genres[i]
        else:
            print_warn(f"  No matching new genre for old genre_id={old_gid}")

    print_ok(f"Genre mapping: {genre_map}")
    return genre_map


def build_user_group_map(old_cur, new_cur):
    """Build user_group mapping from old → new."""
    print_step("Building user_group mapping...")

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

    new_by_role = {}
    for gid, rid in new_groups:
        new_by_role.setdefault(rid, []).append(gid)

    old_by_role = {}
    for gid, rid in old_groups:
        old_by_role.setdefault(rid, []).append(gid)

    group_map = {}
    for role_id, old_gids in old_by_role.items():
        new_gids = new_by_role.get(role_id, [])
        for i, old_gid in enumerate(old_gids):
            if i < len(new_gids):
                group_map[old_gid] = new_gids[i]

    print_ok(f"User group mapping: {group_map}")
    return group_map


def main():
    print_header("STEP 2: MIGRATE SECTIONS & REVIEW FORMS")

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    new_cur.execute("SET SQL_SAFE_UPDATES = 0")

    # 1) Migrate sections
    section_map = migrate_sections(old_cur, new_conn, new_cur)

    # 2) Migrate review forms
    review_form_map, review_form_element_map = migrate_review_forms(old_cur, new_conn, new_cur)

    # 3) Update sections with review form references
    update_section_review_forms(new_conn, new_cur, section_map, review_form_map)

    # 4) Build genre mapping
    genre_map = migrate_genre_map(old_cur, new_cur)

    # 5) Build user_group mapping
    user_group_map = build_user_group_map(old_cur, new_cur)

    # Save all mappings
    maps = load_maps()
    maps["section_map"] = {str(k): v for k, v in section_map.items()}
    maps["review_form_map"] = {str(k): v for k, v in review_form_map.items()}
    maps["review_form_element_map"] = {str(k): v for k, v in review_form_element_map.items()}
    maps["genre_map"] = {str(k): v for k, v in genre_map.items()}
    maps["user_group_map"] = {str(k): v for k, v in user_group_map.items()}
    save_maps(maps)

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    new_conn.commit()

    print_header("STEP 2 COMPLETE")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()
