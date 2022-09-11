
library(tidyverse)
library(here)
library(glue)
library(jsonlite)
library(whisker)
library(fs)

# To overwrite with later code.
dir_ls(here("posters")) %>%
    file_delete()

# Create a markdown file of each poster abstract
create_collection_from_template <- function(data) {
    text <- whisker.render(
        template = read_lines(here("data-raw/abstract-index-template.md")),
        data = list(
            title = data$title,
            full_name = data$full_name,
            affiliation = data$affiliation,
            body = data$body,
            presentation_type = data$presentation_type
        )
    )

    collection_path <- here(glue("posters/{data$author_id}/index.md"))
    dir_create(path_dir(collection_path))
    file_create(collection_path)

    temp_md <- fs::file_temp(ext = ".md")
    write_lines(
        x = text,
        file = temp_md
    )

    # Use this to nicely reformat the markdown file.
    rmarkdown::render(
        input = temp_md,
        output_file = collection_path,
        output_format = "rmarkdown::md_document",
        output_options = list(
            preserve_yaml = TRUE
        ),
        quiet = TRUE
    )
    return(collection_path)
}

read_json(here("data/poster-presentations.json")) %>%
    walk(create_collection_from_template)
