-- Delete all journals from Administration Dashboard

-- Clean up orphaned using clean_orphaned_data.sql

-- Apply FK using add_foreign_keys.sql

-- MANUALLY update the database and makesure the OJS still works fine
    -- journals: journal_id = 1
    -- user_groups: 
    -- - context_id = 1

-- Delete FK constraints
SELECT 
    CONCAT('ALTER TABLE ', table_name, ' DROP FOREIGN KEY ', constraint_name, ';') AS drop_commands
FROM 
    information_schema.key_column_usage 
WHERE 
    constraint_schema = 'journals' 
    AND referenced_table_name IS NOT NULL;

ALTER TABLE access_keys DROP FOREIGN KEY fk_access_keys_user;
ALTER TABLE announcement_settings DROP FOREIGN KEY fk_announcement_settings_announcement;
ALTER TABLE announcement_type_settings DROP FOREIGN KEY fk_announcement_type_settings_type;
ALTER TABLE announcements DROP FOREIGN KEY fk_announcements_type;
ALTER TABLE author_settings DROP FOREIGN KEY fk_author_settings_author;
ALTER TABLE authors DROP FOREIGN KEY fk_authors_publication;
ALTER TABLE authors DROP FOREIGN KEY fk_authors_submission;
ALTER TABLE authors DROP FOREIGN KEY fk_authors_user_group;
ALTER TABLE categories DROP FOREIGN KEY fk_categories_journal;
ALTER TABLE category_settings DROP FOREIGN KEY fk_category_settings_category;
ALTER TABLE citation_settings DROP FOREIGN KEY fk_citation_settings_citation;
ALTER TABLE citations DROP FOREIGN KEY fk_citations_publication;
ALTER TABLE completed_payments DROP FOREIGN KEY fk_completed_payments_journal;
ALTER TABLE completed_payments DROP FOREIGN KEY fk_completed_payments_user;
ALTER TABLE controlled_vocab_entries DROP FOREIGN KEY fk_controlled_vocab_entries_vocab;
ALTER TABLE controlled_vocab_entry_settings DROP FOREIGN KEY fk_controlled_vocab_entry_settings_entry;
ALTER TABLE custom_issue_orders DROP FOREIGN KEY fk_custom_issue_orders_issue;
ALTER TABLE custom_issue_orders DROP FOREIGN KEY fk_custom_issue_orders_journal;
ALTER TABLE custom_section_orders DROP FOREIGN KEY fk_custom_section_orders_issue;
ALTER TABLE custom_section_orders DROP FOREIGN KEY fk_custom_section_orders_section;
ALTER TABLE data_object_tombstone_oai_set_objects DROP FOREIGN KEY fk_tombstone_oai_set_objects_tombstone;
ALTER TABLE data_object_tombstone_settings DROP FOREIGN KEY fk_tombstone_settings_tombstone;
ALTER TABLE edit_decisions DROP FOREIGN KEY fk_edit_decisions_editor;
ALTER TABLE edit_decisions DROP FOREIGN KEY fk_edit_decisions_round;
ALTER TABLE email_log DROP FOREIGN KEY fk_email_log_sender;
ALTER TABLE email_log_users DROP FOREIGN KEY fk_email_log_users_log;
ALTER TABLE email_log_users DROP FOREIGN KEY fk_email_log_users_user;
ALTER TABLE email_templates DROP FOREIGN KEY fk_email_templates_journal;
ALTER TABLE event_log DROP FOREIGN KEY fk_event_log_user;
ALTER TABLE event_log_settings DROP FOREIGN KEY fk_event_log_settings_log;
ALTER TABLE filter_settings DROP FOREIGN KEY fk_filter_settings_filter;
ALTER TABLE filters DROP FOREIGN KEY fk_filters_group;
ALTER TABLE genre_settings DROP FOREIGN KEY fk_genre_settings_genre;
ALTER TABLE genres DROP FOREIGN KEY fk_genres_journal;
ALTER TABLE institutional_subscription_ip DROP FOREIGN KEY fk_institutional_subscription_ip_sub;
ALTER TABLE institutional_subscriptions DROP FOREIGN KEY fk_institutional_subscriptions_sub;
ALTER TABLE issue_files DROP FOREIGN KEY fk_issue_files_issue;
ALTER TABLE issue_galley_settings DROP FOREIGN KEY fk_issue_galley_settings_galley;
ALTER TABLE issue_galleys DROP FOREIGN KEY fk_issue_galleys_file;
ALTER TABLE issue_galleys DROP FOREIGN KEY fk_issue_galleys_issue;
ALTER TABLE issue_settings DROP FOREIGN KEY fk_issue_settings_issue;
ALTER TABLE issues DROP FOREIGN KEY fk_issues_journal;
ALTER TABLE item_views DROP FOREIGN KEY fk_item_views_user;
ALTER TABLE journal_settings DROP FOREIGN KEY fk_journal_settings_journal;
ALTER TABLE library_files DROP FOREIGN KEY fk_library_files_journal;
ALTER TABLE library_files DROP FOREIGN KEY fk_library_files_submission;
ALTER TABLE metadata_description_settings DROP FOREIGN KEY fk_metadata_description_settings_desc;
ALTER TABLE navigation_menu_item_assignment_settings DROP FOREIGN KEY fk_nav_menu_item_assign_settings_assign;
ALTER TABLE navigation_menu_item_assignments DROP FOREIGN KEY fk_nav_menu_item_assign_item;
ALTER TABLE navigation_menu_item_assignments DROP FOREIGN KEY fk_nav_menu_item_assign_menu;
ALTER TABLE navigation_menu_item_settings DROP FOREIGN KEY fk_nav_menu_item_settings_item;
ALTER TABLE notes DROP FOREIGN KEY fk_notes_user;
ALTER TABLE notification_settings DROP FOREIGN KEY fk_notification_settings_notification;
ALTER TABLE notification_subscription_settings DROP FOREIGN KEY fk_notification_subscription_settings_user;
ALTER TABLE notifications DROP FOREIGN KEY fk_notifications_user;
ALTER TABLE publication_categories DROP FOREIGN KEY fk_publication_categories_category;
ALTER TABLE publication_categories DROP FOREIGN KEY fk_publication_categories_publication;
ALTER TABLE publication_galley_settings DROP FOREIGN KEY fk_publication_galley_settings_galley;
ALTER TABLE publication_galleys DROP FOREIGN KEY fk_publication_galleys_file;
ALTER TABLE publication_galleys DROP FOREIGN KEY fk_publication_galleys_publication;
ALTER TABLE publication_settings DROP FOREIGN KEY fk_publication_settings_publication;
ALTER TABLE publications DROP FOREIGN KEY fk_publications_primary_contact;
ALTER TABLE publications DROP FOREIGN KEY fk_publications_section;
ALTER TABLE query_participants DROP FOREIGN KEY fk_query_participants_query;
ALTER TABLE query_participants DROP FOREIGN KEY fk_query_participants_user;
ALTER TABLE review_assignments DROP FOREIGN KEY fk_review_assignments_form;
ALTER TABLE review_assignments DROP FOREIGN KEY fk_review_assignments_reviewer;
ALTER TABLE review_assignments DROP FOREIGN KEY fk_review_assignments_reviewer_file;
ALTER TABLE review_assignments DROP FOREIGN KEY fk_review_assignments_round;
ALTER TABLE review_files DROP FOREIGN KEY fk_review_files_file;
ALTER TABLE review_files DROP FOREIGN KEY fk_review_files_review;
ALTER TABLE review_form_element_settings DROP FOREIGN KEY fk_review_form_element_settings_element;
ALTER TABLE review_form_elements DROP FOREIGN KEY fk_review_form_elements_form;
ALTER TABLE review_form_responses DROP FOREIGN KEY fk_review_form_responses_element;
ALTER TABLE review_form_responses DROP FOREIGN KEY fk_review_form_responses_review;
ALTER TABLE review_form_settings DROP FOREIGN KEY fk_review_form_settings_form;
ALTER TABLE review_round_files DROP FOREIGN KEY fk_review_round_files_file;
ALTER TABLE review_round_files DROP FOREIGN KEY fk_review_round_files_round;
ALTER TABLE section_settings DROP FOREIGN KEY fk_section_settings_section;
ALTER TABLE sections DROP FOREIGN KEY fk_sections_journal;
ALTER TABLE sections DROP FOREIGN KEY fk_sections_review_form;
ALTER TABLE sessions DROP FOREIGN KEY fk_sessions_user;
ALTER TABLE stage_assignments DROP FOREIGN KEY fk_stage_assignments_submission;
ALTER TABLE stage_assignments DROP FOREIGN KEY fk_stage_assignments_user;
ALTER TABLE stage_assignments DROP FOREIGN KEY fk_stage_assignments_user_group;
ALTER TABLE static_pages DROP FOREIGN KEY fk_static_pages_journal;
ALTER TABLE subeditor_submission_group DROP FOREIGN KEY fk_subeditor_submission_group_journal;
ALTER TABLE subeditor_submission_group DROP FOREIGN KEY fk_subeditor_submission_group_user;
ALTER TABLE submission_artwork_files DROP FOREIGN KEY fk_submission_artwork_files_file;
ALTER TABLE submission_comments DROP FOREIGN KEY fk_submission_comments_author;
ALTER TABLE submission_files DROP FOREIGN KEY fk_submission_files_genre;
ALTER TABLE submission_files DROP FOREIGN KEY fk_submission_files_source;
ALTER TABLE submission_files DROP FOREIGN KEY fk_submission_files_uploader;
ALTER TABLE submission_search_object_keywords DROP FOREIGN KEY fk_submission_search_object_keywords_keyword;
ALTER TABLE submission_search_object_keywords DROP FOREIGN KEY fk_submission_search_object_keywords_object;
ALTER TABLE submission_supplementary_files DROP FOREIGN KEY fk_submission_supplementary_files_file;
ALTER TABLE submission_tombstones DROP FOREIGN KEY fk_submission_tombstones_journal;
ALTER TABLE submission_tombstones DROP FOREIGN KEY fk_submission_tombstones_section;
ALTER TABLE submission_tombstones DROP FOREIGN KEY fk_submission_tombstones_submission;
ALTER TABLE submissions DROP FOREIGN KEY fk_submissions_current_publication;
ALTER TABLE submissions DROP FOREIGN KEY fk_submissions_journal;
ALTER TABLE submissions DROP FOREIGN KEY fk_submissions_section;
ALTER TABLE subscription_type_settings DROP FOREIGN KEY fk_subscription_type_settings_type;
ALTER TABLE subscription_types DROP FOREIGN KEY fk_subscription_types_journal;
ALTER TABLE subscriptions DROP FOREIGN KEY fk_subscriptions_journal;
ALTER TABLE subscriptions DROP FOREIGN KEY fk_subscriptions_type;
ALTER TABLE subscriptions DROP FOREIGN KEY fk_subscriptions_user;
ALTER TABLE temporary_files DROP FOREIGN KEY fk_temporary_files_user;
ALTER TABLE user_group_settings DROP FOREIGN KEY fk_user_group_settings_group;
ALTER TABLE user_group_stage DROP FOREIGN KEY fk_user_group_stage_group;
ALTER TABLE user_group_stage DROP FOREIGN KEY fk_user_group_stage_journal;
ALTER TABLE user_interests DROP FOREIGN KEY fk_user_interests_user;
ALTER TABLE user_interests DROP FOREIGN KEY fk_user_interests_vocab_entry;
ALTER TABLE user_settings DROP FOREIGN KEY fk_user_settings_user;
ALTER TABLE user_user_groups DROP FOREIGN KEY fk_user_user_groups_group;
ALTER TABLE user_user_groups DROP FOREIGN KEY fk_user_user_groups_user;

