import pandas as pd
import numpy as np
from datetime import datetime
import re

# Load the page 
url = "https://en.wikipedia.org/wiki/List_of_Law_%26_Order_episodes#Series_overview"
tables = pd.read_html(url)

# Extract episode tables
law_tables_epi = tables[1:25]

# Fix Table 9 (missing row)
law_tables_epi[8] = law_tables_epi[8].drop(index=5)

# Fix types in table 9
law_tables_epi[8]['No.overall'] = pd.to_numeric(law_tables_epi[8]['No.overall'], errors='coerce')
law_tables_epi[8]['No. inseason'] = pd.to_numeric(law_tables_epi[8]['No. inseason'], errors='coerce')
law_tables_epi[8]['U.S. viewers(millions)'] = (
    law_tables_epi[8]['U.S. viewers(millions)']
    .astype(str)
    .str.replace(r'[^\d.]', '', regex=True)
    .astype(float)
)

# Convert prod codes and fix column names
for i in range(24):
    if i == 8:
        continue
    if 'Prod.code' in law_tables_epi[i].columns:
        law_tables_epi[i]['Prod.code'] = law_tables_epi[i]['Prod.code'].astype(str)

# Fix column names
law_tables_epi[23].columns.values[2] = 'Title'
law_tables_epi[23].columns.values[5] = 'Original release date'
for i in range(20, 24):
    if len(law_tables_epi[i].columns) >= 8:
        law_tables_epi[i].columns.values[7] = 'U.S. viewers(millions)'

# Fix viewer type for all other tables
for i in range(24):
    if i == 8:
        continue
    if "U.S. viewers(millions)" in law_tables_epi[i].columns:
        law_tables_epi[i]["U.S. viewers(millions)"] = (
            law_tables_epi[i]["U.S. viewers(millions)"]
            .astype(str)
            .str.replace(r'[^\d.]', '', regex=True)
            .astype(float)
        )

# Combine all episode tables
big_epi = pd.concat(law_tables_epi, ignore_index=True)

# Add Season Category
season_counts = pd.to_numeric(tables[0]['Episodes'][1:24], errors='coerce')
season_labels = [f'season_{i}' for i in range(1, 25)]
breaks = [0] + list(np.cumsum(season_counts)) + [513]
big_epi['Season_Category'] = pd.cut(big_epi['No.overall'], bins=breaks, labels=season_labels, right=True)

# Extract and convert release date
big_epi['Orig_Release_Date'] = (
    big_epi['Original release date']
    .astype(str)
    .str.extract(r'\((.*?)\)')[0]
    .apply(pd.to_datetime, errors='coerce')
)

# One row per director
# Count episodes
director_counts = big_epi['Directed by'].value_counts().sort_index().reset_index()
director_counts.columns = ['Directed by', 'episode_count']

# First episodes
first_eps = big_epi.sort_values('No.overall').drop_duplicates('Directed by')
first_eps.columns = [f'first_{col}' for col in first_eps.columns]

# Last episodes
last_eps = big_epi.sort_values('No.overall', ascending=False).drop_duplicates('Directed by')
last_eps.columns = [f'last_{col}' for col in last_eps.columns]

# Merge director summary
directors = pd.merge(director_counts, first_eps, left_on='Directed by', right_on='first_Directed by')
directors = pd.merge(directors, last_eps, left_on='Directed by', right_on='last_Directed by')

# Viewer stats
viewer_stats = (
    big_epi.groupby('Directed by')['U.S. viewers(millions)']
    .agg([
        ('high_rate', lambda x: (x > 17).mean()),
        ('mean_viewers', 'mean'),
        ('max_viewers', 'max')
    ])
    .reset_index()
)
viewer_stats['viewer_rank'] = viewer_stats['mean_viewers'].rank(method='min')

# Merge into directors table
directors = pd.merge(directors, viewer_stats, on='Directed by')
