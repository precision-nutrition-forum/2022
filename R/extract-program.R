
library(textreadr)
library(readxl)
library(tidyverse)
library(here)
library(fs)
library(jsonlite)

# Processing files from the PNF.zip archive. This is not saved in the Git repo.
zip::unzip(here("data-raw/PNF.zip"), exdir = here("data-raw"))

# Process and move images -------------------------------------------------

profile_pics <- dir_ls(here("data-raw"), regexp = ".*\\.(png|jpe?g|jfif)")

# Have to first rename some of their characters.
renamed_pics <- profile_pics %>%
    path_file() %>%
    str_to_lower() %>%
    str_replace_all(" +", "-")

file_move(
    profile_pics,
    path(here("images", "raw", renamed_pics))
)
# Rename after moving them.


# Extract scope and program -----------------------------------------------

# Paste into the index.qmd and about.qmd files
read_docx(here("data-raw/Scope.docx")) %>%
    clipr::write_clip()

file_delete(here("data-raw/Scope.docx"))

# Extract and tidy schedule -----------------------------------------------

# Need to do some minor manual cleaning, like deleting columns
read_excel(here("data-raw/talks-titles-schedule.xlsx")) %>%
    write_csv(here("data-raw/presentations.csv"))

presentations <- read_csv(here("data-raw/presentations.csv"))

# Use this to form a starting point to fix the column names
# Copy and paste below this
presentations %>%
    names() %>%
    as_tibble() %>%
    glue::glue_data('"{snakecase::to_snake_case(value)}", "{value}",') %>%
    prepend(c("tibble::tribble(", "~new_name,", "~old_name,")) %>%
    append(")") %>%
    clipr::write_clip()

# Pasted from above.
column_renaming <- tibble::tribble(
    ~new_name, ~old_name,
    "session", "Session",
    "date", "date",
    "time", "time",
    "full_name", "Full name (as it should appear in the program)",
    "title", "Title of my presentation",
    "agree_to_publish_talk_and_info", "I agree that the provided title of my talk and personal information are disseminated publicly to advertise the THE FIRST GOTHENBURG PRECISION NUTRITION FORUM.",
    "summary_research_interests", "Short summary of my major research interests  for the public program (just a few sentences).",
    "agree_to_photo_in_program", "Do you agree that a portrait photo is included with your scientific interests summary in the program?",
    "agree_to_livestream_talk", "Given the speaker consent, we want to livestream the scientific presentations. Do you agree that your scientific presentation in the THE FIRST GOTHENBURG PRECISION NUTRITION FORUM is livestreamed on the internet?",
    "agree_to_cc_license_talk", "In the spirit of open science, we want to record and publish the scientific presentation and make them publicly accessible under the creative commons Attribution-NonCommercial-ShareAlike CC (BY-NC-SA) license . This license lets others remix, adapt, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms. In other words, you allow us to upload the video of your presentation to the conference website and make it findable, accessible, and citable. Do yo agree?",
    "primary_affiliation", "Primary affiliation",
    "secondary_affiliation", "Secondary affiliation",
    "tertiary_affiliation", "Tertiary affiliation",
)

presentations %>%
    rename(deframe(column_renaming)) %>%
    mutate(across(where(is.character), str_remove_all, pattern = "\n")) %>%
    mutate(
        date = lubridate::ymd(date),
        full_name = full_name %>%
            str_remove_all("Prof\\.|, MD, MPH|Dr\\.| Ph\\.[Dd]\\.") %>%
            str_to_title() %>%
            str_trim()
    ) %>%
    separate(time, into = c("start_time", "end_time"), sep = "-") %>%
    write_csv(here("data-raw/presentations.csv"))
# Manually edit after this.

# Select who hasn't explicitly consented.
read_csv(here("data-raw/presentations.csv"), show_col_types = FALSE) %>%
    select(full_name, starts_with("agree")) %>%
    pivot_longer(cols = -full_name) %>%
    filter(is.na(value)) %>%
    pull(full_name) %>%
    unique() %>%
    cat(sep = ", ")

# Create schedule ---------------------------------------------------------

