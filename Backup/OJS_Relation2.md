# OJS Database Table Relationships

> Auto-generated relationship map based on column analysis (no FK constraints defined in DB).
> OJS uses **convention-based relationships** — column names like `journal_id`, `submission_id`, `user_id` etc. imply joins.

---

## Table of Contents

1. [Core Entity Tables](#1-core-entity-tables)
2. [Relationship Diagram (Text)](#2-relationship-diagram-text)
3. [Detailed Relationships by Domain](#3-detailed-relationships-by-domain)
4. [Settings Pattern](#4-settings-pattern-eav)
5. [Polymorphic Associations (assoc_type / assoc_id)](#5-polymorphic-associations)
6. [Full Table Reference](#6-full-table-reference)

---

## 1. Core Entity Tables

These are the **primary entities** that most other tables reference:

| Table               | Primary Key            | Description                                    |
| ------------------- | ---------------------- | ---------------------------------------------- |
| `journals`          | `journal_id`           | The journal/context itself                     |
| `users`             | `user_id`              | All user accounts                              |
| `submissions`       | `submission_id`        | Manuscript submissions                         |
| `publications`      | `publication_id`       | Published versions of submissions              |
| `issues`            | `issue_id`             | Journal issues (volumes)                       |
| `sections`          | `section_id`           | Journal sections (e.g., "Articles", "Reviews") |
| `user_groups`       | `user_group_id`        | Roles like Author, Reviewer, Editor            |
| `review_rounds`     | `review_round_id`      | Review rounds for submissions                  |
| `review_forms`      | `review_form_id`       | Review form templates                          |
| `submission_files`  | `file_id` + `revision` | Uploaded files                                 |
| `controlled_vocabs` | `controlled_vocab_id`  | Keyword vocabularies                           |
| `categories`        | `category_id`          | Publication categories                         |
| `navigation_menus`  | `navigation_menu_id`   | Navigation menus                               |
| `filter_groups`     | `filter_group_id`      | Filter group definitions                       |

---

## 2. Relationship Diagram (Text)

```
                                    ┌──────────────┐
                                    │   journals   │
                                    │ (journal_id) │
                                    └──────┬───────┘
                    ┌──────────────────────┼──────────────────────────┐
                    │                      │                          │
              ┌─────▼──────┐        ┌──────▼───────┐          ┌──────▼───────┐
              │   issues   │        │  sections    │          │    users     │
              │ (issue_id) │        │(section_id)  │          │  (user_id)  │
              └─────┬──────┘        └──────┬───────┘          └──────┬───────┘
                    │                      │                         │
         ┌──────────┤              ┌───────┤              ┌─────────┼─────────┐
         │          │              │       │              │         │         │
    issue_files  issue_galleys     │  ┌────▼─────────┐  roles  sessions  user_groups
                                   │  │ submissions  │              (via user_user_groups)
                                   │  │(submission_id)│
                                   │  └──────┬───────┘
                                   │         │
                    ┌──────────────┼─────────┼────────────────────┐
                    │              │         │                    │
             ┌──────▼───────┐     │  ┌──────▼───────┐    ┌──────▼──────────┐
             │ publications │     │  │   authors    │    │ submission_files │
             │(publication_ │     │  │ (author_id)  │    │(file_id+revision)│
             │     id)      │     │  └──────────────┘    └─────────────────┘
             └──────┬───────┘     │
                    │             │
         ┌──────────┤      ┌──────▼──────────┐
         │          │      │review_assignments│
    pub_galleys  citations │  (review_id)    │
                           └─────────────────┘
```

---

## 3. Detailed Relationships by Domain

### 3.1 Journal (Context)

The `journals` table is the top-level context. OJS is multi-journal capable.

| Child Table                  | FK Column    | Relationship                      |
| ---------------------------- | ------------ | --------------------------------- |
| `journal_settings`           | `journal_id` | Journal config (EAV)              |
| `issues`                     | `journal_id` | Issues belong to a journal        |
| `sections`                   | `journal_id` | Sections belong to a journal      |
| `submissions`                | `context_id` | Submissions belong to a journal   |
| `roles`                      | `journal_id` | User-role assignments per journal |
| `user_groups`                | `context_id` | User groups per journal           |
| `categories`                 | `context_id` | Categories per journal            |
| `genres`                     | `context_id` | File genres per journal           |
| `navigation_menus`           | `context_id` | Navigation menus per journal      |
| `navigation_menu_items`      | `context_id` | Menu items per journal            |
| `plugin_settings`            | `context_id` | Plugin config per journal         |
| `email_templates`            | `context_id` | Email templates per journal       |
| `filters`                    | `context_id` | Filters per journal               |
| `library_files`              | `context_id` | Library files per journal         |
| `static_pages`               | `context_id` | Static pages per journal          |
| `subscriptions`              | `journal_id` | Subscriptions per journal         |
| `subscription_types`         | `journal_id` | Subscription types per journal    |
| `completed_payments`         | `context_id` | Payments per journal              |
| `custom_issue_orders`        | `journal_id` | Custom issue ordering             |
| `theses`                     | `journal_id` | Thesis submissions                |
| `books_for_review`           | `journal_id` | Books for review                  |
| `external_feeds`             | `journal_id` | External RSS feeds                |
| `pln_deposits`               | `journal_id` | PLN preservation deposits         |
| `pln_deposit_objects`        | `journal_id` | PLN deposit objects               |
| `review_object_types`        | `context_id` | Review object types               |
| `objects_for_review`         | `context_id` | Objects for review                |
| `rt_versions`                | `journal_id` | Reading tools versions            |
| `subeditor_submission_group` | `context_id` | Sub-editor assignments            |
| `submission_tombstones`      | `journal_id` | Deleted submission records        |
| `metrics`                    | `context_id` | Usage metrics                     |

### 3.2 Users

| Child Table                          | FK Column                              | Relationship                           |
| ------------------------------------ | -------------------------------------- | -------------------------------------- |
| `user_settings`                      | `user_id`                              | User profile settings (EAV)            |
| `user_user_groups`                   | `user_id`                              | Users ↔ User Groups (M2M)              |
| `user_interests`                     | `user_id`                              | Users ↔ Controlled Vocab Entries (M2M) |
| `roles`                              | `user_id`                              | Legacy role assignments                |
| `sessions`                           | `user_id`                              | Active sessions                        |
| `authors`                            | → links via `email` or `user_group_id` | Author records                         |
| `stage_assignments`                  | `user_id`                              | Workflow stage assignments             |
| `review_assignments`                 | `reviewer_id`                          | Review assignments (reviewer)          |
| `edit_assignments`                   | `editor_id`                            | Edit assignments (legacy)              |
| `edit_decisions`                     | `editor_id`                            | Editorial decisions                    |
| `submission_comments`                | `author_id`                            | Comments on submissions                |
| `submission_files`                   | `uploader_user_id`                     | File uploader                          |
| `temporary_files`                    | `user_id`                              | Temporary uploaded files               |
| `email_log`                          | `sender_id`                            | Emails sent by user                    |
| `email_log_users`                    | `user_id`                              | Email recipients                       |
| `event_log`                          | `user_id`                              | Event log entries                      |
| `notes`                              | `user_id`                              | Notes created by user                  |
| `notifications`                      | `user_id`                              | Notifications for user                 |
| `notification_subscription_settings` | `user_id`                              | Notification preferences               |
| `queries`                            | → via `query_participants`             | Discussion queries                     |
| `query_participants`                 | `user_id`                              | Query participants                     |
| `access_keys`                        | `user_id`                              | One-time access keys                   |
| `completed_payments`                 | `user_id`                              | Payments made by user                  |
| `comments`                           | `user_id`                              | Reader comments                        |
| `subscriptions`                      | `user_id`                              | User subscriptions                     |
| `group_memberships`                  | `user_id`                              | Group memberships                      |
| `subeditor_submission_group`         | `user_id`                              | Sub-editor section assignments         |
| `books_for_review`                   | `user_id`                              | Book review reviewer                   |
| `books_for_review`                   | `editor_id`                            | Book review editor                     |
| `object_for_review_assignments`      | `user_id`                              | Object review assignments              |

### 3.3 User Groups & Roles

```
users ──M2M──> user_user_groups ──> user_groups ──> user_group_settings
                                         │
                                         ├──> user_group_stage (which stages this group can access)
                                         │
                                         └──> authors.user_group_id
                                              stage_assignments.user_group_id
```

| Table                 | FK Column                                 | Relationship                  |
| --------------------- | ----------------------------------------- | ----------------------------- |
| `user_user_groups`    | `user_group_id`, `user_id`                | M2M: users ↔ user_groups      |
| `user_group_settings` | `user_group_id`                           | User group labels (EAV)       |
| `user_group_stage`    | `user_group_id`, `context_id`, `stage_id` | Which stages a group accesses |
| `authors`             | `user_group_id`                           | Author's role/group           |
| `stage_assignments`   | `user_group_id`                           | Stage assignment role         |

### 3.4 Submissions (The Central Workflow Entity)

```
submissions ──> publications (1:N, each submission can have multiple publication versions)
     │
     ├──> submission_settings (EAV)
     ├──> submission_files (1:N)
     ├──> authors (1:N, via submission_id or publication_id)
     ├──> review_rounds (1:N)
     ├──> review_assignments (1:N)
     ├──> edit_decisions (1:N)
     ├──> stage_assignments (1:N)
     ├──> submission_comments (1:N)
     ├──> submission_search_objects (1:N)
     ├──> email_log (via assoc_type/assoc_id)
     ├──> event_log (via assoc_type/assoc_id)
     └──> queries (via assoc_type/assoc_id)
```

| Child Table                          | FK Column                       | Relationship                         |
| ------------------------------------ | ------------------------------- | ------------------------------------ |
| `submission_settings`                | `submission_id`                 | Submission metadata (EAV)            |
| `publications`                       | `submission_id`                 | Publication versions                 |
| `submissions.current_publication_id` | → `publications.publication_id` | Current active publication           |
| `submissions.section_id`             | → `sections.section_id`         | Section assignment                   |
| `authors`                            | `submission_id`                 | Authors of submission                |
| `submission_files`                   | `submission_id`                 | Uploaded files                       |
| `submission_file_settings`           | `file_id`                       | File metadata (EAV)                  |
| `submission_artwork_files`           | `file_id`, `revision`           | Artwork file metadata                |
| `submission_supplementary_files`     | `file_id`, `revision`           | Supplementary file flag              |
| `review_rounds`                      | `submission_id`                 | Review rounds                        |
| `review_round_files`                 | `submission_id`                 | Files attached to review rounds      |
| `review_assignments`                 | `submission_id`                 | Reviewer assignments                 |
| `review_files`                       | `review_id` → `file_id`         | Files shown to reviewer              |
| `edit_decisions`                     | `submission_id`                 | Editorial decisions                  |
| `edit_assignments`                   | `article_id` (= submission_id)  | Legacy editor assignments            |
| `stage_assignments`                  | `submission_id`                 | Workflow stage participants          |
| `submission_comments`                | `submission_id`                 | Internal comments                    |
| `submission_search_objects`          | `submission_id`                 | Full-text search index               |
| `submission_xml_galleys`             | `submission_id`                 | XML galley files                     |
| `submission_tombstones`              | `submission_id`                 | Deleted submission placeholders      |
| `referrals`                          | `submission_id`                 | External referrals                   |
| `books_for_review`                   | `submission_id`                 | Linked book reviews                  |
| `dataverse_studies`                  | `submission_id`                 | Dataverse study links                |
| `dataverse_files`                    | `submission_id`                 | Dataverse file links                 |
| `library_files`                      | `submission_id`                 | Library files attached to submission |
| `metrics`                            | `submission_id`                 | Usage statistics                     |
| `comments`                           | `submission_id`                 | Reader comments                      |
| `object_for_review_assignments`      | `submission_id`                 | Object review links                  |

### 3.5 Publications (Versioned Submissions)

```
publications ──> publication_settings (EAV)
     │
     ├──> publication_galleys (1:N) ──> publication_galley_settings
     ├──> authors (1:N, via publication_id)
     ├──> citations (1:N, via publication_id)
     └──> publication_categories (M2M with categories)
```

| Child Table                          | FK Column                       | Relationship                        |
| ------------------------------------ | ------------------------------- | ----------------------------------- |
| `publication_settings`               | `publication_id`                | Publication metadata (EAV)          |
| `publication_galleys`                | `publication_id`                | Galley files (PDF, HTML, etc.)      |
| `publication_galley_settings`        | `galley_id`                     | Galley metadata (EAV)               |
| `publication_galleys.file_id`        | → `submission_files.file_id`    | Linked file                         |
| `authors`                            | `publication_id`                | Authors of this publication version |
| `citations`                          | `publication_id`                | Reference citations                 |
| `citation_settings`                  | `citation_id`                   | Citation metadata (EAV)             |
| `publication_categories`             | `publication_id`, `category_id` | M2M: publications ↔ categories      |
| `publications.section_id`            | → `sections.section_id`         | Section assignment                  |
| `publications.primary_contact_id`    | → `authors.author_id`           | Primary contact author              |
| `submissions.current_publication_id` | → `publications.publication_id` | Currently active publication        |

### 3.6 Issues

```
issues ──> issue_settings (EAV)
  │
  ├──> issue_files (1:N)
  ├──> issue_galleys (1:N) ──> issue_galley_settings
  ├──> custom_issue_orders (ordering)
  └──> custom_section_orders (section ordering within issue)
```

| Child Table             | FK Column                | Relationship               |
| ----------------------- | ------------------------ | -------------------------- |
| `issue_settings`        | `issue_id`               | Issue metadata (EAV)       |
| `issue_files`           | `issue_id`               | Files attached to issue    |
| `issue_galleys`         | `issue_id`               | Issue-level galleys        |
| `issue_galley_settings` | `galley_id`              | Galley metadata (EAV)      |
| `issue_galleys.file_id` | → `issue_files.file_id`  | Linked issue file          |
| `custom_issue_orders`   | `issue_id`               | Custom issue ordering      |
| `custom_section_orders` | `issue_id`, `section_id` | Section order within issue |

### 3.7 Sections

| Child Table               | FK Column                       | Relationship               |
| ------------------------- | ------------------------------- | -------------------------- |
| `section_settings`        | `section_id`                    | Section metadata (EAV)     |
| `sections.journal_id`     | → `journals.journal_id`         | Parent journal             |
| `sections.review_form_id` | → `review_forms.review_form_id` | Default review form        |
| `submissions.section_id`  | → `sections.section_id`         | Submissions in section     |
| `publications.section_id` | → `sections.section_id`         | Publications in section    |
| `custom_section_orders`   | `section_id`                    | Section order within issue |
| `submission_tombstones`   | `section_id`                    | Deleted submission section |

### 3.8 Review Process

```
submissions ──> review_rounds (1:N)
                    │
                    ├──> review_assignments (1:N) ──> review_files (reviewer files)
                    │        │
                    │        ├──> review_form_responses (responses)
                    │        └──> reviewer_id → users
                    │
                    └──> review_round_files (files for the round)

review_forms ──> review_form_elements ──> review_form_element_settings
     │                    │
     │                    └──> review_form_responses
     └──> review_form_settings
```

| Table                                          | FK Column | Refers To                     |
| ---------------------------------------------- | --------- | ----------------------------- |
| `review_rounds.submission_id`                  | →         | `submissions`                 |
| `review_assignments.submission_id`             | →         | `submissions`                 |
| `review_assignments.reviewer_id`               | →         | `users`                       |
| `review_assignments.review_round_id`           | →         | `review_rounds`               |
| `review_assignments.review_form_id`            | →         | `review_forms`                |
| `review_assignments.reviewer_file_id`          | →         | `submission_files.file_id`    |
| `review_files.review_id`                       | →         | `review_assignments`          |
| `review_files.file_id`                         | →         | `submission_files.file_id`    |
| `review_round_files.submission_id`             | →         | `submissions`                 |
| `review_round_files.review_round_id`           | →         | `review_rounds`               |
| `review_round_files.file_id`                   | →         | `submission_files.file_id`    |
| `review_forms.assoc_type/assoc_id`             | →         | Polymorphic (usually journal) |
| `review_form_elements.review_form_id`          | →         | `review_forms`                |
| `review_form_responses.review_form_element_id` | →         | `review_form_elements`        |
| `review_form_responses.review_id`              | →         | `review_assignments`          |
| `edit_decisions.submission_id`                 | →         | `submissions`                 |
| `edit_decisions.editor_id`                     | →         | `users`                       |
| `edit_decisions.review_round_id`               | →         | `review_rounds`               |

### 3.9 Authors

| Table                             | FK Column | Refers To           |
| --------------------------------- | --------- | ------------------- |
| `authors.submission_id`           | →         | `submissions`       |
| `authors.publication_id`          | →         | `publications`      |
| `authors.user_group_id`           | →         | `user_groups`       |
| `author_settings.author_id`       | →         | `authors`           |
| `publications.primary_contact_id` | →         | `authors.author_id` |

### 3.10 Controlled Vocabularies (Keywords, Subjects, etc.)

```
controlled_vocabs ──> controlled_vocab_entries ──> controlled_vocab_entry_settings
                           │
                           └──> user_interests (M2M with users)
```

| Table                                                       | FK Column | Refers To                               |
| ----------------------------------------------------------- | --------- | --------------------------------------- |
| `controlled_vocabs.assoc_type/assoc_id`                     | →         | Polymorphic (submission, journal, etc.) |
| `controlled_vocab_entries.controlled_vocab_id`              | →         | `controlled_vocabs`                     |
| `controlled_vocab_entry_settings.controlled_vocab_entry_id` | →         | `controlled_vocab_entries`              |
| `user_interests.controlled_vocab_entry_id`                  | →         | `controlled_vocab_entries`              |
| `user_interests.user_id`                                    | →         | `users`                                 |

### 3.11 Email & Event Logging

| Table                           | FK Column | Refers To                        |
| ------------------------------- | --------- | -------------------------------- |
| `email_log.sender_id`           | →         | `users`                          |
| `email_log.assoc_type/assoc_id` | →         | Polymorphic (usually submission) |
| `email_log_users.email_log_id`  | →         | `email_log`                      |
| `email_log_users.user_id`       | →         | `users`                          |
| `event_log.user_id`             | →         | `users`                          |
| `event_log.assoc_type/assoc_id` | →         | Polymorphic (usually submission) |
| `event_log_settings.log_id`     | →         | `event_log`                      |

### 3.12 Notifications

| Table                                        | FK Column | Refers To       |
| -------------------------------------------- | --------- | --------------- |
| `notifications.user_id`                      | →         | `users`         |
| `notifications.context_id`                   | →         | `journals`      |
| `notifications.assoc_type/assoc_id`          | →         | Polymorphic     |
| `notification_settings.notification_id`      | →         | `notifications` |
| `notification_subscription_settings.user_id` | →         | `users`         |

### 3.13 Navigation Menus

```
navigation_menus ──> navigation_menu_item_assignments ──> navigation_menu_items
                          │                                      │
                          ├──> parent_id (self-ref)              └──> navigation_menu_item_settings
                          └──> nav_menu_item_assignment_settings
```

| Table                                                                         | FK Column | Refers To                                 |
| ----------------------------------------------------------------------------- | --------- | ----------------------------------------- |
| `navigation_menus.context_id`                                                 | →         | `journals`                                |
| `navigation_menu_items.context_id`                                            | →         | `journals`                                |
| `navigation_menu_item_assignments.navigation_menu_id`                         | →         | `navigation_menus`                        |
| `navigation_menu_item_assignments.navigation_menu_item_id`                    | →         | `navigation_menu_items`                   |
| `navigation_menu_item_assignments.parent_id`                                  | →         | `navigation_menu_item_assignments` (self) |
| `navigation_menu_item_assignment_settings.navigation_menu_item_assignment_id` | →         | `navigation_menu_item_assignments`        |
| `navigation_menu_item_settings.navigation_menu_item_id`                       | →         | `navigation_menu_items`                   |

### 3.14 Filters

| Table                       | FK Column | Refers To                    |
| --------------------------- | --------- | ---------------------------- |
| `filters.filter_group_id`   | →         | `filter_groups`              |
| `filters.parent_filter_id`  | →         | `filters` (self-referencing) |
| `filters.context_id`        | →         | `journals`                   |
| `filter_settings.filter_id` | →         | `filters`                    |

### 3.15 Subscriptions & Payments

```
subscriptions ──> subscription_types
     │                  │
     │                  └──> subscription_type_settings
     │
     ├──> institutional_subscriptions ──> institutional_subscription_ip
     │
     └──> users (via user_id)

queued_payments (pending)
completed_payments (completed)
paypal_transactions (PayPal specifics)
```

| Table                                           | FK Column | Refers To            |
| ----------------------------------------------- | --------- | -------------------- |
| `subscriptions.journal_id`                      | →         | `journals`           |
| `subscriptions.user_id`                         | →         | `users`              |
| `subscriptions.type_id`                         | →         | `subscription_types` |
| `subscription_types.journal_id`                 | →         | `journals`           |
| `subscription_type_settings.type_id`            | →         | `subscription_types` |
| `institutional_subscriptions.subscription_id`   | →         | `subscriptions`      |
| `institutional_subscription_ip.subscription_id` | →         | `subscriptions`      |
| `completed_payments.context_id`                 | →         | `journals`           |
| `completed_payments.user_id`                    | →         | `users`              |

### 3.16 Queries (Discussions)

| Table                         | FK Column | Refers To                        |
| ----------------------------- | --------- | -------------------------------- |
| `queries.assoc_type/assoc_id` | →         | Polymorphic (usually submission) |
| `query_participants.query_id` | →         | `queries`                        |
| `query_participants.user_id`  | →         | `users`                          |

### 3.17 Stage Assignments (Workflow)

| Table                             | FK Column | Refers To     |
| --------------------------------- | --------- | ------------- |
| `stage_assignments.submission_id` | →         | `submissions` |
| `stage_assignments.user_group_id` | →         | `user_groups` |
| `stage_assignments.user_id`       | →         | `users`       |
| `user_group_stage.user_group_id`  | →         | `user_groups` |
| `user_group_stage.context_id`     | →         | `journals`    |

### 3.18 Submission Search Index

```
submission_search_objects ──> submission_search_object_keywords ──> submission_search_keyword_list
```

| Table                                          | FK Column | Refers To                        |
| ---------------------------------------------- | --------- | -------------------------------- |
| `submission_search_objects.submission_id`      | →         | `submissions`                    |
| `submission_search_object_keywords.object_id`  | →         | `submission_search_objects`      |
| `submission_search_object_keywords.keyword_id` | →         | `submission_search_keyword_list` |

### 3.19 Data Object Tombstones (OAI Deletion Records)

| Table                                                | FK Column | Refers To                |
| ---------------------------------------------------- | --------- | ------------------------ |
| `data_object_tombstones.data_object_id`              | →         | Original deleted object  |
| `data_object_tombstone_oai_set_objects.tombstone_id` | →         | `data_object_tombstones` |
| `data_object_tombstone_settings.tombstone_id`        | →         | `data_object_tombstones` |

### 3.20 Groups (Editorial Teams, etc.)

| Table                        | FK Column | Refers To                     |
| ---------------------------- | --------- | ----------------------------- |
| `groups.assoc_type/assoc_id` | →         | Polymorphic (usually journal) |
| `group_memberships.group_id` | →         | `groups`                      |
| `group_memberships.user_id`  | →         | `users`                       |
| `group_settings.group_id`    | →         | `groups`                      |

### 3.21 Announcements

| Table                                    | FK Column | Refers To                     |
| ---------------------------------------- | --------- | ----------------------------- |
| `announcements.assoc_type/assoc_id`      | →         | Polymorphic (usually journal) |
| `announcements.type_id`                  | →         | `announcement_types`          |
| `announcement_settings.announcement_id`  | →         | `announcements`               |
| `announcement_types.assoc_type/assoc_id` | →         | Polymorphic (usually journal) |
| `announcement_type_settings.type_id`     | →         | `announcement_types`          |

### 3.22 Reading Tools (RT)

| Table                    | FK Column | Refers To     |
| ------------------------ | --------- | ------------- |
| `rt_versions.journal_id` | →         | `journals`    |
| `rt_contexts.version_id` | →         | `rt_versions` |
| `rt_searches.context_id` | →         | `rt_contexts` |

### 3.23 Review Objects (Plugin: Objects for Review)

| Table                                                  | FK Column | Refers To                |
| ------------------------------------------------------ | --------- | ------------------------ |
| `review_object_types.context_id`                       | →         | `journals`               |
| `review_object_type_settings.type_id`                  | →         | `review_object_types`    |
| `review_object_metadata.review_object_type_id`         | →         | `review_object_types`    |
| `review_object_metadata_settings.metadata_id`          | →         | `review_object_metadata` |
| `objects_for_review.review_object_type_id`             | →         | `review_object_types`    |
| `objects_for_review.context_id`                        | →         | `journals`               |
| `objects_for_review.editor_id`                         | →         | `users`                  |
| `object_for_review_settings.object_id`                 | →         | `objects_for_review`     |
| `object_for_review_settings.review_object_metadata_id` | →         | `review_object_metadata` |
| `object_for_review_persons.object_id`                  | →         | `objects_for_review`     |
| `object_for_review_assignments.object_id`              | →         | `objects_for_review`     |
| `object_for_review_assignments.user_id`                | →         | `users`                  |
| `object_for_review_assignments.submission_id`          | →         | `submissions`            |

### 3.24 Books for Review (Plugin)

| Table                               | FK Column | Refers To          |
| ----------------------------------- | --------- | ------------------ |
| `books_for_review.journal_id`       | →         | `journals`         |
| `books_for_review.user_id`          | →         | `users` (reviewer) |
| `books_for_review.editor_id`        | →         | `users` (editor)   |
| `books_for_review.submission_id`    | →         | `submissions`      |
| `books_for_review_authors.book_id`  | →         | `books_for_review` |
| `books_for_review_settings.book_id` | →         | `books_for_review` |

### 3.25 PLN (Preservation Network) Deposits

| Table                            | FK Column | Refers To                |
| -------------------------------- | --------- | ------------------------ |
| `pln_deposits.journal_id`        | →         | `journals`               |
| `pln_deposit_objects.journal_id` | →         | `journals`               |
| `pln_deposit_objects.deposit_id` | →         | `pln_deposits`           |
| `pln_deposit_objects.object_id`  | →         | Depends on `object_type` |

### 3.26 Dataverse Integration

| Table                             | FK Column | Refers To                        |
| --------------------------------- | --------- | -------------------------------- |
| `dataverse_studies.submission_id` | →         | `submissions`                    |
| `dataverse_files.submission_id`   | →         | `submissions`                    |
| `dataverse_files.study_id`        | →         | `dataverse_studies`              |
| `dataverse_files.supp_id`         | →         | `submission_supplementary_files` |

### 3.27 Metrics & Usage Stats

| Table                                               | FK Column | Refers To                       |
| --------------------------------------------------- | --------- | ------------------------------- |
| `metrics.context_id`                                | →         | `journals`                      |
| `metrics.submission_id`                             | →         | `submissions`                   |
| `metrics.assoc_type/assoc_id`                       | →         | Polymorphic                     |
| `metrics.pkp_section_id`                            | →         | `sections`                      |
| `metrics.representation_id`                         | →         | `publication_galleys.galley_id` |
| `usage_stats_temporary_records.assoc_type/assoc_id` | →         | Polymorphic                     |

---

## 4. Settings Pattern (EAV)

OJS uses the **Entity-Attribute-Value (EAV)** pattern extensively. For almost every main table `X`, there is a corresponding `X_settings` table:

```
X_settings (
    X_id        → X.primary_key
    locale      VARCHAR(14)        -- language code (e.g., 'en_US', 'id_ID')
    setting_name  VARCHAR(255)     -- attribute name
    setting_value TEXT             -- attribute value
    setting_type  VARCHAR(6)      -- data type hint
)
```

**All settings tables and their parent:**

| Settings Table                             | Parent FK                            | Parent Table                       |
| ------------------------------------------ | ------------------------------------ | ---------------------------------- |
| `journal_settings`                         | `journal_id`                         | `journals`                         |
| `issue_settings`                           | `issue_id`                           | `issues`                           |
| `section_settings`                         | `section_id`                         | `sections`                         |
| `submission_settings`                      | `submission_id`                      | `submissions`                      |
| `publication_settings`                     | `publication_id`                     | `publications`                     |
| `publication_galley_settings`              | `galley_id`                          | `publication_galleys`              |
| `issue_galley_settings`                    | `galley_id`                          | `issue_galleys`                    |
| `author_settings`                          | `author_id`                          | `authors`                          |
| `citation_settings`                        | `citation_id`                        | `citations`                        |
| `user_settings`                            | `user_id`                            | `users`                            |
| `user_group_settings`                      | `user_group_id`                      | `user_groups`                      |
| `announcement_settings`                    | `announcement_id`                    | `announcements`                    |
| `announcement_type_settings`               | `type_id`                            | `announcement_types`               |
| `category_settings`                        | `category_id`                        | `categories`                       |
| `genre_settings`                           | `genre_id`                           | `genres`                           |
| `plugin_settings`                          | `plugin_name` + `context_id`         | Plugin per journal                 |
| `filter_settings`                          | `filter_id`                          | `filters`                          |
| `email_templates_settings`                 | `email_id`                           | `email_templates`                  |
| `event_log_settings`                       | `log_id`                             | `event_log`                        |
| `notification_settings`                    | `notification_id`                    | `notifications`                    |
| `notification_subscription_settings`       | `user_id`                            | Per user                           |
| `navigation_menu_item_settings`            | `navigation_menu_item_id`            | `navigation_menu_items`            |
| `navigation_menu_item_assignment_settings` | `navigation_menu_item_assignment_id` | `navigation_menu_item_assignments` |
| `submission_file_settings`                 | `file_id`                            | `submission_files`                 |
| `library_file_settings`                    | `file_id`                            | `library_files`                    |
| `static_page_settings`                     | `static_page_id`                     | `static_pages`                     |
| `controlled_vocab_entry_settings`          | `controlled_vocab_entry_id`          | `controlled_vocab_entries`         |
| `group_settings`                           | `group_id`                           | `groups`                           |
| `referral_settings`                        | `referral_id`                        | `referrals`                        |
| `subscription_type_settings`               | `type_id`                            | `subscription_types`               |
| `review_form_settings`                     | `review_form_id`                     | `review_forms`                     |
| `review_form_element_settings`             | `review_form_element_id`             | `review_form_elements`             |
| `metadata_description_settings`            | `metadata_description_id`            | `metadata_descriptions`            |
| `data_object_tombstone_settings`           | `tombstone_id`                       | `data_object_tombstones`           |
| `external_feed_settings`                   | `feed_id`                            | `external_feeds`                   |
| `books_for_review_settings`                | `book_id`                            | `books_for_review`                 |
| `object_for_review_settings`               | `object_id`                          | `objects_for_review`               |
| `review_object_metadata_settings`          | `metadata_id`                        | `review_object_metadata`           |
| `review_object_type_settings`              | `type_id`                            | `review_object_types`              |

---

## 5. Polymorphic Associations

OJS uses **polymorphic associations** (`assoc_type` + `assoc_id`) extensively. The `assoc_type` is a numeric constant that identifies the **type of entity**, and `assoc_id` is the ID within that entity table.

### Common `assoc_type` Constants (from OJS source code):

| Constant                                          | Value (hex) | Value (decimal) | Entity                          |
| ------------------------------------------------- | ----------- | --------------- | ------------------------------- |
| `ASSOC_TYPE_JOURNAL`                              | `0x0000100` | 256             | `journals.journal_id`           |
| `ASSOC_TYPE_SUBMISSION`                           | `0x0100009` | 1048585         | `submissions.submission_id`     |
| `ASSOC_TYPE_ISSUE`                                | `0x0000103` | 259             | `issues.issue_id`               |
| `ASSOC_TYPE_ISSUE_GALLEY`                         | `0x0000105` | 261             | `issue_galleys.galley_id`       |
| `ASSOC_TYPE_GALLEY` / `ASSOC_TYPE_REPRESENTATION` | `0x0100004` | 1048580         | `publication_galleys.galley_id` |
| `ASSOC_TYPE_SUBMISSION_FILE`                      | `0x0200003` | 2097155         | `submission_files.file_id`      |
| `ASSOC_TYPE_USER`                                 | `0x0001000` | 4096            | `users.user_id`                 |
| `ASSOC_TYPE_SECTION`                              | `0x0000104` | 260             | `sections.section_id`           |
| `ASSOC_TYPE_REVIEW_ASSIGNMENT`                    | `0x0200005` | 2097157         | `review_assignments.review_id`  |
| `ASSOC_TYPE_REVIEW_ROUND`                         | `0x0200006` | 2097158         | `review_rounds.review_round_id` |
| `ASSOC_TYPE_QUERY`                                | `0x020000a` | 2097162         | `queries.query_id`              |
| `ASSOC_TYPE_NOTE`                                 | `0x0100013` | 1048595         | `notes.note_id`                 |

### Tables Using Polymorphic Associations:

| Table                                   | Columns                                | Common assoc_type targets                 |
| --------------------------------------- | -------------------------------------- | ----------------------------------------- |
| `email_log`                             | `assoc_type`, `assoc_id`               | Submissions                               |
| `event_log`                             | `assoc_type`, `assoc_id`               | Submissions                               |
| `notes`                                 | `assoc_type`, `assoc_id`               | Queries                                   |
| `notifications`                         | `assoc_type`, `assoc_id`               | Submissions, Issues                       |
| `queries`                               | `assoc_type`, `assoc_id`               | Submissions                               |
| `item_views`                            | `assoc_type`, `assoc_id`               | Galleys, Issues                           |
| `controlled_vocabs`                     | `assoc_type`, `assoc_id`               | Submissions (keywords), Users (interests) |
| `announcements`                         | `assoc_type`, `assoc_id`               | Journals                                  |
| `announcement_types`                    | `assoc_type`, `assoc_id`               | Journals                                  |
| `groups`                                | `assoc_type`, `assoc_id`               | Journals                                  |
| `review_forms`                          | `assoc_type`, `assoc_id`               | Journals                                  |
| `metadata_descriptions`                 | `assoc_type`, `assoc_id`               | Various                                   |
| `metrics`                               | `assoc_type`, `assoc_id`               | Submissions, Galleys, Issues              |
| `metrics`                               | `assoc_object_type`, `assoc_object_id` | Secondary polymorphic                     |
| `data_object_tombstone_oai_set_objects` | `assoc_type`, `assoc_id`               | Various                                   |
| `usage_stats_temporary_records`         | `assoc_type`, `assoc_id`               | Various                                   |
| `access_keys`                           | `context` + `assoc_id`                 | Various                                   |
| `user_settings`                         | `assoc_type`, `assoc_id`               | Various                                   |
| `submission_comments`                   | `assoc_id`                             | Various (review round)                    |
| `submission_files`                      | `assoc_type`, `assoc_id`               | Various                                   |

---

## 6. Full Table Reference

### Standalone / Configuration Tables (no parent FK)

| Table                          | Description                       |
| ------------------------------ | --------------------------------- |
| `site`                         | Global site settings (single row) |
| `site_settings`                | Global site settings (EAV)        |
| `scheduled_tasks`              | Cron-like scheduled tasks         |
| `versions`                     | Installed software versions       |
| `processes`                    | Running background processes      |
| `oai_resumption_tokens`        | OAI-PMH harvesting tokens         |
| `mutex`                        | Database-level mutex              |
| `auth_sources`                 | Authentication plugins            |
| `notification_mail_list`       | Email notification subscribers    |
| `email_templates_default`      | Default email templates           |
| `email_templates_default_data` | Default email template content    |
| `paypal_transactions`          | PayPal transaction records        |

### Many-to-Many Junction Tables

| Table                               | Links                                     | Via Columns                            |
| ----------------------------------- | ----------------------------------------- | -------------------------------------- |
| `user_user_groups`                  | `users` ↔ `user_groups`                   | `user_id`, `user_group_id`             |
| `user_interests`                    | `users` ↔ `controlled_vocab_entries`      | `user_id`, `controlled_vocab_entry_id` |
| `roles`                             | `users` ↔ `journals` (with role)          | `user_id`, `journal_id`, `role_id`     |
| `group_memberships`                 | `users` ↔ `groups`                        | `user_id`, `group_id`                  |
| `query_participants`                | `queries` ↔ `users`                       | `query_id`, `user_id`                  |
| `email_log_users`                   | `email_log` ↔ `users`                     | `email_log_id`, `user_id`              |
| `review_files`                      | `review_assignments` ↔ `submission_files` | `review_id`, `file_id`                 |
| `review_round_files`                | `review_rounds` ↔ `submission_files`      | `review_round_id`, `file_id`           |
| `publication_categories`            | `publications` ↔ `categories`             | `publication_id`, `category_id`        |
| `custom_section_orders`             | `issues` ↔ `sections`                     | `issue_id`, `section_id`               |
| `submission_search_object_keywords` | `search_objects` ↔ `keyword_list`         | `object_id`, `keyword_id`              |

---

## Quick Reference: "How do I find...?"

| Question                      | Query Path                                                                                                                                                 |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Title of a submission**     | `submissions` → `publications` → `publication_settings` WHERE `setting_name = 'title'`                                                                     |
| **Authors of a submission**   | `submissions` → `publications` → `authors` → `author_settings`                                                                                             |
| **Files of a submission**     | `submissions` → `submission_files` → `submission_file_settings`                                                                                            |
| **Reviewers of a submission** | `submissions` → `review_assignments` → `users` (via `reviewer_id`)                                                                                         |
| **Issue a paper is in**       | `publications` → `publication_settings` WHERE `setting_name = 'issueId'` → `issues`                                                                        |
| **PDF/galley of a paper**     | `publications` → `publication_galleys` → `submission_files` (via `file_id`)                                                                                |
| **Keywords of a submission**  | `controlled_vocabs` WHERE `symbolic = 'submissionKeyword'` AND `assoc_id = submission_id` → `controlled_vocab_entries` → `controlled_vocab_entry_settings` |
| **User's role in journal**    | `users` → `user_user_groups` → `user_groups` (check `role_id`)                                                                                             |
| **Editor decisions**          | `submissions` → `edit_decisions` → `users` (via `editor_id`)                                                                                               |
| **Review rounds**             | `submissions` → `review_rounds` → `review_assignments`                                                                                                     |
| **Discussion threads**        | `queries` WHERE `assoc_id = submission_id` → `query_participants`, `notes` WHERE `assoc_id = query_id`                                                     |
| **Email history**             | `email_log` WHERE `assoc_id = submission_id` → `email_log_users`                                                                                           |
| **Event audit trail**         | `event_log` WHERE `assoc_id = submission_id` → `event_log_settings`                                                                                        |

==============================================

Sure! Let me explain the OJS concepts using a real-world flow example that's easy to follow.

---

## 🎓 OJS (Open Journal System) — Explained with a Story

Imagine you're running an **academic journal** called _"Jurnal Elektro Indonesia"_. Researchers send their papers to your journal, reviewers check the papers, editors decide to accept/reject, and finally the papers get published in an issue. OJS manages this entire process.

---

### The Flow: From Paper Submission to Publication

```
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 0: SETUP                                                      │
│                                                                      │
│  👤 Admin creates a JOURNAL called "Jurnal Elektro Indonesia"        │
│     └─ journals table (journal_id = 1)                               │
│     └─ journal_settings: name, description, logo, etc.               │
│                                                                      │
│  👤 Admin creates SECTIONS inside the journal:                       │
│     ├─ "Articles"    (section_id = 1)                                │
│     └─ "Book Reviews" (section_id = 2)                               │
│                                                                      │
│  👤 Admin creates ISSUES (like magazine editions):                   │
│     ├─ Vol 1, No 1, 2025  (issue_id = 1)                            │
│     └─ Vol 1, No 2, 2025  (issue_id = 2) ← still empty, upcoming   │
│                                                                      │
│  👤 Admin registers USERS with different roles (USER_GROUPS):        │
│     ├─ Dr. Budi    → role: "Editor"    (user_id = 1)                │
│     ├─ Prof. Siti  → role: "Reviewer"  (user_id = 2)                │
│     ├─ Dr. Rina    → role: "Reviewer"  (user_id = 3)                │
│     └─ Andi        → role: "Author"    (user_id = 4)                │
│                                                                      │
│     Roles stored in: users + user_user_groups + user_groups          │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: AUTHOR SUBMITS A PAPER                                     │
│                                                                      │
│  👤 Andi (Author) logs into OJS and submits his paper:               │
│     "Analisis Efisiensi Motor Listrik Brushless DC"                  │
│                                                                      │
│  What happens in the database:                                       │
│                                                                      │
│  📄 submissions (submission_id = 10)                                 │
│     ├─ context_id = 1  (→ journals, which journal?)                  │
│     ├─ section_id = 1  (→ sections, "Articles")                      │
│     ├─ status = 1      (= "Queued/New")                              │
│     ├─ stage_id = 1    (= "Submission" stage)                        │
│     └─ current_publication_id = 20                                   │
│                                                                      │
│  📄 publications (publication_id = 20)                               │
│     └─ submission_id = 10                                            │
│                                                                      │
│  📄 publication_settings (the paper's title, abstract, etc.)         │
│     ├─ (publication_id=20, setting_name='title',                     │
│     │   locale='id_ID', setting_value='Analisis Efisiensi...')       │
│     ├─ (publication_id=20, setting_name='abstract',                  │
│     │   locale='id_ID', setting_value='Penelitian ini...')           │
│     └─ (publication_id=20, setting_name='issueId',                   │
│         setting_value=NULL) ← not assigned to issue yet              │
│                                                                      │
│  👤 authors (author_id = 30)                                         │
│     ├─ publication_id = 20                                           │
│     ├─ submission_id = 10                                            │
│     └─ user_group_id = 14  (→ user_groups "Author")                 │
│                                                                      │
│  📄 author_settings                                                  │
│     ├─ (author_id=30, setting_name='familyName',                     │
│     │   setting_value='Wijaya')                                      │
│     └─ (author_id=30, setting_name='givenName',                      │
│         setting_value='Andi')                                        │
│                                                                      │
│  📎 submission_files (file_id = 100, revision = 1)                   │
│     ├─ submission_id = 10                                            │
│     ├─ file_stage = 2   (= "Submission files")                       │
│     ├─ genre_id = 1     (→ genres "Article Text")                    │
│     ├─ original_file_name = 'paper_motor_bldc.pdf'                   │
│     └─ uploader_user_id = 4  (Andi)                                 │
│                                                                      │
│  🔖 controlled_vocabs + controlled_vocab_entries (keywords)          │
│     └─ "motor brushless DC", "efisiensi energi"                      │
│                                                                      │
│  📋 stage_assignments (who is involved at this stage)                │
│     └─ (submission_id=10, user_id=4, user_group_id=14)              │
│         Andi is assigned as Author to this submission                 │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 2: EDITOR ASSIGNS REVIEWERS                                   │
│                                                                      │
│  👤 Dr. Budi (Editor) sees the new submission and:                   │
│     1. Moves it to "Review" stage (stage_id changes to 3)           │
│     2. Creates a Review Round                                        │
│     3. Assigns two reviewers                                         │
│                                                                      │
│  📋 stage_assignments (editor added to workflow)                     │
│     └─ (submission_id=10, user_id=1, user_group_id=3)               │
│         Dr. Budi assigned as Editor                                  │
│                                                                      │
│  🔄 review_rounds (review_round_id = 5)                             │
│     ├─ submission_id = 10                                            │
│     ├─ stage_id = 3      (= "External Review")                      │
│     ├─ round = 1         (first round of review)                     │
│     └─ status = 6        (= "Pending Reviews")                       │
│                                                                      │
│  📎 review_round_files (which files reviewers can see)               │
│     └─ (submission_id=10, review_round_id=5, file_id=100)           │
│                                                                      │
│  👤 review_assignments (review_id = 40)                              │
│     ├─ submission_id = 10                                            │
│     ├─ reviewer_id = 2   (→ users, Prof. Siti)                      │
│     ├─ review_round_id = 5                                           │
│     ├─ review_method = 2 (= "Double Blind")                         │
│     ├─ date_assigned = 2025-01-15                                    │
│     └─ date_due = 2025-02-15                                        │
│                                                                      │
│  👤 review_assignments (review_id = 41)                              │
│     ├─ submission_id = 10                                            │
│     ├─ reviewer_id = 3   (→ users, Dr. Rina)                        │
│     ├─ review_round_id = 5                                           │
│     └─ date_due = 2025-02-15                                        │
│                                                                      │
│  📧 email_log (notification emails sent)                             │
│     └─ (assoc_type=1048585, assoc_id=10, sender_id=1,               │
│         subject='Review Request')                                    │
│                                                                      │
│  📧 email_log_users (who received the email)                         │
│     ├─ (email_log_id=..., user_id=2)  Prof. Siti                    │
│     └─ (email_log_id=..., user_id=3)  Dr. Rina                      │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 3: REVIEWERS SUBMIT REVIEWS                                   │
│                                                                      │
│  👤 Prof. Siti opens her review assignment:                          │
│     - Reads the paper (review_files links her to the PDF)            │
│     - Fills out review form                                          │
│     - Gives recommendation: "Accept with Revisions"                  │
│                                                                      │
│  📋 review_assignments (review_id = 40) updated:                     │
│     ├─ recommendation = 6  (= "Revisions Required")                 │
│     ├─ date_completed = 2025-02-01                                   │
│     └─ review_form_id = 1  (→ review_forms)                         │
│                                                                      │
│  📝 review_form_responses (reviewer's answers)                       │
│     ├─ (review_form_element_id=1, review_id=40,                      │
│     │   response_value='Methodology is solid but...')                │
│     └─ (review_form_element_id=2, review_id=40,                      │
│         response_value='4')  ← rating score                         │
│                                                                      │
│  📝 submission_comments (reviewer comments to editor/author)         │
│     └─ (submission_id=10, author_id=2, role_id=4096,                 │
│         comments='Please revise section 3...')                       │
│                                                                      │
│  📋 event_log (audit trail)                                          │
│     └─ (assoc_type=1048585, assoc_id=10, user_id=2,                 │
│         message='Reviewer submitted review')                         │
│                                                                      │
│  👤 Dr. Rina also submits: recommendation = 2 ("Accept")            │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 4: EDITOR MAKES A DECISION                                    │
│                                                                      │
│  👤 Dr. Budi reviews both reviews and decides:                       │
│     "Accept with Revisions Required"                                 │
│                                                                      │
│  📋 edit_decisions (edit_decision_id = 60)                           │
│     ├─ submission_id = 10                                            │
│     ├─ editor_id = 1     (Dr. Budi)                                 │
│     ├─ decision = 6      (= "Revisions Required")                   │
│     ├─ review_round_id = 5                                           │
│     └─ stage_id = 3                                                  │
│                                                                      │
│  📧 email_log → notification sent to Andi (the author)              │
│  🔔 notifications → Andi gets a notification in OJS                  │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 5: AUTHOR REVISES & RESUBMITS                                 │
│                                                                      │
│  👤 Andi uploads a revised version of his paper                      │
│                                                                      │
│  📎 submission_files (file_id = 100, revision = 2)  ← new revision! │
│     ├─ source_file_id = 100                                          │
│     ├─ source_revision = 1                                           │
│     └─ original_file_name = 'paper_motor_bldc_revised.pdf'           │
│                                                                      │
│  The editor may start Review Round 2, or accept directly.            │
│  Let's say editor accepts this time:                                 │
│                                                                      │
│  📋 edit_decisions (new decision)                                    │
│     └─ decision = 2  (= "Accept")                                   │
│                                                                      │
│  Stage moves to: stage_id = 5 ("Production")                        │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 6: PRODUCTION & GALLEY CREATION                                │
│                                                                      │
│  👤 Editor/Production Manager creates the final PDF (galley)         │
│                                                                      │
│  📎 submission_files (file_id = 200, revision = 1)                   │
│     ├─ file_stage = 10   (= "Production ready")                     │
│     └─ original_file_name = 'final_formatted.pdf'                    │
│                                                                      │
│  📄 publication_galleys (galley_id = 70)                             │
│     ├─ publication_id = 20                                           │
│     ├─ file_id = 200     (→ submission_files)                        │
│     ├─ label = 'PDF'                                                 │
│     └─ locale = 'id_ID'                                              │
│                                                                      │
│  📄 publication_galley_settings                                      │
│     └─ (galley_id=70, setting_name='pub-id::doi',                    │
│         setting_value='10.12345/example.2025.001')                   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 7: ASSIGN TO ISSUE & PUBLISH                                  │
│                                                                      │
│  👤 Editor assigns the paper to Issue "Vol 1, No 2, 2025"           │
│                                                                      │
│  📄 publication_settings updated:                                    │
│     └─ (publication_id=20, setting_name='issueId',                   │
│         setting_value='2')  ← now linked to issue_id = 2!           │
│                                                                      │
│  📄 publications updated:                                            │
│     ├─ status = 3         (= "Published")                            │
│     └─ date_published = 2025-06-01                                   │
│                                                                      │
│  📄 submissions updated:                                             │
│     └─ status = 3         (= "Published")                            │
│                                                                      │
│  📊 metrics (usage tracking starts)                                  │
│     └─ (context_id=1, submission_id=10, assoc_type=1048585,          │
│         metric_type='ojs::counter', metric=0)                        │
│                                                                      │
│  🎉 The paper is now live on the journal website!                    │
│     Readers can view/download the PDF galley.                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 📖 Glossary — What Each Term Means

| OJS Term              | Real-World Analogy                                                                                         | Database Table        |
| --------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------- |
| **Journal**           | The magazine/journal itself (e.g., "Jurnal Elektro Indonesia")                                             | `journals`            |
| **Issue**             | One edition of the magazine (e.g., "Vol 1, No 2, June 2025")                                               | `issues`              |
| **Section**           | Category within an issue (e.g., "Research Articles", "Book Reviews")                                       | `sections`            |
| **Submission**        | A paper/manuscript sent by an author for review                                                            | `submissions`         |
| **Publication**       | A versioned "snapshot" of a submission (title, abstract, authors). A submission can have multiple versions | `publications`        |
| **Author**            | Person who wrote the paper (linked to publication)                                                         | `authors`             |
| **Galley**            | The final formatted file (PDF, HTML, EPUB) readers download                                                | `publication_galleys` |
| **Review Round**      | One cycle of peer review (Round 1, Round 2, etc.)                                                          | `review_rounds`       |
| **Review Assignment** | A reviewer assigned to review a paper                                                                      | `review_assignments`  |
| **Edit Decision**     | Editor's verdict: Accept / Reject / Revisions Required                                                     | `edit_decisions`      |
| **Stage**             | Workflow step: 1=Submission, 3=Review, 4=Copyediting, 5=Production                                         | `stage_id` column     |
| **User Group**        | Role template: "Journal Editor", "Reviewer", "Author"                                                      | `user_groups`         |
| **Stage Assignment**  | Who is participating in which workflow stage for a submission                                              | `stage_assignments`   |
| **Controlled Vocab**  | Keywords, subjects, disciplines attached to papers                                                         | `controlled_vocabs`   |
| **Metrics**           | Download/view counts for published articles                                                                | `metrics`             |
| **Query**             | Internal discussion thread between editor/reviewer/author                                                  | `queries`             |
| **Note**              | A message within a query/discussion                                                                        | `notes`               |

---

### 🔑 The Key Insight: Why Settings Tables Exist

You might wonder: _"Why isn't the paper title just a column on `submissions`?"_

Because OJS supports **multiple languages**! A paper can have:

- Title in Indonesian: _"Analisis Efisiensi Motor Listrik Brushless DC"_
- Title in English: _"Efficiency Analysis of Brushless DC Electric Motors"_

Both are stored as separate rows in `publication_settings` with different `locale` values (`id_ID` vs `en_US`). That's why OJS uses the EAV (Entity-Attribute-Value) pattern — every translatable field is a row, not a column.

==============================================

No! That's a great question. **1 submission can have MULTIPLE publications**.

Think of it like this:

---

## 📝 Submission vs. Publication

### **Submission** = The Journey

- The **single paper** submitted by Andi once
- Tracks the **workflow** (submitted → under review → accepted → published)
- `submissions` table (one row per paper, stays the same)

### **Publication** = The Snapshot

- A **versioned state** of that paper
- Created when there's a significant change to the paper's metadata
- `publications` table (can have multiple rows for one submission)

---

## 📚 Real-World Example

Let's say Andi submits his paper "Motor Analysis":

```
submissions (submission_id = 10)
├─ Status: Published
├─ current_publication_id = 22  ← points to LATEST version
└─ section_id = 1 (Articles)

publications
├─ (publication_id = 20)  ← v1: Initial submission
│  └─ submission_id = 10
│  └─ publication_settings: title = "Motor Analysis"
│
├─ (publication_id = 21)  ← v2: After 1st revision
│  └─ submission_id = 10  ← SAME submission!
│  └─ publication_settings: title = "Efficiency Analysis of Motor Control Systems"
│                          (author names updated, abstract changed)
│
└─ (publication_id = 22)  ← v3: Final published version
   └─ submission_id = 10  ← SAME submission!
   └─ publication_settings: title = "Efficiency Analysis of Brushless DC Motor Control Systems"
                           (DOI added, issue assigned)
```

---

## 🔄 When Does a New Publication Get Created?

1. **Author revises & resubmits** → new `publication` row (new version)
2. **Title/authors change during editing** → new `publication` row
3. **Abstract gets updated** → new `publication` row
4. **Assigned to a different issue** → might create new `publication` row
5. **Published** → final `publication` with `date_published` set

Each version has its own:

- `publication_settings` (title, abstract in different locales)
- `publication_galleys` (PDF, HTML files for that version)
- `authors` (author list at that point in time)
- `citations` (references at that version)

---

## 🎯 Key Relationship

```sql
submissions.current_publication_id → publications.publication_id
                                    (points to the LATEST version)
```

So when you want to show the paper on the website, you:

1. Get the `submission` record
2. Follow `current_publication_id` to get the **latest** `publication`
3. From `publication`, get the title, authors, abstract (from `publication_settings`)
4. From `publication`, get the PDF/HTML files (from `publication_galleys`)

---

## 💡 Why Multiple Publications?

Because OJS needs to **preserve the history** of what was submitted, reviewed, and published at each stage. If the author revised the title during the revision process, you want to know:

- What the title was when first submitted (v1)
- What it changed to after revision (v2)
- What the final published title is (v3)

This is important for academic integrity and traceability!
