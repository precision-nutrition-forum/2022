
library(textreadr)
library(readxl)
library(tidyverse)
library(here)
library(fs)

# Processing files from the PNF.zip archive. This is not saved in the Git repo.
zip::unzip(here("data-raw/PNF.zip"), exdir = here("data-raw"))

# Proces and move images --------------------------------------------------

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
    unique()

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

dir_create(here("data"))

read_csv(here("data-raw/presentations.csv"), col_types = rep("c", 14), guess_max = 0) %>%
    bind_rows(nonspeaker_sessions) %>%
    select(session, date, start_time, end_time, full_name, title) %>%
    arrange(date, lubridate::hm(start_time)) %>%
    mutate(across(everything(), ~if_else(is.na(.), "", .))) %>%
    write_csv(here("data/schedule.csv"))

