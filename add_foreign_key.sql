-- =============================================================================
-- OJS Foreign Key Constraints
-- Generated based on OJS_DATABASE_RELATIONSHIPS.md + actual table/column analysis
-- Target: 127.0.0.1:3386, dbname: journals
--
-- NOTE: Some FKs may fail if orphan data exists. That's expected.
--       Each ALTER TABLE is independent so failures won't block others.
-- =============================================================================

-- ─────────────────────────────────────────────
-- 3.1 JOURNAL (CONTEXT) CHILDREN
-- ─────────────────────────────────────────────

-- journal_settings → journals
ALTER TABLE journal_settings
  ADD CONSTRAINT fk_journal_settings_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- issues → journals
ALTER TABLE issues
  ADD CONSTRAINT fk_issues_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- sections → journals
ALTER TABLE sections
  ADD CONSTRAINT fk_sections_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- submissions → journals (via context_id)
ALTER TABLE submissions
  ADD CONSTRAINT fk_submissions_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- user_groups → journals (via context_id)
ALTER TABLE user_groups
  ADD CONSTRAINT fk_user_groups_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- categories → journals (via context_id)
ALTER TABLE categories
  ADD CONSTRAINT fk_categories_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- genres → journals (via context_id)
ALTER TABLE genres
  ADD CONSTRAINT fk_genres_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- navigation_menus → journals (via context_id)
ALTER TABLE navigation_menus
  ADD CONSTRAINT fk_navigation_menus_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- navigation_menu_items → journals (via context_id)
ALTER TABLE navigation_menu_items
  ADD CONSTRAINT fk_navigation_menu_items_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- email_templates → journals (via context_id)
ALTER TABLE email_templates
  ADD CONSTRAINT fk_email_templates_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- filters → journals (via context_id)
ALTER TABLE filters
  ADD CONSTRAINT fk_filters_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- library_files → journals (via context_id)
ALTER TABLE library_files
  ADD CONSTRAINT fk_library_files_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- static_pages → journals (via context_id)
ALTER TABLE static_pages
  ADD CONSTRAINT fk_static_pages_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- completed_payments → journals (via context_id)
ALTER TABLE completed_payments
  ADD CONSTRAINT fk_completed_payments_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- custom_issue_orders → journals
ALTER TABLE custom_issue_orders
  ADD CONSTRAINT fk_custom_issue_orders_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- subscription_types → journals
ALTER TABLE subscription_types
  ADD CONSTRAINT fk_subscription_types_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- subscriptions → journals
ALTER TABLE subscriptions
  ADD CONSTRAINT fk_subscriptions_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- submission_tombstones → journals
