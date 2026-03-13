"""
Step 6: rename_submission_folders.py
=====================================
Copies/moves article folders from the old journal structure to the new one,
renaming BOTH the folders AND the files inside them.

OJS file naming pattern:
  {submission_id}-{genre_id}-{file_id}-{revision}-{file_stage}-{date}.ext

After the DB migration, submission_id, genre_id, and file_id have all been
remapped to new values.  The physical filenames must match the DB, so this
script renames every component accordingly.

Old structure: {SOURCE_DIR}/journals/{OLD_JOURNAL_ID}/articles/{old_sub_id}/...
New structure: {TARGET_DIR}/journals/{NEW_JOURNAL_ID}/articles/{new_sub_id}/...

Prerequisites: Run step1 through step5 first (merge_id_maps.json must exist).
"""

import json
import os
import re
import shutil
import sys

# ============================================================
# CONFIGURATION — SET THESE PATHS BEFORE RUNNING
# ============================================================

# Source directory: where the old OJS files are stored
# This is the base directory that contains journals/{journal_id}/articles/
SOURCE_DIR = "/mnt/windows/Data/Projects/OJS_Elektro_new_clean2/ojs_old2/var/www/ojs-docker/volumes/private"

# Target directory: where the new OJS files should be placed
# Set to the same as SOURCE_DIR if you want to rename in-place
# Set to a different path to copy instead of rename
TARGET_DIR = "/mnt/windows/Data/Projects/OJS_Elektro_new_clean2/ojs_new2/files"

# Old and new journal IDs (should match merge_config.py)
OLD_JOURNAL_ID = 27
NEW_JOURNAL_ID = 1

# Set to True to COPY files (keeps originals), False to MOVE/RENAME
COPY_MODE = True

# Dry run: set to True to preview changes without actually renaming
DRY_RUN = True

# ============================================================

MAP_FILE = "merge_id_maps.json"

# OJS filename pattern:
#   {submission_id}-{genre_id}-{file_id}-{revision}-{file_stage}-{date}.ext
# Example: 8809-317-21327-1-2-20251013.docx
OJS_FILE_RE = re.compile(
    r"^(\d+)-(\d+)-(\d+)-(\d+)-(\d+)-(\d+)\.(.+)$"
)


def load_maps():
    """Load all required ID maps from merge_id_maps.json."""
    try:
        with open(MAP_FILE, "r") as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"ERROR: Could not load {MAP_FILE}: {e}")
        print("Make sure you've run the migration steps first.")
        sys.exit(1)

    sub_map = {int(k): int(v) for k, v in data.get("submission_map", {}).items()}
    genre_map = {int(k): int(v) for k, v in data.get("genre_map", {}).items()}
    file_map = {int(k): int(v) for k, v in data.get("file_map", {}).items()}

    if not sub_map:
        print("ERROR: No submission_map found in merge_id_maps.json")
        sys.exit(1)

    return sub_map, genre_map, file_map


def rename_ojs_file(filename, sub_map, genre_map, file_map):
    """
    Rename a single OJS filename by remapping submission_id, genre_id, file_id.

    Returns (new_filename, changed) where changed is True if any component
    was remapped.
    """
    m = OJS_FILE_RE.match(filename)
    if not m:
        return filename, False

    old_sub_id = int(m.group(1))
    old_genre_id = int(m.group(2))
    old_file_id = int(m.group(3))
    revision = m.group(4)      # keep as-is
    file_stage = m.group(5)    # keep as-is
    date_str = m.group(6)      # keep as-is
    ext = m.group(7)           # keep as-is

    new_sub_id = sub_map.get(old_sub_id, old_sub_id)
    new_genre_id = genre_map.get(old_genre_id, old_genre_id)
    new_file_id = file_map.get(old_file_id, old_file_id)

    changed = (new_sub_id != old_sub_id or
               new_genre_id != old_genre_id or
               new_file_id != old_file_id)

    new_filename = f"{new_sub_id}-{new_genre_id}-{new_file_id}-{revision}-{file_stage}-{date_str}.{ext}"
    return new_filename, changed


