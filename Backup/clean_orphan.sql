-- =============================================================================
-- OJS Orphan Data Cleanup
-- Run this BEFORE add_foreign_keys.sql to prevent FK creation failures.
--
-- Target: 127.0.0.1:3386, dbname: journals
--
-- STRATEGY:
--   - If the FK uses ON DELETE SET NULL → the column is nullable → UPDATE SET NULL
--   - If the FK uses ON UPDATE CASCADE (no SET NULL) → column is NOT NULL → DELETE
--   - Special: context_id = 0 means "site-level" in OJS. These are legitimate
--     records but break FK to journals. We skip those (handled via comments).
--
-- ORDER MATTERS:
--   We clean from the deepest children first, working up to parents.
--   This prevents cascade issues where deleting a parent would leave
--   orphan grandchildren that we haven't cleaned yet.
--
-- Each statement includes a diagnostic SELECT COUNT(*) comment so you can
-- preview how many rows will be affected before running.
-- =============================================================================

-- ─────────────────────────────────────────────
-- PHASE 0: SAFETY — Disable FK checks during cleanup
-- (in case some FKs already exist from a previous run)
-- ─────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 0;

-- ─────────────────────────────────────────────
-- PHASE 1: DEEPEST CHILDREN (leaf tables, no dependents)
--          These tables are only referenced BY parent tables,
--          nothing else depends on them.
-- ─────────────────────────────────────────────

-- ── 1.01 author_settings → authors ──
-- preview: SELECT COUNT(*) FROM author_settings WHERE author_id NOT IN (SELECT author_id FROM authors);
DELETE FROM author_settings
WHERE author_id NOT IN (SELECT author_id FROM authors);

-- ── 1.02 citation_settings → citations ──
-- preview: SELECT COUNT(*) FROM citation_settings WHERE citation_id NOT IN (SELECT citation_id FROM citations);
DELETE FROM citation_settings
WHERE citation_id NOT IN (SELECT citation_id FROM citations);

-- ── 1.03 publication_galley_settings → publication_galleys ──
-- preview: SELECT COUNT(*) FROM publication_galley_settings WHERE galley_id NOT IN (SELECT galley_id FROM publication_galleys);
DELETE FROM publication_galley_settings
WHERE galley_id NOT IN (SELECT galley_id FROM publication_galleys);

-- ── 1.04 issue_galley_settings → issue_galleys ──
-- preview: SELECT COUNT(*) FROM issue_galley_settings WHERE galley_id NOT IN (SELECT galley_id FROM issue_galleys);
DELETE FROM issue_galley_settings
WHERE galley_id NOT IN (SELECT galley_id FROM issue_galleys);

-- ── 1.05 publication_settings → publications ──
-- preview: SELECT COUNT(*) FROM publication_settings WHERE publication_id NOT IN (SELECT publication_id FROM publications);
DELETE FROM publication_settings
WHERE publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 1.06 submission_settings → submissions ──
-- preview: SELECT COUNT(*) FROM submission_settings WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM submission_settings
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 1.07 submission_file_settings → submission_files ──
-- preview: SELECT COUNT(*) FROM submission_file_settings WHERE file_id NOT IN (SELECT file_id FROM submission_files);
DELETE FROM submission_file_settings
WHERE file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 1.08 issue_settings → issues ──
-- preview: SELECT COUNT(*) FROM issue_settings WHERE issue_id NOT IN (SELECT issue_id FROM issues);
DELETE FROM issue_settings
WHERE issue_id NOT IN (SELECT issue_id FROM issues);

-- ── 1.09 section_settings → sections ──
-- preview: SELECT COUNT(*) FROM section_settings WHERE section_id NOT IN (SELECT section_id FROM sections);
DELETE FROM section_settings
WHERE section_id NOT IN (SELECT section_id FROM sections);

-- ── 1.10 journal_settings → journals ──
-- preview: SELECT COUNT(*) FROM journal_settings WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM journal_settings
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 1.11 user_settings → users ──
-- preview: SELECT COUNT(*) FROM user_settings WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM user_settings
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 1.12 user_group_settings → user_groups ──
-- preview: SELECT COUNT(*) FROM user_group_settings WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);
DELETE FROM user_group_settings
WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);

-- ── 1.13 review_form_settings → review_forms ──
-- preview: SELECT COUNT(*) FROM review_form_settings WHERE review_form_id NOT IN (SELECT review_form_id FROM review_forms);
DELETE FROM review_form_settings
WHERE review_form_id NOT IN (SELECT review_form_id FROM review_forms);

-- ── 1.14 review_form_element_settings → review_form_elements ──
-- preview: SELECT COUNT(*) FROM review_form_element_settings WHERE review_form_element_id NOT IN (SELECT review_form_element_id FROM review_form_elements);
DELETE FROM review_form_element_settings
WHERE review_form_element_id NOT IN (SELECT review_form_element_id FROM review_form_elements);

