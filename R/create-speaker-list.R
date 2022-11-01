
library(tidyverse)
library(here)
library(glue)
library(yaml)
library(whisker)
library(fs)

# To overwrite with later code.
dir_ls(here("talks")) %>%
    file_delete()

# Function to create files from a template --------------------------------

# Create a markdown file of each poster abstract
create_collection_from_template <- function(data) {
    text <- whisker.render(
        template = read_lines(here("R/template-talks.md")),
        data = list(
            speaker_id = data$speaker_id,
            title = data$title,
            full_name = data$full_name,
            affiliations = data$affiliations,
            summary_research_interests = data$summary_research_interests,
            video_embedded_html_link = data$video_embedded_html_link
        )
    )

    collection_path <- here(glue("talks/{data$speaker_id}/index.md"))
    dir_create(path_dir(collection_path))
    file_create(collection_path)

    temp_md <- fs::file_temp(ext = ".md")
    write_lines(
        x = text,
        file = collection_path
    )
    return(collection_path)
}

# Give speaker data to function to create the files -----------------------

titles <- read_csv(here("data/program.csv"),
                   col_select = c(title, speaker_id),
                   col_types = "c") %>%
    filter(!is.na(speaker_id))

video_links <- yaml::read_yaml(here("data/videos.yml")) %>%
        map_dfr(as_tibble)

read_csv(here("data/talks.csv"), col_types = "c") %>%
    full_join(titles, by = "speaker_id") %>%
    full_join(video_links, by = "speaker_id") %>%
    transpose() %>%
    walk(create_collection_from_template)