def rename_files_in_folder(folder_path, sub_map, genre_map, file_map, dry_run):
    """
    Walk a submission folder and rename every OJS-patterned file inside it.
    Returns (renamed_count, skipped_count).
    """
    renamed = 0
    skipped = 0

    for dirpath, _dirnames, filenames in os.walk(folder_path):
        for fname in filenames:
            new_fname, changed = rename_ojs_file(fname, sub_map, genre_map, file_map)
            if not changed:
                skipped += 1
                continue

            old_path = os.path.join(dirpath, fname)
            new_path = os.path.join(dirpath, new_fname)

            if dry_run:
                # Show relative path for readability
                rel = os.path.relpath(old_path, folder_path)
                print(f"    [DRY RUN] {rel} → {new_fname}")
            else:
                os.rename(old_path, new_path)
                rel = os.path.relpath(new_path, folder_path)
                print(f"    RENAMED: {rel}")
            renamed += 1

    return renamed, skipped


def migrate_folders():
    """Copy/move article folders and rename all files inside them."""
    sub_map, genre_map, file_map = load_maps()

    old_articles_dir = os.path.join(SOURCE_DIR, "journals", str(OLD_JOURNAL_ID), "articles")
    new_articles_dir = os.path.join(TARGET_DIR, "journals", str(NEW_JOURNAL_ID), "articles")

    if not os.path.isdir(old_articles_dir):
        print(f"ERROR: Source directory does not exist: {old_articles_dir}")
        print("Please set SOURCE_DIR correctly at the top of this file.")
        sys.exit(1)

    existing_folders = set(os.listdir(old_articles_dir)) if os.path.isdir(old_articles_dir) else set()

    print(f"Source articles dir : {old_articles_dir}")
    print(f"Target articles dir : {new_articles_dir}")
    print(f"Found {len(existing_folders)} folders in source")
    print(f"Submission map      : {len(sub_map)} entries")
    print(f"Genre map           : {len(genre_map)} entries")
    print(f"File map            : {len(file_map)} entries")
    print(f"Mode                : {'COPY' if COPY_MODE else 'MOVE/RENAME'}")
    print(f"Dry run             : {DRY_RUN}")
    print()

    if not DRY_RUN:
        os.makedirs(new_articles_dir, exist_ok=True)

    folders_done = 0
    folders_skipped = 0
    folders_not_found = 0
    total_files_renamed = 0
    total_files_skipped = 0

    for old_sub_id, new_sub_id in sorted(sub_map.items()):
        old_folder = os.path.join(old_articles_dir, str(old_sub_id))
        new_folder = os.path.join(new_articles_dir, str(new_sub_id))

        if not os.path.isdir(old_folder):
            print(f"  SKIP: Source folder not found: {old_sub_id}/")
            folders_not_found += 1
            continue

        if os.path.exists(new_folder):
            print(f"  SKIP: Target folder already exists: {new_sub_id}/")
            folders_skipped += 1
            continue

        # --- Step A: Copy or move the folder ---
        if DRY_RUN:
            print(f"  [DRY RUN] Folder {old_sub_id}/ → {new_sub_id}/")
            # For dry-run file preview, scan the *source* folder
            fr, fs = rename_files_in_folder(old_folder, sub_map, genre_map, file_map, dry_run=True)
        else:
            if COPY_MODE:
                shutil.copytree(old_folder, new_folder)
                print(f"  COPIED: {old_sub_id}/ → {new_sub_id}/")
            else:
                shutil.move(old_folder, new_folder)
                print(f"  MOVED: {old_sub_id}/ → {new_sub_id}/")

            # --- Step B: Rename files inside the NEW folder ---
            fr, fs = rename_files_in_folder(new_folder, sub_map, genre_map, file_map, dry_run=False)

        folders_done += 1
        total_files_renamed += fr
        total_files_skipped += fs

    print()
    print(f"{'='*60}")
    print(f"  Summary:")
    action = "Would process" if DRY_RUN else "Processed"
    print(f"  {action} folders   : {folders_done}")
    print(f"  Skipped (exists)   : {folders_skipped}")
    print(f"  Not found          : {folders_not_found}")
    print(f"  Files renamed      : {total_files_renamed}")
    print(f"  Files unchanged    : {total_files_skipped}")
    print(f"{'='*60}")

    if DRY_RUN:
        print()
        print("This was a DRY RUN. Set DRY_RUN = False to actually rename.")


def main():
    print(f"{'='*60}")
    print(f"  STEP 6: MIGRATE SUBMISSION FOLDERS & FILES")
    print(f"{'='*60}")
    print()

    if SOURCE_DIR.startswith("/path/to"):
        print("ERROR: Please set SOURCE_DIR at the top of this file.")
        sys.exit(1)
    if TARGET_DIR.startswith("/path/to"):
        print("ERROR: Please set TARGET_DIR at the top of this file.")
        sys.exit(1)

    migrate_folders()


if __name__ == "__main__":
    main()
