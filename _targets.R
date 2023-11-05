library(targets)
library(tarchetypes)

tar_option_set(packages = "sjx")

read_data <- function(data_name, package_name) {
  temp <- new.env(parent = emptyenv())
  
  data(list = data_name,
       package = package_name,
       envir = temp)
  
  get(data_name,
      envir = temp)
}

list(
  tar_target(inventories,
             read_data("inventories",
                       "sjx")),
  tar_target(sales,
             read_data("sales",
                       "sjx")),
  tar_render(analyse,
             "sa_method_comparison.Rmd",
             output_dir = "/home/sjx/pipeline_output")
)