# To get the breaks and other times.
nonspeaker_sessions <- read_docx(here("data-raw/program.docx")) %>%
    str_subset("[Bb]reak|Poster|Lunch") %>%
    str_split(" ", n = 2) %>%
    map_dfr(~as_tibble(matrix(.x, ncol = 2),
                       .name_repair = ~c("time", "session"))) %>%
    separate(time, into = c("start_time", "end_time"), sep = "-") %>%
    mutate(date = paste0("2022-09-", rep(c("12", "13"), each = 2))) %>%
    add_row(session = "Closing remarks", date = "2022-09-13", start_time = "17:00", end_time = "")

# file_delete(here("data-raw/program.docx"))
dir_create(here("data"))

read_csv(here("data-raw/presentations.csv"), col_types = "c", guess_max = 0) %>%
    mutate(
        speaker_id = full_name %>%
            str_to_lower() %>%
            str_replace_all(" ", "-") %>%
            str_remove_all("\\.") %>%
            str_replace_all("ä", "a") %>%
            str_replace_all("ö", "o") %>%
            str_replace_all("ë", "e") %>%
            str_replace_all("é", "e")
        ) %>%
    bind_rows(nonspeaker_sessions) %>%
    select(speaker_id, session, date, start_time, end_time, full_name, title) %>%
    arrange(date, lubridate::hm(start_time)) %>%
    mutate(across(everything(), ~if_else(is.na(.), "", .))) %>%
    write_csv(here("data/schedule.csv"))

# Create speakers ---------------------------------------------------------

read_csv(here("data-raw/presentations.csv"), col_types = "c", guess_max = 0) %>%
    select(full_name, summary_research_interests, ends_with("affiliation")) %>%
    mutate(across(everything(), ~if_else(is.na(.), "", .))) %>%
    rowwise(full_name, summary_research_interests) %>%
    summarize(affiliations = str_flatten(c_across(ends_with("affiliation")), "; ") %>%
                  str_remove_all("; (; )+") %>%
                  str_remove("; +?$")) %>%
    left_join(here("data/schedule.csv") %>%
                  read_csv(
                      col_types = "c",
                      col_select = c("speaker_id", "full_name")
                  ),
              by = "full_name") %>%
    relocate(speaker_id, everything()) %>%
    write_csv(here("data/speakers.csv"))

# Create poster presentation list -----------------------------------------

# Had to do some minor manual edits in Institution column.
read_excel(here("data-raw/poster-presenters-titles-abstracts.xlsx"),
           skip = 1) %>%
    rename_with(snakecase::to_snake_case) %>%
    rename_with(~ str_remove(., "submitter_(.*_name_|email_|company_)") %>%
                    str_remove("abstract_")) %>%
    rename(presentation_type = presentation_preference_name,
           affiliation = organisation_institute) %>%
    mutate(affiliation = affiliation %>%
               str_replace("NutritionUniversity of Oslo - ", "Nutrition, University of Oslo; ") %>%
               str_replace("University of technology", "University of Technology") %>%
               str_replace("University of Gothenburg\\|Dep of Surgery", "Department of Surgery, University of Gothenburg")
           ) %>%
    mutate(
        body = body %>%
            str_remove("^<[Pp]>") %>%
            str_remove("<\\|[Pp]>$") %>%
            str_remove_all("<\\|?span>") %>%
            str_remove_all("<\\|?(B|strong)>") %>%
            str_replace_all('<(\\|?[Pp]|br \\||p style=.*\\")>', "\n") %>%
            str_replace_all("<\\|?sup>", "^") %>%
            str_replace_all("\\|", "/") %>%
            str_replace_all("(Background|Introduction|Methods?|Results?|Conclusions?|Keywords?)[.:]?", "\n\n**\\1:**\n\n") %>%
            str_replace_all("<\\|?I>", "*"),
        full_name = str_c(first_name, family_name, sep = " "),
        author_id = full_name %>%
            str_replace_all("ö", "o") %>%
            str_to_lower() %>%
            str_replace_all(" ", "-")
        ) %>%
    select(author_id, full_name, title, body, presentation_type, affiliation) %>%
    # Use JSON because of the abstract body.
    write_json(here("data/poster-presentations.json"),
               pretty = TRUE)

# This is to find people with incomplete or missing abstracts.
read_json(here("data/poster-presentations.json")) %>%
    bind_rows() %>%
    filter(nchar(body) < 1000) %>%
    pull(full_name) %>%
    str_c(collapse = ", ") %>%
    clipr::write_clip()