-- ── 1.15 controlled_vocab_entry_settings → controlled_vocab_entries ──
-- preview: SELECT COUNT(*) FROM controlled_vocab_entry_settings WHERE controlled_vocab_entry_id NOT IN (SELECT controlled_vocab_entry_id FROM controlled_vocab_entries);
DELETE FROM controlled_vocab_entry_settings
WHERE controlled_vocab_entry_id NOT IN (SELECT controlled_vocab_entry_id FROM controlled_vocab_entries);

-- ── 1.16 event_log_settings → event_log ──
-- preview: SELECT COUNT(*) FROM event_log_settings WHERE log_id NOT IN (SELECT log_id FROM event_log);
DELETE FROM event_log_settings
WHERE log_id NOT IN (SELECT log_id FROM event_log);

-- ── 1.17 email_log_users → email_log ──
-- preview: SELECT COUNT(*) FROM email_log_users WHERE email_log_id NOT IN (SELECT log_id FROM email_log);
DELETE FROM email_log_users
WHERE email_log_id NOT IN (SELECT log_id FROM email_log);

-- ── 1.18 email_log_users → users ──
-- preview: SELECT COUNT(*) FROM email_log_users WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM email_log_users
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 1.19 notification_settings → notifications ──
-- preview: SELECT COUNT(*) FROM notification_settings WHERE notification_id NOT IN (SELECT notification_id FROM notifications);
DELETE FROM notification_settings
WHERE notification_id NOT IN (SELECT notification_id FROM notifications);

-- ── 1.20 navigation_menu_item_assignment_settings → navigation_menu_item_assignments ──
-- preview: SELECT COUNT(*) FROM navigation_menu_item_assignment_settings WHERE navigation_menu_item_assignment_id NOT IN (SELECT navigation_menu_item_assignment_id FROM navigation_menu_item_assignments);
DELETE FROM navigation_menu_item_assignment_settings
WHERE navigation_menu_item_assignment_id NOT IN (
  SELECT navigation_menu_item_assignment_id FROM navigation_menu_item_assignments
);

-- ── 1.21 navigation_menu_item_settings → navigation_menu_items ──
-- preview: SELECT COUNT(*) FROM navigation_menu_item_settings WHERE navigation_menu_item_id NOT IN (SELECT navigation_menu_item_id FROM navigation_menu_items);
DELETE FROM navigation_menu_item_settings
WHERE navigation_menu_item_id NOT IN (SELECT navigation_menu_item_id FROM navigation_menu_items);

-- ── 1.22 filter_settings → filters ──
-- preview: SELECT COUNT(*) FROM filter_settings WHERE filter_id NOT IN (SELECT filter_id FROM filters);
DELETE FROM filter_settings
WHERE filter_id NOT IN (SELECT filter_id FROM filters);

-- ── 1.23 subscription_type_settings → subscription_types ──
-- preview: SELECT COUNT(*) FROM subscription_type_settings WHERE type_id NOT IN (SELECT type_id FROM subscription_types);
DELETE FROM subscription_type_settings
WHERE type_id NOT IN (SELECT type_id FROM subscription_types);

-- ── 1.24 genre_settings → genres ──
-- preview: SELECT COUNT(*) FROM genre_settings WHERE genre_id NOT IN (SELECT genre_id FROM genres);
DELETE FROM genre_settings
WHERE genre_id NOT IN (SELECT genre_id FROM genres);

-- ── 1.25 category_settings → categories ──
-- preview: SELECT COUNT(*) FROM category_settings WHERE category_id NOT IN (SELECT category_id FROM categories);
DELETE FROM category_settings
WHERE category_id NOT IN (SELECT category_id FROM categories);

-- ── 1.26 static_page_settings → static_pages ──
-- preview: SELECT COUNT(*) FROM static_page_settings WHERE static_page_id NOT IN (SELECT static_page_id FROM static_pages);
DELETE FROM static_page_settings
WHERE static_page_id NOT IN (SELECT static_page_id FROM static_pages);

-- ── 1.27 metadata_description_settings → metadata_descriptions ──
-- preview: SELECT COUNT(*) FROM metadata_description_settings WHERE metadata_description_id NOT IN (SELECT metadata_description_id FROM metadata_descriptions);
DELETE FROM metadata_description_settings
WHERE metadata_description_id NOT IN (SELECT metadata_description_id FROM metadata_descriptions);

-- ── 1.28 announcement_settings → announcements ──
-- preview: SELECT COUNT(*) FROM announcement_settings WHERE announcement_id NOT IN (SELECT announcement_id FROM announcements);
DELETE FROM announcement_settings
WHERE announcement_id NOT IN (SELECT announcement_id FROM announcements);