ALTER TABLE submission_tombstones
  ADD CONSTRAINT fk_submission_tombstones_journal
  FOREIGN KEY (journal_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- notifications → journals (via context_id)
ALTER TABLE notifications
  ADD CONSTRAINT fk_notifications_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- subeditor_submission_group → journals (via context_id)
ALTER TABLE subeditor_submission_group
  ADD CONSTRAINT fk_subeditor_submission_group_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.2 USER CHILDREN
-- ─────────────────────────────────────────────

-- user_settings → users
ALTER TABLE user_settings
  ADD CONSTRAINT fk_user_settings_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- user_user_groups → users
ALTER TABLE user_user_groups
  ADD CONSTRAINT fk_user_user_groups_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- user_interests → users
ALTER TABLE user_interests
  ADD CONSTRAINT fk_user_interests_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- sessions → users
ALTER TABLE sessions
  ADD CONSTRAINT fk_sessions_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- stage_assignments → users
ALTER TABLE stage_assignments
  ADD CONSTRAINT fk_stage_assignments_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- review_assignments → users (reviewer_id)
ALTER TABLE review_assignments
  ADD CONSTRAINT fk_review_assignments_reviewer
  FOREIGN KEY (reviewer_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- edit_decisions → users (editor_id)
ALTER TABLE edit_decisions
  ADD CONSTRAINT fk_edit_decisions_editor
  FOREIGN KEY (editor_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- submission_comments → users (author_id)
ALTER TABLE submission_comments
  ADD CONSTRAINT fk_submission_comments_author
  FOREIGN KEY (author_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- submission_files → users (uploader_user_id)
ALTER TABLE submission_files
  ADD CONSTRAINT fk_submission_files_uploader
  FOREIGN KEY (uploader_user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- temporary_files → users
ALTER TABLE temporary_files
  ADD CONSTRAINT fk_temporary_files_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- email_log → users (sender_id)
ALTER TABLE email_log
  ADD CONSTRAINT fk_email_log_sender
  FOREIGN KEY (sender_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- email_log_users → users
ALTER TABLE email_log_users
  ADD CONSTRAINT fk_email_log_users_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- event_log → users
ALTER TABLE event_log
  ADD CONSTRAINT fk_event_log_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- notes → users
ALTER TABLE notes
  ADD CONSTRAINT fk_notes_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- notifications → users
ALTER TABLE notifications
  ADD CONSTRAINT fk_notifications_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- notification_subscription_settings → users
ALTER TABLE notification_subscription_settings
  ADD CONSTRAINT fk_notification_subscription_settings_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- query_participants → users
ALTER TABLE query_participants
  ADD CONSTRAINT fk_query_participants_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- access_keys → users
ALTER TABLE access_keys
  ADD CONSTRAINT fk_access_keys_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- completed_payments → users
ALTER TABLE completed_payments
  ADD CONSTRAINT fk_completed_payments_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- subscriptions → users
ALTER TABLE subscriptions
  ADD CONSTRAINT fk_subscriptions_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- subeditor_submission_group → users
ALTER TABLE subeditor_submission_group
  ADD CONSTRAINT fk_subeditor_submission_group_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- item_views → users (nullable)
ALTER TABLE item_views
  ADD CONSTRAINT fk_item_views_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.3 USER GROUPS & ROLES
-- ─────────────────────────────────────────────

-- user_user_groups → user_groups
ALTER TABLE user_user_groups
  ADD CONSTRAINT fk_user_user_groups_group
  FOREIGN KEY (user_group_id) REFERENCES user_groups(user_group_id)
  ON UPDATE CASCADE;

-- user_group_settings → user_groups
ALTER TABLE user_group_settings
  ADD CONSTRAINT fk_user_group_settings_group
  FOREIGN KEY (user_group_id) REFERENCES user_groups(user_group_id)
  ON UPDATE CASCADE;

-- user_group_stage → user_groups
ALTER TABLE user_group_stage
  ADD CONSTRAINT fk_user_group_stage_group
  FOREIGN KEY (user_group_id) REFERENCES user_groups(user_group_id)
  ON UPDATE CASCADE;

-- user_group_stage → journals (via context_id)
ALTER TABLE user_group_stage
  ADD CONSTRAINT fk_user_group_stage_journal
  FOREIGN KEY (context_id) REFERENCES journals(journal_id)
  ON UPDATE CASCADE;

-- authors → user_groups
ALTER TABLE authors
  ADD CONSTRAINT fk_authors_user_group
  FOREIGN KEY (user_group_id) REFERENCES user_groups(user_group_id)
  ON UPDATE CASCADE;

-- stage_assignments → user_groups
ALTER TABLE stage_assignments
  ADD CONSTRAINT fk_stage_assignments_user_group
  FOREIGN KEY (user_group_id) REFERENCES user_groups(user_group_id)
  ON UPDATE CASCADE;

-- user_interests → controlled_vocab_entries
ALTER TABLE user_interests
  ADD CONSTRAINT fk_user_interests_vocab_entry
  FOREIGN KEY (controlled_vocab_entry_id) REFERENCES controlled_vocab_entries(controlled_vocab_entry_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.4 SUBMISSIONS
-- ─────────────────────────────────────────────

-- submissions → sections
ALTER TABLE submissions
  ADD CONSTRAINT fk_submissions_section
  FOREIGN KEY (section_id) REFERENCES sections(section_id)
  ON UPDATE CASCADE;

-- submissions → publications (current_publication_id)
ALTER TABLE submissions
  ADD CONSTRAINT fk_submissions_current_publication
  FOREIGN KEY (current_publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- submission_settings → submissions
ALTER TABLE submission_settings
  ADD CONSTRAINT fk_submission_settings_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- submission_files → submissions
ALTER TABLE submission_files
  ADD CONSTRAINT fk_submission_files_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- submission_files → genres
ALTER TABLE submission_files
  ADD CONSTRAINT fk_submission_files_genre
  FOREIGN KEY (genre_id) REFERENCES genres(genre_id)
  ON UPDATE CASCADE;

-- submission_files → submission_files (source_file_id, self-referencing)
ALTER TABLE submission_files
  ADD CONSTRAINT fk_submission_files_source
  FOREIGN KEY (source_file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- submission_file_settings → submission_files
ALTER TABLE submission_file_settings
  ADD CONSTRAINT fk_submission_file_settings_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- submission_artwork_files → submission_files
ALTER TABLE submission_artwork_files
  ADD CONSTRAINT fk_submission_artwork_files_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- submission_supplementary_files → submission_files
ALTER TABLE submission_supplementary_files
  ADD CONSTRAINT fk_submission_supplementary_files_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- submission_comments → submissions
ALTER TABLE submission_comments
  ADD CONSTRAINT fk_submission_comments_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- submission_search_objects → submissions
ALTER TABLE submission_search_objects
  ADD CONSTRAINT fk_submission_search_objects_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- submission_search_object_keywords → submission_search_objects
ALTER TABLE submission_search_object_keywords
  ADD CONSTRAINT fk_submission_search_object_keywords_object
  FOREIGN KEY (object_id) REFERENCES submission_search_objects(object_id)
  ON UPDATE CASCADE;

-- submission_tombstones → submissions
ALTER TABLE submission_tombstones
  ADD CONSTRAINT fk_submission_tombstones_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- submission_tombstones → sections
ALTER TABLE submission_tombstones
  ADD CONSTRAINT fk_submission_tombstones_section
  FOREIGN KEY (section_id) REFERENCES sections(section_id)
  ON UPDATE CASCADE;

-- library_files → submissions
ALTER TABLE library_files
  ADD CONSTRAINT fk_library_files_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- library_file_settings → library_files
ALTER TABLE library_file_settings
  ADD CONSTRAINT fk_library_file_settings_file
  FOREIGN KEY (file_id) REFERENCES library_files(file_id)
  ON UPDATE CASCADE;

-- stage_assignments → submissions
ALTER TABLE stage_assignments
  ADD CONSTRAINT fk_stage_assignments_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.5 PUBLICATIONS
-- ─────────────────────────────────────────────

-- publications → submissions
ALTER TABLE publications
  ADD CONSTRAINT fk_publications_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- publications → sections
ALTER TABLE publications
  ADD CONSTRAINT fk_publications_section
  FOREIGN KEY (section_id) REFERENCES sections(section_id)
  ON UPDATE CASCADE;

-- publications → authors (primary_contact_id)
ALTER TABLE publications
  ADD CONSTRAINT fk_publications_primary_contact
  FOREIGN KEY (primary_contact_id) REFERENCES authors(author_id)
  ON UPDATE CASCADE;

-- publication_settings → publications
ALTER TABLE publication_settings
  ADD CONSTRAINT fk_publication_settings_publication
  FOREIGN KEY (publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- publication_galleys → publications
ALTER TABLE publication_galleys
  ADD CONSTRAINT fk_publication_galleys_publication
  FOREIGN KEY (publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- publication_galleys → submission_files (file_id)
ALTER TABLE publication_galleys
  ADD CONSTRAINT fk_publication_galleys_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- publication_galley_settings → publication_galleys
ALTER TABLE publication_galley_settings
  ADD CONSTRAINT fk_publication_galley_settings_galley
  FOREIGN KEY (galley_id) REFERENCES publication_galleys(galley_id)
  ON UPDATE CASCADE;

-- authors → publications
ALTER TABLE authors
  ADD CONSTRAINT fk_authors_publication
  FOREIGN KEY (publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- authors → submissions
ALTER TABLE authors
  ADD CONSTRAINT fk_authors_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- author_settings → authors
ALTER TABLE author_settings
  ADD CONSTRAINT fk_author_settings_author
  FOREIGN KEY (author_id) REFERENCES authors(author_id)
  ON UPDATE CASCADE;

-- citations → publications
ALTER TABLE citations
  ADD CONSTRAINT fk_citations_publication
  FOREIGN KEY (publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- citation_settings → citations
ALTER TABLE citation_settings
  ADD CONSTRAINT fk_citation_settings_citation
  FOREIGN KEY (citation_id) REFERENCES citations(citation_id)
  ON UPDATE CASCADE;

-- publication_categories → publications
ALTER TABLE publication_categories
  ADD CONSTRAINT fk_publication_categories_publication
  FOREIGN KEY (publication_id) REFERENCES publications(publication_id)
  ON UPDATE CASCADE;

-- publication_categories → categories
ALTER TABLE publication_categories
  ADD CONSTRAINT fk_publication_categories_category
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.6 ISSUES
-- ─────────────────────────────────────────────

-- issue_settings → issues
ALTER TABLE issue_settings
  ADD CONSTRAINT fk_issue_settings_issue
  FOREIGN KEY (issue_id) REFERENCES issues(issue_id)
  ON UPDATE CASCADE;

-- issue_files → issues
ALTER TABLE issue_files
  ADD CONSTRAINT fk_issue_files_issue
  FOREIGN KEY (issue_id) REFERENCES issues(issue_id)
  ON UPDATE CASCADE;

-- issue_galleys → issues
ALTER TABLE issue_galleys
  ADD CONSTRAINT fk_issue_galleys_issue
  FOREIGN KEY (issue_id) REFERENCES issues(issue_id)
  ON UPDATE CASCADE;

-- issue_galleys → issue_files (file_id)
ALTER TABLE issue_galleys
  ADD CONSTRAINT fk_issue_galleys_file
  FOREIGN KEY (file_id) REFERENCES issue_files(file_id)
  ON UPDATE CASCADE;

-- issue_galley_settings → issue_galleys
ALTER TABLE issue_galley_settings
  ADD CONSTRAINT fk_issue_galley_settings_galley
  FOREIGN KEY (galley_id) REFERENCES issue_galleys(galley_id)
  ON UPDATE CASCADE;

-- custom_issue_orders → issues
ALTER TABLE custom_issue_orders
  ADD CONSTRAINT fk_custom_issue_orders_issue
  FOREIGN KEY (issue_id) REFERENCES issues(issue_id)
  ON UPDATE CASCADE;

-- custom_section_orders → issues
ALTER TABLE custom_section_orders
  ADD CONSTRAINT fk_custom_section_orders_issue
  FOREIGN KEY (issue_id) REFERENCES issues(issue_id)
  ON UPDATE CASCADE;

-- custom_section_orders → sections
ALTER TABLE custom_section_orders
  ADD CONSTRAINT fk_custom_section_orders_section
  FOREIGN KEY (section_id) REFERENCES sections(section_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.7 SECTIONS
-- ─────────────────────────────────────────────

-- section_settings → sections
ALTER TABLE section_settings
  ADD CONSTRAINT fk_section_settings_section
  FOREIGN KEY (section_id) REFERENCES sections(section_id)
  ON UPDATE CASCADE;

-- sections → review_forms (review_form_id)
ALTER TABLE sections
  ADD CONSTRAINT fk_sections_review_form
  FOREIGN KEY (review_form_id) REFERENCES review_forms(review_form_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.8 REVIEW PROCESS
-- ─────────────────────────────────────────────

-- review_rounds → submissions
ALTER TABLE review_rounds
  ADD CONSTRAINT fk_review_rounds_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- review_assignments → submissions
ALTER TABLE review_assignments
  ADD CONSTRAINT fk_review_assignments_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- review_assignments → review_rounds
ALTER TABLE review_assignments
  ADD CONSTRAINT fk_review_assignments_round
  FOREIGN KEY (review_round_id) REFERENCES review_rounds(review_round_id)
  ON UPDATE CASCADE;

-- review_assignments → review_forms
ALTER TABLE review_assignments
  ADD CONSTRAINT fk_review_assignments_form
  FOREIGN KEY (review_form_id) REFERENCES review_forms(review_form_id)
  ON UPDATE CASCADE;

-- review_assignments → submission_files (reviewer_file_id)
ALTER TABLE review_assignments
  ADD CONSTRAINT fk_review_assignments_reviewer_file
  FOREIGN KEY (reviewer_file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- review_files → review_assignments
ALTER TABLE review_files
  ADD CONSTRAINT fk_review_files_review
  FOREIGN KEY (review_id) REFERENCES review_assignments(review_id)
  ON UPDATE CASCADE;

-- review_files → submission_files
ALTER TABLE review_files
  ADD CONSTRAINT fk_review_files_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- review_round_files → submissions
ALTER TABLE review_round_files
  ADD CONSTRAINT fk_review_round_files_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- review_round_files → review_rounds
ALTER TABLE review_round_files
  ADD CONSTRAINT fk_review_round_files_round
  FOREIGN KEY (review_round_id) REFERENCES review_rounds(review_round_id)
  ON UPDATE CASCADE;

-- review_round_files → submission_files
ALTER TABLE review_round_files
  ADD CONSTRAINT fk_review_round_files_file
  FOREIGN KEY (file_id) REFERENCES submission_files(file_id)
  ON UPDATE CASCADE;

-- review_form_settings → review_forms
ALTER TABLE review_form_settings
  ADD CONSTRAINT fk_review_form_settings_form
  FOREIGN KEY (review_form_id) REFERENCES review_forms(review_form_id)
  ON UPDATE CASCADE;

-- review_form_elements → review_forms
ALTER TABLE review_form_elements
  ADD CONSTRAINT fk_review_form_elements_form
  FOREIGN KEY (review_form_id) REFERENCES review_forms(review_form_id)
  ON UPDATE CASCADE;

-- review_form_element_settings → review_form_elements
ALTER TABLE review_form_element_settings
  ADD CONSTRAINT fk_review_form_element_settings_element
  FOREIGN KEY (review_form_element_id) REFERENCES review_form_elements(review_form_element_id)
  ON UPDATE CASCADE;

-- review_form_responses → review_form_elements
ALTER TABLE review_form_responses
  ADD CONSTRAINT fk_review_form_responses_element
  FOREIGN KEY (review_form_element_id) REFERENCES review_form_elements(review_form_element_id)
  ON UPDATE CASCADE;

-- review_form_responses → review_assignments
ALTER TABLE review_form_responses
  ADD CONSTRAINT fk_review_form_responses_review
  FOREIGN KEY (review_id) REFERENCES review_assignments(review_id)
  ON UPDATE CASCADE;

-- edit_decisions → submissions
ALTER TABLE edit_decisions
  ADD CONSTRAINT fk_edit_decisions_submission
  FOREIGN KEY (submission_id) REFERENCES submissions(submission_id)
  ON UPDATE CASCADE;

-- edit_decisions → review_rounds
ALTER TABLE edit_decisions
  ADD CONSTRAINT fk_edit_decisions_round
  FOREIGN KEY (review_round_id) REFERENCES review_rounds(review_round_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.10 CONTROLLED VOCABULARIES
-- ─────────────────────────────────────────────

-- controlled_vocab_entries → controlled_vocabs
ALTER TABLE controlled_vocab_entries
  ADD CONSTRAINT fk_controlled_vocab_entries_vocab
  FOREIGN KEY (controlled_vocab_id) REFERENCES controlled_vocabs(controlled_vocab_id)
  ON UPDATE CASCADE;

-- controlled_vocab_entry_settings → controlled_vocab_entries
ALTER TABLE controlled_vocab_entry_settings
  ADD CONSTRAINT fk_controlled_vocab_entry_settings_entry
  FOREIGN KEY (controlled_vocab_entry_id) REFERENCES controlled_vocab_entries(controlled_vocab_entry_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.11 EMAIL & EVENT LOGGING
-- ─────────────────────────────────────────────

-- email_log_users → email_log
ALTER TABLE email_log_users
  ADD CONSTRAINT fk_email_log_users_log
  FOREIGN KEY (email_log_id) REFERENCES email_log(log_id)
  ON UPDATE CASCADE;

-- event_log_settings → event_log
ALTER TABLE event_log_settings
  ADD CONSTRAINT fk_event_log_settings_log
  FOREIGN KEY (log_id) REFERENCES event_log(log_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.12 NOTIFICATIONS
-- ─────────────────────────────────────────────

-- notification_settings → notifications
ALTER TABLE notification_settings
  ADD CONSTRAINT fk_notification_settings_notification
  FOREIGN KEY (notification_id) REFERENCES notifications(notification_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.13 NAVIGATION MENUS
-- ─────────────────────────────────────────────

-- navigation_menu_item_assignments → navigation_menus
ALTER TABLE navigation_menu_item_assignments
  ADD CONSTRAINT fk_nav_menu_item_assign_menu
  FOREIGN KEY (navigation_menu_id) REFERENCES navigation_menus(navigation_menu_id)
  ON UPDATE CASCADE;

-- navigation_menu_item_assignments → navigation_menu_items
ALTER TABLE navigation_menu_item_assignments
  ADD CONSTRAINT fk_nav_menu_item_assign_item
  FOREIGN KEY (navigation_menu_item_id) REFERENCES navigation_menu_items(navigation_menu_item_id)
  ON UPDATE CASCADE;

-- navigation_menu_item_assignment_settings → navigation_menu_item_assignments
ALTER TABLE navigation_menu_item_assignment_settings
  ADD CONSTRAINT fk_nav_menu_item_assign_settings_assign
  FOREIGN KEY (navigation_menu_item_assignment_id) REFERENCES navigation_menu_item_assignments(navigation_menu_item_assignment_id)
  ON UPDATE CASCADE;

-- navigation_menu_item_settings → navigation_menu_items
ALTER TABLE navigation_menu_item_settings
  ADD CONSTRAINT fk_nav_menu_item_settings_item
  FOREIGN KEY (navigation_menu_item_id) REFERENCES navigation_menu_items(navigation_menu_item_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.14 FILTERS
-- ─────────────────────────────────────────────

-- filters → filter_groups
ALTER TABLE filters
  ADD CONSTRAINT fk_filters_group
  FOREIGN KEY (filter_group_id) REFERENCES filter_groups(filter_group_id)
  ON UPDATE CASCADE;

-- filters → filters (self-referencing parent_filter_id)
ALTER TABLE filters
  ADD CONSTRAINT fk_filters_parent
  FOREIGN KEY (parent_filter_id) REFERENCES filters(filter_id)
  ON UPDATE CASCADE;

-- filter_settings → filters
ALTER TABLE filter_settings
  ADD CONSTRAINT fk_filter_settings_filter
  FOREIGN KEY (filter_id) REFERENCES filters(filter_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.15 SUBSCRIPTIONS & PAYMENTS
-- ─────────────────────────────────────────────

-- subscriptions → subscription_types (type_id)
ALTER TABLE subscriptions
  ADD CONSTRAINT fk_subscriptions_type
  FOREIGN KEY (type_id) REFERENCES subscription_types(type_id)
  ON UPDATE CASCADE;

-- subscription_type_settings → subscription_types
ALTER TABLE subscription_type_settings
  ADD CONSTRAINT fk_subscription_type_settings_type
  FOREIGN KEY (type_id) REFERENCES subscription_types(type_id)
  ON UPDATE CASCADE;

-- institutional_subscriptions → subscriptions
ALTER TABLE institutional_subscriptions
  ADD CONSTRAINT fk_institutional_subscriptions_sub
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
  ON UPDATE CASCADE;

-- institutional_subscription_ip → subscriptions
ALTER TABLE institutional_subscription_ip
  ADD CONSTRAINT fk_institutional_subscription_ip_sub
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.16 QUERIES (DISCUSSIONS)
-- ─────────────────────────────────────────────

-- query_participants → queries
ALTER TABLE query_participants
  ADD CONSTRAINT fk_query_participants_query
  FOREIGN KEY (query_id) REFERENCES queries(query_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.18 SUBMISSION SEARCH INDEX
-- ─────────────────────────────────────────────

-- submission_search_object_keywords → submission_search_keyword_list
ALTER TABLE submission_search_object_keywords
  ADD CONSTRAINT fk_submission_search_object_keywords_keyword
  FOREIGN KEY (keyword_id) REFERENCES submission_search_keyword_list(keyword_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.19 DATA OBJECT TOMBSTONES
-- ─────────────────────────────────────────────

-- data_object_tombstone_oai_set_objects → data_object_tombstones
ALTER TABLE data_object_tombstone_oai_set_objects
  ADD CONSTRAINT fk_tombstone_oai_set_objects_tombstone
  FOREIGN KEY (tombstone_id) REFERENCES data_object_tombstones(tombstone_id)
  ON UPDATE CASCADE;

-- data_object_tombstone_settings → data_object_tombstones
ALTER TABLE data_object_tombstone_settings
  ADD CONSTRAINT fk_tombstone_settings_tombstone
  FOREIGN KEY (tombstone_id) REFERENCES data_object_tombstones(tombstone_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- 3.21 ANNOUNCEMENTS
-- ─────────────────────────────────────────────

-- announcements → announcement_types
ALTER TABLE announcements
  ADD CONSTRAINT fk_announcements_type
  FOREIGN KEY (type_id) REFERENCES announcement_types(type_id)
  ON UPDATE CASCADE;

-- announcement_settings → announcements
ALTER TABLE announcement_settings
  ADD CONSTRAINT fk_announcement_settings_announcement
  FOREIGN KEY (announcement_id) REFERENCES announcements(announcement_id)
  ON UPDATE CASCADE;

-- announcement_type_settings → announcement_types
ALTER TABLE announcement_type_settings
  ADD CONSTRAINT fk_announcement_type_settings_type
  FOREIGN KEY (type_id) REFERENCES announcement_types(type_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- SETTINGS TABLES (EAV pattern)
-- ─────────────────────────────────────────────

-- genre_settings → genres
ALTER TABLE genre_settings
  ADD CONSTRAINT fk_genre_settings_genre
  FOREIGN KEY (genre_id) REFERENCES genres(genre_id)
  ON UPDATE CASCADE;

-- category_settings → categories
ALTER TABLE category_settings
  ADD CONSTRAINT fk_category_settings_category
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
  ON UPDATE CASCADE;

-- static_page_settings → static_pages
ALTER TABLE static_page_settings
  ADD CONSTRAINT fk_static_page_settings_page
  FOREIGN KEY (static_page_id) REFERENCES static_pages(static_page_id)
  ON UPDATE CASCADE;

-- metadata_description_settings → metadata_descriptions
ALTER TABLE metadata_description_settings
  ADD CONSTRAINT fk_metadata_description_settings_desc
  FOREIGN KEY (metadata_description_id) REFERENCES metadata_descriptions(metadata_description_id)
  ON UPDATE CASCADE;

-- ─────────────────────────────────────────────
-- DONE!
-- ─────────────────────────────────────────────
SELECT 'All ALTER TABLE statements executed.' AS status;
