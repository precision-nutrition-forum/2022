
library(tidyverse)
library(here)
library(fs)
library(magick)

dir_ls(here("images/raw"), glob = "*.png") %>%
    file_copy(here("images"))

old_jpg_images <- dir_ls(here("images/raw"), glob = "*.jpg")
new_png_images <- here("images", path_ext_set(path_file(jpg_images), "png"))

convert_to_png <- function(old_file, new_file) {
    old_file %>%
        image_read() %>%
        image_write(path = new_file, format = "png")
}

walk2(
    old_jpg_images,
    new_png_images,
    convert_to_png
)