-- ── 1.29 announcement_type_settings → announcement_types ──
-- preview: SELECT COUNT(*) FROM announcement_type_settings WHERE type_id NOT IN (SELECT type_id FROM announcement_types);
DELETE FROM announcement_type_settings
WHERE type_id NOT IN (SELECT type_id FROM announcement_types);

-- ── 1.30 data_object_tombstone_oai_set_objects → data_object_tombstones ──
-- preview: SELECT COUNT(*) FROM data_object_tombstone_oai_set_objects WHERE tombstone_id NOT IN (SELECT tombstone_id FROM data_object_tombstones);
DELETE FROM data_object_tombstone_oai_set_objects
WHERE tombstone_id NOT IN (SELECT tombstone_id FROM data_object_tombstones);

-- ── 1.31 data_object_tombstone_settings → data_object_tombstones ──
-- preview: SELECT COUNT(*) FROM data_object_tombstone_settings WHERE tombstone_id NOT IN (SELECT tombstone_id FROM data_object_tombstones);
DELETE FROM data_object_tombstone_settings
WHERE tombstone_id NOT IN (SELECT tombstone_id FROM data_object_tombstones);

-- ── 1.32 library_file_settings → library_files ──
-- preview: SELECT COUNT(*) FROM library_file_settings WHERE file_id NOT IN (SELECT file_id FROM library_files);
DELETE FROM library_file_settings
WHERE file_id NOT IN (SELECT file_id FROM library_files);

-- ─────────────────────────────────────────────
-- PHASE 2: MID-LEVEL CHILDREN
--          These depend on parent tables AND are parents to Phase 1 tables.
--          Clean their orphan references here.
-- ─────────────────────────────────────────────

-- ── 2.01 review_form_responses → review_form_elements ──
-- preview: SELECT COUNT(*) FROM review_form_responses WHERE review_form_element_id NOT IN (SELECT review_form_element_id FROM review_form_elements);
DELETE FROM review_form_responses
WHERE review_form_element_id NOT IN (SELECT review_form_element_id FROM review_form_elements);

-- ── 2.02 review_form_responses → review_assignments ──
-- preview: SELECT COUNT(*) FROM review_form_responses WHERE review_id NOT IN (SELECT review_id FROM review_assignments);
DELETE FROM review_form_responses
WHERE review_id NOT IN (SELECT review_id FROM review_assignments);

-- ── 2.03 review_form_elements → review_forms ──
-- preview: SELECT COUNT(*) FROM review_form_elements WHERE review_form_id NOT IN (SELECT review_form_id FROM review_forms);
DELETE FROM review_form_elements
WHERE review_form_id NOT IN (SELECT review_form_id FROM review_forms);

-- ── 2.04 review_files → review_assignments ──
-- preview: SELECT COUNT(*) FROM review_files WHERE review_id NOT IN (SELECT review_id FROM review_assignments);
DELETE FROM review_files
WHERE review_id NOT IN (SELECT review_id FROM review_assignments);

-- ── 2.05 review_files → submission_files ──
-- preview: SELECT COUNT(*) FROM review_files WHERE file_id NOT IN (SELECT file_id FROM submission_files);
DELETE FROM review_files
WHERE file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 2.06 review_round_files → submissions ──
-- preview: SELECT COUNT(*) FROM review_round_files WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM review_round_files
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.07 review_round_files → review_rounds ──
-- preview: SELECT COUNT(*) FROM review_round_files WHERE review_round_id NOT IN (SELECT review_round_id FROM review_rounds);
DELETE FROM review_round_files
WHERE review_round_id NOT IN (SELECT review_round_id FROM review_rounds);

-- ── 2.08 review_round_files → submission_files ──
-- preview: SELECT COUNT(*) FROM review_round_files WHERE file_id NOT IN (SELECT file_id FROM submission_files);
DELETE FROM review_round_files
WHERE file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 2.09 review_assignments → submissions ──
-- preview: SELECT COUNT(*) FROM review_assignments WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM review_assignments
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.10 review_assignments → users (reviewer_id) ──
-- preview: SELECT COUNT(*) FROM review_assignments WHERE reviewer_id NOT IN (SELECT user_id FROM users);
DELETE FROM review_assignments
WHERE reviewer_id NOT IN (SELECT user_id FROM users);

-- ── 2.11 review_assignments → review_rounds ──
-- preview: SELECT COUNT(*) FROM review_assignments WHERE review_round_id NOT IN (SELECT review_round_id FROM review_rounds);
DELETE FROM review_assignments
WHERE review_round_id NOT IN (SELECT review_round_id FROM review_rounds);

