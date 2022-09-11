# PNF2022: Website source material

This repository contains the source material for the website for the
Precision Nutrition Forum 2022 conference.

## Installation and building the website

This website is built using [R](https://cran.r-project.org/) and
[Quarto](https://quarto.org/) within
[RStudio](https://www.rstudio.com/). To install the necessary R
packages, open up the `2022.Rproj` file to open the RStudio R Project.
Then, in the R Console, copy and paste the below code and run it.

``` r
# install.packages("remotes")
remotes::install_deps()
```

Quarto is installed by default with RStudio, so you don't need to
install it. While inside the RStudio R Project, open the Terminal and
run this code to add the Quarto Extension to include FontAwesome icons.

``` bash
quarto install extension quarto-ext/fontawesome
```

To build the website, if inside RStudio, use the key bindings
`Ctrl-Shift-B` (for build). Otherwise, you can build the website by
pasting the below code into the Terminal.

``` bash
quarto render
```
