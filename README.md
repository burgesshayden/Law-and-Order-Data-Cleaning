# Law & Order Episode Data Cleaning

This project involves cleaning and processing data from the Wikipedia page for **Law & Order episodes** using R. The goal was to structure the data into a tidy format suitable for further analysis, with a focus on directors and episode viewership trends.

## Overview

The script `data_cleaning_part1-2.R` performs the following:

1. **Scrapes** episode tables from [Wikipedia](https://en.wikipedia.org/wiki/List_of_Law_%26_Order_episodes#Series_overview).
2. **Cleans** inconsistent formatting, missing values, and mismatched column names across 24 tables.
3. **Merges** all episode tables into a single tidy tibble.
4. **Adds new variables** such as season category and release date in proper formats.
5. **Creates a directors dataset** that tracks:
   - Number of episodes directed
   - First and last episode directed
   - Average viewers, max viewers, and other viewership stats per director

## Technologies Used

- **R**
- Libraries:
  - `tidyverse`
  - `rvest`
  - `readr`
  - `janitor`
  - `dplyr`

## Script Tasks

### Task 1
Clean and correct data types for episode-level information, including missing rows and numeric conversion.

### Task 2 & 3
Ensure uniform column names and data types (especially for production codes and viewer numbers).

### Task 4
Assign each episode to its correct season using `cut()` and cumulative episode counts.

### Task 5
Convert the `Original release date` column to proper `Date` type using parsing and cleaning steps.

### Task 6
Create a summary tibble of directors, including the first and last episode they directed.

### Task 7
Add metrics per director:
- Proportion of episodes with >17 million viewers
- Average viewers
- Max viewers
- Viewer ranking

## Output

Two main datasets are created:
- `big_epi`: cleaned and combined episode-level data
- `directors`: summary-level data for directors with viewership insights