-- ── 2.12 review_assignments → review_forms (nullable) ──
-- preview: SELECT COUNT(*) FROM review_assignments WHERE review_form_id IS NOT NULL AND review_form_id NOT IN (SELECT review_form_id FROM review_forms);
UPDATE review_assignments SET review_form_id = NULL
WHERE review_form_id IS NOT NULL
  AND review_form_id NOT IN (SELECT review_form_id FROM review_forms);

-- ── 2.13 review_assignments → submission_files (reviewer_file_id, nullable) ──
-- preview: SELECT COUNT(*) FROM review_assignments WHERE reviewer_file_id IS NOT NULL AND reviewer_file_id NOT IN (SELECT file_id FROM submission_files);
UPDATE review_assignments SET reviewer_file_id = NULL
WHERE reviewer_file_id IS NOT NULL
  AND reviewer_file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 2.14 review_rounds → submissions ──
-- preview: SELECT COUNT(*) FROM review_rounds WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM review_rounds
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.15 edit_decisions → submissions ──
-- preview: SELECT COUNT(*) FROM edit_decisions WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM edit_decisions
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.16 edit_decisions → users (editor_id) ──
-- preview: SELECT COUNT(*) FROM edit_decisions WHERE editor_id NOT IN (SELECT user_id FROM users);
DELETE FROM edit_decisions
WHERE editor_id NOT IN (SELECT user_id FROM users);

-- ── 2.17 edit_decisions → review_rounds (nullable) ──
-- preview: SELECT COUNT(*) FROM edit_decisions WHERE review_round_id IS NOT NULL AND review_round_id NOT IN (SELECT review_round_id FROM review_rounds);
UPDATE edit_decisions SET review_round_id = NULL
WHERE review_round_id IS NOT NULL
  AND review_round_id NOT IN (SELECT review_round_id FROM review_rounds);

-- ── 2.18 citations → publications ──
-- preview: SELECT COUNT(*) FROM citations WHERE publication_id NOT IN (SELECT publication_id FROM publications);
DELETE FROM citations
WHERE publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 2.19 authors → publications ──
-- preview: SELECT COUNT(*) FROM authors WHERE publication_id NOT IN (SELECT publication_id FROM publications);
DELETE FROM authors
WHERE publication_id IS NOT NULL
  AND publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 2.20 authors → submissions (nullable in some OJS versions) ──
-- preview: SELECT COUNT(*) FROM authors WHERE submission_id IS NOT NULL AND submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM authors
WHERE submission_id IS NOT NULL
  AND submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.21 authors → user_groups (nullable) ──
-- preview: SELECT COUNT(*) FROM authors WHERE user_group_id IS NOT NULL AND user_group_id NOT IN (SELECT user_group_id FROM user_groups);
UPDATE authors SET user_group_id = NULL
WHERE user_group_id IS NOT NULL
  AND user_group_id NOT IN (SELECT user_group_id FROM user_groups);

-- ── 2.22 publication_galleys → publications ──
-- preview: SELECT COUNT(*) FROM publication_galleys WHERE publication_id NOT IN (SELECT publication_id FROM publications);
DELETE FROM publication_galleys
WHERE publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 2.23 publication_galleys → submission_files (file_id, nullable) ──
-- preview: SELECT COUNT(*) FROM publication_galleys WHERE file_id IS NOT NULL AND file_id NOT IN (SELECT file_id FROM submission_files);
UPDATE publication_galleys SET file_id = NULL
WHERE file_id IS NOT NULL
  AND file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 2.24 publication_categories → publications ──
-- preview: SELECT COUNT(*) FROM publication_categories WHERE publication_id NOT IN (SELECT publication_id FROM publications);
DELETE FROM publication_categories
WHERE publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 2.25 publication_categories → categories ──
-- preview: SELECT COUNT(*) FROM publication_categories WHERE category_id NOT IN (SELECT category_id FROM categories);
DELETE FROM publication_categories
WHERE category_id NOT IN (SELECT category_id FROM categories);

-- ── 2.26 publications → submissions ──
-- preview: SELECT COUNT(*) FROM publications WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM publications
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 2.27 publications → sections (nullable) ──
-- preview: SELECT COUNT(*) FROM publications WHERE section_id IS NOT NULL AND section_id NOT IN (SELECT section_id FROM sections);
UPDATE publications SET section_id = NULL
WHERE section_id IS NOT NULL
  AND section_id NOT IN (SELECT section_id FROM sections);

-- ── 2.28 publications → authors (primary_contact_id, nullable) ──
-- preview: SELECT COUNT(*) FROM publications WHERE primary_contact_id IS NOT NULL AND primary_contact_id NOT IN (SELECT author_id FROM authors);
UPDATE publications SET primary_contact_id = NULL
WHERE primary_contact_id IS NOT NULL
  AND primary_contact_id NOT IN (SELECT author_id FROM authors);

