## Preliminary ##
library(tidyverse)
library(rvest)
library(readr)
library(dplyr)
library(janitor)
url = "https://en.wikipedia.org/wiki/List_of_Law_%26_Order_episodes#Series_overview"
html = read_html(url)
law.tables = html |>
  html_table()
##############################################

# Get tables with episode info

law.tables.epi = law.tables[2:25]

# Table 9: Row 6 is missing no. overall, no. inseason and prod. code data

law.table9 = law.tables.epi[[9]][-6,] # remove 6th row from 9th table

# TASK 1:
# correct data types in table 9

law.table9$No.overall = parse_double(law.table9$No.overall)
law.table9$`No. inseason` = parse_double(law.table9$`No. inseason`)
law.table9$`U.S. viewers(millions)` = parse_number(law.table9$`U.S. viewers(millions)`)
law.tables.epi[[9]] = law.table9

# TASK 2/3:

# change all prod codes to chr
for(i in 1:24){
  if (i == 9) next
  law.tables.epi[[i]]$Prod.code = as.character(law.tables.epi[[i]]$Prod.code)
}

# make all column names match
names(law.tables.epi[[24]])[3] = "Title"
names(law.tables.epi[[24]])[6] = "Original release date"
for(i in 21:24){
    names(law.tables.epi[[i]])[8] = "U.S. viewers(millions)"
  }

# change data type in U.S. viewers to dbl
for(i in 1:24){
  if (i == 9) next
  law.tables.epi[[i]]$`U.S. viewers(millions)` = parse_number(law.tables.epi[[i]]$`U.S. viewers(millions)`)
  }

# combine all tibbles
big_epi = bind_rows(law.tables.epi)


# TASK 4
# create new variable showing which season each episode belongs to

law.table1 = law.tables[[1]]$Episodes[2:24]
law.table1 = parse_number(law.table1) # get season episode counts
season_labels = paste("season", 1:24, sep="_") # make labels
breaks = c(0, cumsum(law.table1), 513) # set breaks
# add the new column
big_epi$Season_Category = cut(big_epi$No.overall, breaks=breaks, labels=season_labels, right=TRUE)


# TASK 5
# Create a new column with type date for Orig. Release Date

big_epi = big_epi |>
separate_wider_delim(
  `Original release date`,
  delim = "(", # Remove everything up to the opening parens to keep just date 
  names = c(NA, "Orig_Release_Date") # rename column 
  )

big_epi = big_epi |>
separate_wider_delim(
  Orig_Release_Date,
  delim = ")", # Remove leftover closing parens, leaving just date as chr
  names = c("Orig_Release_Date", NA) # Rename column
  )

# Convert column to type date 
big_epi = big_epi |>
  mutate(Orig_Release_Date = as_date(Orig_Release_Date))

# Clean names 
big_epi = clean_names(big_epi)


# TASK 6
# new tibble with one row per director

# Get how many episodes each director directed, alphabetical
director_counts = big_epi |> 
  count(directed_by, sort = TRUE) |>
  arrange(directed_by, descending = FALSE)

big_epi = big_epi |>
  arrange(directed_by, descending = FALSE)

# Get first episode info
first_episode = big_epi |>
  distinct(directed_by, .keep_all = TRUE)

# Change column names to distinguish from last episode data
names(first_episode) = paste0("first_", names(first_episode))

# Remove unnecessary rows and reorder columns 
first_episode = first_episode |>
  relocate(first_season_category, .after = first_no_inseason) |>
  select(-first_directed_by, -first_written_by, -first_prod_code)

# Create a descending version of big epi to use distinct to capture 
# last episode 
big_epi_desc = big_epi |>
  arrange(desc(no_overall)) |>
  arrange(directed_by, decreasing = FALSE)

# Get last episode info
last_episode = big_epi_desc |>
  distinct(directed_by, .keep_all = TRUE)

# Change column names to distinguish from first episode data
names(last_episode) = paste0("last_", names(last_episode))

# Remove unnecessary rows and reorder columns 
last_episode = last_episode |>
  relocate(last_season_category, .after = last_no_inseason) |>
  select(-last_directed_by, -last_written_by, -last_prod_code)

# Combine all tibbles
directors = bind_cols(director_counts, first_episode, last_episode)


# TASK 7
# 4 additional columns on directors tibble

# calculate episodes > 17 mil views, average views, max viewers and rank 
task_7 = big_epi |>
  group_by(directed_by) |>
    summarize(
      high_rate = mean(u_s_viewers_millions > 17, na.rm = TRUE),
      mean_viewers = mean(u_s_viewers_millions, na.rm = TRUE),
      max_viewers = max(u_s_viewers_millions, na.rm = TRUE)
      ) |>
    mutate(viewer_rank = min_rank(mean_viewers))

# remove directed by column
task_7 = task_7 |>
  select(-directed_by)

# add new columns to directors
directors = bind_cols(directors, task_7)