delete p from publications p 
where p.submission_id not in (
	select submission_id from submissions s 
);

delete a from authors a 
where a.publication_id  not in (
	select publication_id   from publications p  
);

delete az from author_settings az
where az.author_id not in (
	select author_id from authors a   
);

delete c from citations c
where publication_id not in (
	select publication_id from publications p    
);

delete ed from edit_decisions ed
where ed.submission_id not in (
	select submission_id from submissions s 
);

delete u from users u 
where u.user_id not in (
	select user_id from user_user_groups uug 
);

delete el from email_log el  
where el.sender_id not in (
	select user_id from user_user_groups uug 
);

delete elu from email_log_users elu  
where elu.email_log_id not in (
	select log_id from email_log el  
);

delete el from event_log el
where el.user_id not in (
	select user_id from users u   
);

delete els from event_log_settings  els
where els.log_id not in (
	select log_id from event_log el    
);

delete n from notes n
where n.user_id not in (
	select user_id from users    
);

delete ps from publication_settings ps
where ps.publication_id not in (
	select publication_id from publications p     
);

delete ra from review_assignments ra
where ra.submission_id not in (
	select submission_id from submissions s      
);

delete qp from query_participants qp
where qp.user_id not in (
	select user_id from users      
);

delete q from queries q 
where q.query_id not in (
	select query_id from query_participants qp 
);