-- ── 2.29 controlled_vocab_entries → controlled_vocabs ──
-- preview: SELECT COUNT(*) FROM controlled_vocab_entries WHERE controlled_vocab_id NOT IN (SELECT controlled_vocab_id FROM controlled_vocabs);
DELETE FROM controlled_vocab_entries
WHERE controlled_vocab_id NOT IN (SELECT controlled_vocab_id FROM controlled_vocabs);

-- ── 2.30 user_interests → controlled_vocab_entries ──
-- preview: SELECT COUNT(*) FROM user_interests WHERE controlled_vocab_entry_id NOT IN (SELECT controlled_vocab_entry_id FROM controlled_vocab_entries);
DELETE FROM user_interests
WHERE controlled_vocab_entry_id NOT IN (SELECT controlled_vocab_entry_id FROM controlled_vocab_entries);

-- ── 2.31 user_interests → users ──
-- preview: SELECT COUNT(*) FROM user_interests WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM user_interests
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ─────────────────────────────────────────────
-- PHASE 3: SUBMISSION-LEVEL CHILDREN
--          Tables that reference submissions, users, user_groups, sections, etc.
-- ─────────────────────────────────────────────

-- ── 3.01 stage_assignments → submissions ──
-- preview: SELECT COUNT(*) FROM stage_assignments WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM stage_assignments
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.02 stage_assignments → users ──
-- preview: SELECT COUNT(*) FROM stage_assignments WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM stage_assignments
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 3.03 stage_assignments → user_groups ──
-- preview: SELECT COUNT(*) FROM stage_assignments WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);
DELETE FROM stage_assignments
WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);

-- ── 3.04 submission_files → submissions ──
-- preview: SELECT COUNT(*) FROM submission_files WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM submission_files
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.05 submission_files → genres (nullable) ──
-- preview: SELECT COUNT(*) FROM submission_files WHERE genre_id IS NOT NULL AND genre_id NOT IN (SELECT genre_id FROM genres);
UPDATE submission_files SET genre_id = NULL
WHERE genre_id IS NOT NULL
  AND genre_id NOT IN (SELECT genre_id FROM genres);

-- ── 3.06 submission_files → users (uploader_user_id, nullable) ──
-- preview: SELECT COUNT(*) FROM submission_files WHERE uploader_user_id IS NOT NULL AND uploader_user_id NOT IN (SELECT user_id FROM users);
UPDATE submission_files SET uploader_user_id = NULL
WHERE uploader_user_id IS NOT NULL
  AND uploader_user_id NOT IN (SELECT user_id FROM users);

-- ── 3.07 submission_files → submission_files (source_file_id, self-ref, nullable) ──
-- preview: SELECT COUNT(*) FROM submission_files WHERE source_file_id IS NOT NULL AND source_file_id NOT IN (SELECT file_id FROM submission_files);
UPDATE submission_files SET source_file_id = NULL
WHERE source_file_id IS NOT NULL
  AND source_file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 3.08 submission_artwork_files → submission_files ──
-- preview: SELECT COUNT(*) FROM submission_artwork_files WHERE file_id NOT IN (SELECT file_id FROM submission_files);
DELETE FROM submission_artwork_files
WHERE file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 3.09 submission_supplementary_files → submission_files ──
-- preview: SELECT COUNT(*) FROM submission_supplementary_files WHERE file_id NOT IN (SELECT file_id FROM submission_files);
DELETE FROM submission_supplementary_files
WHERE file_id NOT IN (SELECT file_id FROM submission_files);

-- ── 3.10 submission_comments → submissions ──
-- preview: SELECT COUNT(*) FROM submission_comments WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM submission_comments
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.11 submission_comments → users (author_id) ──
-- preview: SELECT COUNT(*) FROM submission_comments WHERE author_id NOT IN (SELECT user_id FROM users);
DELETE FROM submission_comments
WHERE author_id NOT IN (SELECT user_id FROM users);

-- ── 3.12 submission_search_objects → submissions ──
-- preview: SELECT COUNT(*) FROM submission_search_objects WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM submission_search_objects
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.13 submission_search_object_keywords → submission_search_objects ──
-- preview: SELECT COUNT(*) FROM submission_search_object_keywords WHERE object_id NOT IN (SELECT object_id FROM submission_search_objects);
DELETE FROM submission_search_object_keywords
WHERE object_id NOT IN (SELECT object_id FROM submission_search_objects);

-- ── 3.14 submission_search_object_keywords → submission_search_keyword_list ──
-- preview: SELECT COUNT(*) FROM submission_search_object_keywords WHERE keyword_id NOT IN (SELECT keyword_id FROM submission_search_keyword_list);
DELETE FROM submission_search_object_keywords
WHERE keyword_id NOT IN (SELECT keyword_id FROM submission_search_keyword_list);

