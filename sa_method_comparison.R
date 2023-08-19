# Load libraries
library(readxl) # reading in Excel file
library(dplyr) # rename
library(seasonal) # X-13ARIMA-SEATS
library(lubridate) # year
library(janitor) # clean_names
library(ggplot2) # plotting
library(reshape2) # melt

# Define function to download series data and metadata
download_ts <- function(url) {
  
  # Download data
  raw_data <- tempfile(fileext = ".xlsx")
  download.file(url, raw_data, method = "auto", mode = "wb")
  series_data <- read_excel(raw_data, sheet = "Data1", skip = 9) %>%
    rename(period = "Series ID") %>%
    na.omit() # Some series have different start and end dates, so reduce dataset to complete cases across series
  
  # Download metadata
  series_metadata <- read_excel(raw_data, sheet = "Index", skip = 9, col_names = TRUE)
  
  # Remove irrelevant data
  series_metadata <- series_metadata %>%
    filter(grepl("^[A-Z][a-z]+", `Data Item Description`)) %>% # Discard junk (empty and copyright) rows
    select_if(~!all(is.na(.))) %>% # Discard empty columns
    clean_names()
  
  # Create common start and end dates across series
  # (Effectively ignore spreadsheet's original series_start and series_end variables as some series values are suppressed, meaning these variables don't align with what's really in the spreadsheet)
  series_metadata <- series_metadata %>%
    mutate(common_series_start = series_data$period[1],
           common_series_end = series_data$period[nrow(series_data)],
           common_start_year = year(ymd(common_series_start)),
           common_start_period = ifelse(freq == "Month", month(ymd(common_series_start)), quarter(ymd(common_series_start))),
           common_end_year = year(ymd(common_series_end)),
           common_end_period = ifelse(freq == "Month", month(ymd(common_series_end)), quarter(ymd(common_series_end))))
  
  # Create numeric version of frequency variable
  series_metadata <- series_metadata %>%
    mutate(freq_name = freq,
           freq_num = ifelse(freq == "Quarter", 4, 12)) %>%
    within(rm("freq"))
  
  return(list(data = series_data, meta = series_metadata))
}

# Define function to create matching groups of series IDs corresponding to original, seasonally adjusted and trend series
create_ts_groups <- function(meta) {
  
  # Extract series groups
  unique_series_names <- pull(unique(meta["data_item_description"]))
  
  # Initialise vectors to store matching series IDs by index number
  series_ID_orig <- character()
  series_ID_seas <- character()
  series_ID_tren <- character()

  # Cycle through each group of series
  for (name_index in 1:length(unique_series_names)) {
    
    # Filter data to extract current series group
    unique_name <- unique_series_names[name_index]
    data_filtered <- filter(meta, data_item_description == unique_name)

    # Cycle through each series in group
    for (row in 1:nrow(data_filtered)) {
      # Extract series type and populate vectors
      if (data_filtered[row, "series_type"] == "Original") series_ID_orig <- c(series_ID_orig, as.character(data_filtered[row, "series_id"]))
      if (data_filtered[row, "series_type"] == "Seasonally Adjusted") series_ID_seas <- c(series_ID_seas, as.character(data_filtered[row, "series_id"]))
      if (data_filtered[row, "series_type"] == "Trend") series_ID_tren <- c(series_ID_tren, as.character(data_filtered[row, "series_id"]))
    }
    
    # Insert blanks where series are absent in spreadsheet to ensure corresponding vectors of series IDs are aligned
    if (length(series_ID_orig) < name_index) series_ID_orig <- c(series_ID_orig, "")
    if (length(series_ID_seas) < name_index) series_ID_seas <- c(series_ID_seas, "")
    if (length(series_ID_tren) < name_index) series_ID_tren <- c(series_ID_tren, "")
  }
  
  return(list(orig = series_ID_orig, seas = series_ID_seas, tren = series_ID_tren))
}

# Define function to create time series
create_ts <- function(data, meta, name) {
  common_start_year <- filter(meta, series_id == name)$common_start_year
  common_start_month <- filter(meta, series_id == name)$common_start_period
  common_end_year <- filter(meta, series_id == name)$common_end_year
  common_end_month <- filter(meta, series_id == name)$common_end_period
  freq <- filter(meta, series_id == name)$freq_num
  return(ts(data[, name], start = c(common_start_year, common_start_month), end = c(common_end_year, common_end_month), frequency = freq))
}

# Define function to plot time series
plot_ts <- function(data, meta, type, filename) {
  
  # Set up output device
  graphics.off()
  pdf(paste0(filename, ".pdf"), width = 12, onefile = TRUE)

  # Extract groups and series IDs
  series_groups <- create_ts_groups(meta)
  series_ID_orig <- series_groups$orig
  if (type == "S") series_ID_othr <- series_groups$seas
  if (type == "T") series_ID_othr <- series_groups$tren
  
  # Cycle through series
  for (series_index in 1:length(series_ID_orig)) {
    
    # Skip iteration when only the original series are present for a given group but not the SA or T series
    if (series_ID_othr[series_index] == "") next
    
    # Extract relevant series metadata for generating required series and for plotting purposes
    X13_type <- ifelse(type == "S", "seasonaladj", "trend")
    plot_type <- ifelse(type == "S", "Seasonally Adjusted", "Trend")
    series_description <- filter(meta, series_id == series_ID_othr[series_index])$data_item_description
    units <- filter(meta, series_id == series_ID_orig[series_index])$unit
    period_type <- ifelse(meta$freq_name[1] == "Quarter", "quarters", "months")
    period_range <- seq(data$period[1], data$period[nrow(data)], period_type)
    
    # Extract ABS original and seasonally adjusted/trend series
    ABS_orig <- create_ts(data, meta, series_ID_orig[series_index])
    ABS <- create_ts(data, meta, series_ID_othr[series_index])
    
    # Generate X-13ARIMA-SEATS seasonally adjusted/trend series
    X13 <- seas(ABS_orig, x11 = "")$data[, X13_type] # X11 option specifies X-11; overrides the 'seats' spec
    
    # Generate plotting data
    plot_data <- data.frame("ABS" = as.numeric(ABS), "X13" = as.numeric(X13), "Period" = as.Date(period_range)) %>%
      melt(id.vars = c("Period"), value.name = "Value", variable.name = "Method")
    
    # Generate plot
    p <- ggplot(plot_data, aes(x = Period, y = Value, group = Method, colour = Method)) +
      geom_line() +
      labs(title = series_description, subtitle = paste0(plot_type, "\nUnits: ", units)) +
      theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) +
      xlab("") +
      ylab("") +
      scale_x_date(date_breaks = "2 years", date_labels = "%Y", date_minor_breaks = "1 year") +
      scale_y_continuous(labels = scales::comma_format())

    # Print to PDF
    print(p)
  }

  # Close output device
  dev.off()
}

# Generate graphs for QBIS key data items
series <- download_ts("https://www.abs.gov.au/statistics/economy/business-indicators/business-indicators-australia/mar-2023/5676001.xlsx")
plot_ts(series$data, series$meta, type = "S", filename = paste0("QBIS - Table 1 - Mar23 - SA"))
plot_ts(series$data, series$meta, type = "T", filename = paste0("QBIS - Table 1 - Mar23 - TR"))