delete sf from submission_files sf 
where sf.submission_id not in (
	select submission_id from submissions s  
);

select * from submission_settings ss 
where ss.submission_id not in (
	select submission_id from submissions s  
);

delete rf from review_files rf 
where rf.file_id not in (
	select file_id from submission_files sf   
);

delete rr from review_rounds rr 
where rr.submission_id not in (
	select submission_id from submissions s    
);

delete rrf from review_round_files rrf  
where rrf.review_round_id not in (
	select review_round_id from review_rounds rr      
);

delete sfs from submission_file_settings sfs   
where sfs.file_id not in (
	select file_id from submission_files sf        
);

delete ssf from submission_supplementary_files ssf    
where ssf.file_id not in (
	select file_id from submission_files sf          
);

delete us from user_settings us    
where us.user_id not in (
	select user_id from users u           
);

-- If you update the submission ID, 
-- Dont forget to also update the public folders and items

-- Migrate these table into the new one
-- authors
-- author_settings
-- citations
-- edit_decisions
-- email_log
-- email_log_users
-- event_log
-- event_log_settings
-- notes
-- publications
-- publication_settings
-- queries
-- query_participants
-- review_assignments
-- review_files
-- review_forms
-- review_form_elements
-- review_form_element_settings
-- review_form_responses
-- review_form_settings
-- review_rounds
-- review_round_files
-- sections
-- section_settings
-- stage_assignments
-- submissions
-- submission_files
-- submission_file_settings
-- submission_supplementary_files
-- users
-- user_groups
-- user_group_settings
-- user_group_stage
-- user_settings
-- user_user_groups
-- subeditor_submission_group


-- Before upload to final, update the old user first
select * from users u 
where u.username in (select username from users_dupe ud ) 
or u.email in (select email from users_dupe ud )

-- Delete not used users
delete u from users u
where u.email not in (
	select email from authors
) and 
u.user_id not in (
	select sf.uploader_user_id from submission_files sf 
) and
u.user_id not in (
	select el.sender_id from email_log el  
) and
u.user_id not in (
	select user_id from email_log_users elu 
) and
u.user_id not in (
	select user_id from event_log el 
) and
u.user_id not in (
	select user_id from notes 
) and
u.user_id not in (
	select user_id from stage_assignments sa  
) and
u.user_id not in (
	select reviewer_id from review_assignments  
) and
u.user_id not in (
	select editor_id from edit_assignments  
) and
u.user_id not in (
	select editor_id from edit_decisions  
) and
u.user_id not in (
	select author_id from submission_comments  
)