-- ── 3.15 submission_tombstones → journals ──
-- preview: SELECT COUNT(*) FROM submission_tombstones WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM submission_tombstones
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 3.16 submission_tombstones → submissions ──
-- preview: SELECT COUNT(*) FROM submission_tombstones WHERE submission_id NOT IN (SELECT submission_id FROM submissions);
DELETE FROM submission_tombstones
WHERE submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.17 submission_tombstones → sections (nullable) ──
-- preview: SELECT COUNT(*) FROM submission_tombstones WHERE section_id IS NOT NULL AND section_id NOT IN (SELECT section_id FROM sections);
UPDATE submission_tombstones SET section_id = NULL
WHERE section_id IS NOT NULL
  AND section_id NOT IN (SELECT section_id FROM sections);

-- ── 3.18 library_files → submissions (nullable) ──
-- preview: SELECT COUNT(*) FROM library_files WHERE submission_id IS NOT NULL AND submission_id NOT IN (SELECT submission_id FROM submissions);
UPDATE library_files SET submission_id = NULL
WHERE submission_id IS NOT NULL
  AND submission_id NOT IN (SELECT submission_id FROM submissions);

-- ── 3.19 library_files → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM library_files WHERE context_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM library_files
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ─────────────────────────────────────────────
-- PHASE 4: USER & USER_GROUP REFERENCES
--          Tables linking users to groups, sessions, etc.
-- ─────────────────────────────────────────────

-- ── 4.01 user_user_groups → users ──
-- preview: SELECT COUNT(*) FROM user_user_groups WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM user_user_groups
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 4.02 user_user_groups → user_groups ──
-- preview: SELECT COUNT(*) FROM user_user_groups WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);
DELETE FROM user_user_groups
WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);

-- ── 4.03 user_group_stage → user_groups ──
-- preview: SELECT COUNT(*) FROM user_group_stage WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);
DELETE FROM user_group_stage
WHERE user_group_id NOT IN (SELECT user_group_id FROM user_groups);

-- ── 4.04 user_group_stage → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM user_group_stage WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM user_group_stage
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 4.05 sessions → users (nullable — user_id can be NULL for anonymous sessions) ──
-- preview: SELECT COUNT(*) FROM sessions WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT user_id FROM users);
UPDATE sessions SET user_id = NULL
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT user_id FROM users);

-- ── 4.06 temporary_files → users ──
-- preview: SELECT COUNT(*) FROM temporary_files WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM temporary_files
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 4.07 access_keys → users ──
-- preview: SELECT COUNT(*) FROM access_keys WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM access_keys
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ─────────────────────────────────────────────
-- PHASE 5: LOGGING & NOTIFICATIONS
--          email_log, event_log, notifications, notes, queries
-- ─────────────────────────────────────────────

-- ── 5.01 email_log → users (sender_id, nullable) ──
-- preview: SELECT COUNT(*) FROM email_log WHERE sender_id IS NOT NULL AND sender_id NOT IN (SELECT user_id FROM users);
UPDATE email_log SET sender_id = NULL
WHERE sender_id IS NOT NULL
  AND sender_id NOT IN (SELECT user_id FROM users);

-- ── 5.02 event_log → users (nullable) ──
-- preview: SELECT COUNT(*) FROM event_log WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT user_id FROM users);
UPDATE event_log SET user_id = NULL
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT user_id FROM users);

-- ── 5.03 notes → users ──
-- preview: SELECT COUNT(*) FROM notes WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM notes
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 5.04 notifications → users ──
-- preview: SELECT COUNT(*) FROM notifications WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT user_id FROM users);
DELETE FROM notifications
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT user_id FROM users);

-- ── 5.05 notifications → journals (context_id) ──
-- Notifications with context_id = 0 are site-level — skip those.
-- preview: SELECT COUNT(*) FROM notifications WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM notifications
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 5.06 notification_subscription_settings → users ──
-- preview: SELECT COUNT(*) FROM notification_subscription_settings WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM notification_subscription_settings
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 5.07 query_participants → queries ──
-- preview: SELECT COUNT(*) FROM query_participants WHERE query_id NOT IN (SELECT query_id FROM queries);
DELETE FROM query_participants
WHERE query_id NOT IN (SELECT query_id FROM queries);

-- ── 5.08 query_participants → users ──
-- preview: SELECT COUNT(*) FROM query_participants WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM query_participants
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ─────────────────────────────────────────────
-- PHASE 6: JOURNAL-LEVEL CHILDREN (context_id → journals)
--          These reference journals. context_id = 0 means site-level,
--          which is valid in OJS but breaks FK. We skip context_id = 0.
-- ─────────────────────────────────────────────

-- ── 6.01 issues → journals ──
-- preview: SELECT COUNT(*) FROM issues WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM issues
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 6.02 sections → journals ──
-- preview: SELECT COUNT(*) FROM sections WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM sections
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 6.03 sections → review_forms (nullable) ──
-- preview: SELECT COUNT(*) FROM sections WHERE review_form_id IS NOT NULL AND review_form_id NOT IN (SELECT review_form_id FROM review_forms);
UPDATE sections SET review_form_id = NULL
WHERE review_form_id IS NOT NULL
  AND review_form_id NOT IN (SELECT review_form_id FROM review_forms);

-- ── 6.04 submissions → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM submissions WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM submissions
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.05 submissions → sections (nullable) ──
-- preview: SELECT COUNT(*) FROM submissions WHERE section_id IS NOT NULL AND section_id NOT IN (SELECT section_id FROM sections);
UPDATE submissions SET section_id = NULL
WHERE section_id IS NOT NULL
  AND section_id NOT IN (SELECT section_id FROM sections);

-- ── 6.06 submissions → publications (current_publication_id, nullable) ──
-- preview: SELECT COUNT(*) FROM submissions WHERE current_publication_id IS NOT NULL AND current_publication_id NOT IN (SELECT publication_id FROM publications);
UPDATE submissions SET current_publication_id = NULL
WHERE current_publication_id IS NOT NULL
  AND current_publication_id NOT IN (SELECT publication_id FROM publications);

-- ── 6.07 user_groups → journals (context_id) ──
-- context_id = 0 = site-level user groups, skip those
-- preview: SELECT COUNT(*) FROM user_groups WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM user_groups
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.08 categories → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM categories WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM categories
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.09 genres → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM genres WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM genres
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.10 navigation_menus → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM navigation_menus WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM navigation_menus
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.11 navigation_menu_items → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM navigation_menu_items WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM navigation_menu_items
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.12 navigation_menu_item_assignments → navigation_menus ──
-- preview: SELECT COUNT(*) FROM navigation_menu_item_assignments WHERE navigation_menu_id NOT IN (SELECT navigation_menu_id FROM navigation_menus);
DELETE FROM navigation_menu_item_assignments
WHERE navigation_menu_id NOT IN (SELECT navigation_menu_id FROM navigation_menus);

-- ── 6.13 navigation_menu_item_assignments → navigation_menu_items ──
-- preview: SELECT COUNT(*) FROM navigation_menu_item_assignments WHERE navigation_menu_item_id NOT IN (SELECT navigation_menu_item_id FROM navigation_menu_items);
DELETE FROM navigation_menu_item_assignments
WHERE navigation_menu_item_id NOT IN (SELECT navigation_menu_item_id FROM navigation_menu_items);

-- ── 6.14 email_templates → journals (context_id) ──
-- context_id = 0 = default templates, skip those
-- preview: SELECT COUNT(*) FROM email_templates WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM email_templates
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.15 filters → journals (context_id, nullable) ──
-- preview: SELECT COUNT(*) FROM filters WHERE context_id IS NOT NULL AND context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
UPDATE filters SET context_id = NULL
WHERE context_id IS NOT NULL
  AND context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.16 filters → filter_groups ──
-- preview: SELECT COUNT(*) FROM filters WHERE filter_group_id NOT IN (SELECT filter_group_id FROM filter_groups);
DELETE FROM filters
WHERE filter_group_id NOT IN (SELECT filter_group_id FROM filter_groups);

-- ── 6.17 filters → filters (parent_filter_id, nullable, self-ref) ──
-- preview: SELECT COUNT(*) FROM filters WHERE parent_filter_id IS NOT NULL AND parent_filter_id NOT IN (SELECT filter_id FROM filters);
UPDATE filters SET parent_filter_id = NULL
WHERE parent_filter_id IS NOT NULL
  AND parent_filter_id NOT IN (SELECT filter_id FROM filters);

-- ── 6.18 static_pages → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM static_pages WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM static_pages
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.19 completed_payments → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM completed_payments WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM completed_payments
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.20 completed_payments → users ──
-- preview: SELECT COUNT(*) FROM completed_payments WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM completed_payments
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 6.21 custom_issue_orders → journals ──
-- preview: SELECT COUNT(*) FROM custom_issue_orders WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM custom_issue_orders
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 6.22 custom_issue_orders → issues ──
-- preview: SELECT COUNT(*) FROM custom_issue_orders WHERE issue_id NOT IN (SELECT issue_id FROM issues);
DELETE FROM custom_issue_orders
WHERE issue_id NOT IN (SELECT issue_id FROM issues);

-- ── 6.23 custom_section_orders → issues ──
-- preview: SELECT COUNT(*) FROM custom_section_orders WHERE issue_id NOT IN (SELECT issue_id FROM issues);
DELETE FROM custom_section_orders
WHERE issue_id NOT IN (SELECT issue_id FROM issues);

-- ── 6.24 custom_section_orders → sections ──
-- preview: SELECT COUNT(*) FROM custom_section_orders WHERE section_id NOT IN (SELECT section_id FROM sections);
DELETE FROM custom_section_orders
WHERE section_id NOT IN (SELECT section_id FROM sections);

-- ── 6.25 issue_files → issues ──
-- preview: SELECT COUNT(*) FROM issue_files WHERE issue_id NOT IN (SELECT issue_id FROM issues);
DELETE FROM issue_files
WHERE issue_id NOT IN (SELECT issue_id FROM issues);

-- ── 6.26 issue_galleys → issues ──
-- preview: SELECT COUNT(*) FROM issue_galleys WHERE issue_id NOT IN (SELECT issue_id FROM issues);
DELETE FROM issue_galleys
WHERE issue_id NOT IN (SELECT issue_id FROM issues);

-- ── 6.27 issue_galleys → issue_files (file_id, nullable) ──
-- preview: SELECT COUNT(*) FROM issue_galleys WHERE file_id IS NOT NULL AND file_id NOT IN (SELECT file_id FROM issue_files);
UPDATE issue_galleys SET file_id = NULL
WHERE file_id IS NOT NULL
  AND file_id NOT IN (SELECT file_id FROM issue_files);

-- ── 6.28 subscription_types → journals ──
-- preview: SELECT COUNT(*) FROM subscription_types WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM subscription_types
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 6.29 subscriptions → journals ──
-- preview: SELECT COUNT(*) FROM subscriptions WHERE journal_id NOT IN (SELECT journal_id FROM journals);
DELETE FROM subscriptions
WHERE journal_id NOT IN (SELECT journal_id FROM journals);

-- ── 6.30 subscriptions → users ──
-- preview: SELECT COUNT(*) FROM subscriptions WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM subscriptions
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 6.31 subscriptions → subscription_types ──
-- preview: SELECT COUNT(*) FROM subscriptions WHERE type_id NOT IN (SELECT type_id FROM subscription_types);
DELETE FROM subscriptions
WHERE type_id NOT IN (SELECT type_id FROM subscription_types);

-- ── 6.32 institutional_subscriptions → subscriptions ──
-- preview: SELECT COUNT(*) FROM institutional_subscriptions WHERE subscription_id NOT IN (SELECT subscription_id FROM subscriptions);
DELETE FROM institutional_subscriptions
WHERE subscription_id NOT IN (SELECT subscription_id FROM subscriptions);

-- ── 6.33 institutional_subscription_ip → subscriptions ──
-- preview: SELECT COUNT(*) FROM institutional_subscription_ip WHERE subscription_id NOT IN (SELECT subscription_id FROM subscriptions);
DELETE FROM institutional_subscription_ip
WHERE subscription_id NOT IN (SELECT subscription_id FROM subscriptions);

-- ── 6.34 subeditor_submission_group → journals (context_id) ──
-- preview: SELECT COUNT(*) FROM subeditor_submission_group WHERE context_id NOT IN (SELECT journal_id FROM journals) AND context_id != 0;
DELETE FROM subeditor_submission_group
WHERE context_id NOT IN (SELECT journal_id FROM journals)
  AND context_id != 0;

-- ── 6.35 subeditor_submission_group → users ──
-- preview: SELECT COUNT(*) FROM subeditor_submission_group WHERE user_id NOT IN (SELECT user_id FROM users);
DELETE FROM subeditor_submission_group
WHERE user_id NOT IN (SELECT user_id FROM users);

-- ── 6.36 announcements → announcement_types (nullable) ──
-- preview: SELECT COUNT(*) FROM announcements WHERE type_id IS NOT NULL AND type_id NOT IN (SELECT type_id FROM announcement_types);
UPDATE announcements SET type_id = NULL
WHERE type_id IS NOT NULL
  AND type_id NOT IN (SELECT type_id FROM announcement_types);

-- ── 6.37 item_views → users (nullable) ──
-- preview: SELECT COUNT(*) FROM item_views WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT user_id FROM users);
UPDATE item_views SET user_id = NULL
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT user_id FROM users);

-- ─────────────────────────────────────────────
-- PHASE 7: RE-ENABLE FK CHECKS
-- ─────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────
-- DONE!
-- Now you can safely run add_foreign_keys.sql
-- ─────────────────────────────────────────────
SELECT 'Orphan data cleanup complete. Ready for add_foreign_keys.sql.' AS status;
