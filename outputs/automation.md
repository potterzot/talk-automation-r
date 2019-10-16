---
title: "Let's Get Loopy!"
author: "Nicholas A Potter"
date: "10/16/2019"
output: 
  html_document:
    keep_md: true
---



## Before we start:

The following packages are needed to reproduce the code below:

- `here`
- `dplyr`
- `tidyr`
- `purrr`
- `furrr`
- `broom`
- `parallel`
- `data.table`

Install them all with `install.packages(c("here", "dplyr", "tidyr", "purrr", "furrr", "broom", "parallel", "data.table"))`.

## Basic Principle: Keep your code DRY (Don't Repeat Yourself)

#### Reduce frustration and errors by following these key ideas:
- Use loops to reduce chance of errors
- Limit loops to data that has the same format
- Write the interior of the loop first for a single case
- Loop for a small subset while developing
- Write checks for the data afterward

#### Options
- `for` loops `for (i in 1:n) { ... }`
- `apply`, `tapply`, `sapply`, `lapply`
- parrallel computing: `mclapply`
- `Reduce` and `Map`
- `purrr:reduce` and `purrr::map` [link](https://purrr.tidyverse.org/)
- `furrr:map` [link](https://davisvaughan.github.io/furrr/)

## Differences


## Looping with `apply`, `lapply`, `tapply`




## Looping over multiple files: load - combine - clean

Often you have many files, as we have in the `data` directory of this repository.


```r
library(here)
```

```
## here() starts at /home/potterzot/reason/talks/talk-automation-r
```

```r
files <- list.files(here("data"))
```

### Load

We could load each of them and then append:


```r
# ... so boring ... and so error prone ...
d1 <- readRDS(here("data", files[[1]]))

# d <- Reduce(rbind, list(d1, d2, d3, d4))
```

Instead you can iterate over the files and read them in:


```r
# Using a for loop
d_list <- list()
for (i in seq_along(files)) {
  d_list[[i]] <- readRDS(here("data", files[[i]]))
}

# Using lapply
d_list <- lapply(files, function(f) {
  readRDS(here("data", f))
  # You can do a lot of data processing here
})

# Using mclapply
library(parallel)
mc <- getOption("mc.cores", 4)
d_list <- mclapply(files, function(f) {
  readRDS(here("data", f))
  # You can do a lot of data processing here
})
```

### Comine 

Combine the data into a single data.frame:


```r
# Using Reduce
d <- Reduce(rbind, d_list)

# Using data.table
d <- data.table::rbindlist(d_list, fill = TRUE)

# Using dplyr
d <- dplyr::bind_rows(d_list)

# Using purrr
d <- purrr::map_dfr(d_list, ~ .)

# Parallel
d <- furrr::future_map_dfr(d_list, ~ .)
```

### Clean

Then we can tidy the data. We only need a few things:
- unit of observation (county)
- time of observation (year)
- variable
- value

But `Value` is a messy variable:


```r
sort(unique(d$Value)) %>% head()
```

```
## [1] "                 (D)" "                 (Z)" "0.3"                 
## [4] "0.4"                  "0.5"                  "0.6"
```


```r
head(d)
```

```
##   week_ending state_name country_code                      location_desc
## 1                ALABAMA         9000  ALABAMA, NORTHERN VALLEY, COLBERT
## 2                ALABAMA         9000  ALABAMA, NORTHERN VALLEY, COLBERT
## 3                ALABAMA         9000  ALABAMA, NORTHERN VALLEY, COLBERT
## 4                ALABAMA         9000  ALABAMA, NORTHERN VALLEY, COLBERT
## 5                ALABAMA         9000  ALABAMA, NORTHERN VALLEY, COLBERT
## 6                ALABAMA         9000 ALABAMA, NORTHERN VALLEY, FRANKLIN
##   begin_code zip_5 county_ansi state_alpha        util_practice_desc
## 1         00               033          AL ALL UTILIZATION PRACTICES
## 2         00               033          AL ALL UTILIZATION PRACTICES
## 3         00               033          AL ALL UTILIZATION PRACTICES
## 4         00               033          AL ALL UTILIZATION PRACTICES
## 5         00               033          AL ALL UTILIZATION PRACTICES
## 6         00               059          AL ALL UTILIZATION PRACTICES
##   domain_desc        asd_desc freq_desc      prodn_practice_desc end_code
## 1       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
## 2       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
## 3       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
## 4       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
## 5       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
## 6       TOTAL NORTHERN VALLEY    ANNUAL ALL PRODUCTION PRACTICES       00
##   sector_desc                short_desc  country_name  Value
## 1   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 85,790
## 2   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 65,683
## 3   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 60,028
## 4   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 69,414
## 5   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 72,630
## 6   ECONOMICS AG LAND, CROPLAND - ACRES UNITED STATES 32,410
##   reference_period_desc CV (%) class_desc asd_code agg_level_desc
## 1                  YEAR   19.5   CROPLAND       10         COUNTY
## 2                  YEAR   13.4   CROPLAND       10         COUNTY
## 3                  YEAR          CROPLAND       10         COUNTY
## 4                  YEAR          CROPLAND       10         COUNTY
## 5                  YEAR          CROPLAND       10         COUNTY
## 6                  YEAR   19.5   CROPLAND       10         COUNTY
##   county_name region_desc watershed_desc state_ansi congr_district_code
## 1     COLBERT                                    01                    
## 2     COLBERT                                    01                    
## 3     COLBERT                                    01                    
## 4     COLBERT                                    01                    
## 5     COLBERT                                    01                    
## 6    FRANKLIN                                    01                    
##   domaincat_desc state_fips_code            group_desc watershed_code
## 1  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
## 2  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
## 3  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
## 4  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
## 5  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
## 6  NOT SPECIFIED              01 FARMS & LAND & ASSETS       00000000
##   unit_desc source_desc           load_time county_code statisticcat_desc
## 1     ACRES      CENSUS 2018-02-01 00:00:00         033              AREA
## 2     ACRES      CENSUS 2012-12-31 00:00:00         033              AREA
## 3     ACRES      CENSUS 2012-01-01 00:00:00         033              AREA
## 4     ACRES      CENSUS 2012-01-01 00:00:00         033              AREA
## 5     ACRES      CENSUS 2012-01-01 00:00:00         033              AREA
## 6     ACRES      CENSUS 2018-02-01 00:00:00         059              AREA
##   commodity_desc year    variable
## 1        AG LAND 2017 ag_cropland
## 2        AG LAND 2012 ag_cropland
## 3        AG LAND 2007 ag_cropland
## 4        AG LAND 2002 ag_cropland
## 5        AG LAND 1997 ag_cropland
## 6        AG LAND 2017 ag_cropland
```

```r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
library(tidyr)
d_tdy <- d %>%
  # Just the columns we want
  select(state_alpha, state_fips_code, county_code, year, variable, Value) %>%
  # Keep just the census variables
  filter(year %in% seq(1997,2017, by = 5)) %>%
  # Create a `fips` column that is the unit of observation identifier
  unite(fips, state_fips_code, county_code, sep = "") %>%
  # Clean the `Value` column to be numeric
  mutate(value = trimws(gsub(",", "", Value)),
         value = gsub("(Z)|(D)", NA, value),
         value = as.numeric(value)) %>%
  # Fix multiple observations for a given fips-year combination
  group_by(state_alpha, fips, year, variable) %>%
  summarize(value = sum(value, na.rm = TRUE)) %>%
  # Give each value in `variable` it's own column
  spread(key = variable, value = value) %>%
  # remove the grouping
  ungroup()
```

## Looping over multiple files: load - clean - combine

We could switch the order of things to clean each data set as we read it in. I personally prefer the first option if possible. It is faster, but sometimes you have to do some cleaning that is specific to a certain file.

__Reasons to use the load - clean - combine ordering__

- The combined data is too big to be read into memory without subsetting/cleaning first.
- Data has to be handled differently based on file, use `if(f == ...) { ... } else if(...) { ... } else { ... }` to handle, or use different read loops to group files that are formatted the same.



```r
d_list <- lapply(files, function(f) {
  d <- readRDS(here("data", f)) %>%
    # Keep just the census variables
    filter(year %in% seq(1997,2017, by = 5))

  if(nrow(d) > 0) {
    d_tdy <- d %>%
      # Just the columns we want
      select(state_alpha, state_fips_code, county_code, year, variable, Value) %>%
      # Create a `fips` column that is the unit of observation identifier
      unite(fips, state_fips_code, county_code, sep = "") %>%
      # Clean the `Value` column to be numeric
      mutate(value = trimws(gsub(",", "", Value)),
             value = gsub("(Z)|(D)", NA, value),
             value = as.numeric(value)) %>%
      # Fix multiple observations for a given fips-year combination
      group_by(state_alpha, fips, year, variable) %>%
      summarize(value = sum(value, na.rm = TRUE)) %>%
      # Give each value in `variable` it's own column
      spread(key = variable, value = value) %>%
      # remove the grouping
      ungroup()
  } else {
    d_tdy <- data.frame()
  }

  d_tdy
})

# CAREFUL! Don't rbind because we've already transformed the data, so we have to merge instead
d <- Reduce(function(x,y) { merge(x,y, by = c("state_alpha", "fips", "year"), all.x = TRUE) }, d_list)
```

## Looping for analysis

We can regress data here using a model, something like


```r
# Let's see if there's a relationship between farm profits per acre and ownership rates
d2 <- d_tdy %>%
  mutate(farms = farms_fullown + farms_partown + farms_tenant,
         ag_expenses = expense_chem + expense_fert + expense_fuel + 
                       expense_hired + expense_seeds,
         profit_per_farm = (ag_sales - ag_expenses) / farms,
         farms_rented_pct = farms_tenant / farms)
# Note that the standard errors here won't be right because there is likely spatial and temporal correlation
d_west <- d2 %>%
  filter(state_alpha %in% c("WA", "OR", "ID", "MT", "CA", "AZ", "NV", "UT", "NM", "CO", "WY"))
m <- lm(farms_rented_pct ~ profit_per_farm + fips + state_alpha:year, data = d_west)
```

Often we want to run a number of regression models and output the results as a list


```r
# Using lapply
result_list <- lapply(1:10, function(i) {
  dsub <- d_west %>% filter(ntile(d_west$profit_per_farm, 10) == 1)
  m <- lm(farms_rented_pct ~ profit_per_farm + fips + state_alpha:year, data = dsub)
})

# Or with purrr
result_list <- d_west %>%
  mutate(decile = ntile(.$profit_per_farm, 10)) %>%
  split(.$decile) %>%
  map(~ lm(farms_rented_pct ~ profit_per_farm + fips + state_alpha:year, data = .))
```

And we can also loop to extract coefficients and summary statistics

```r
library(broom)
library(purrr)

# Coefficients
coef_list <- lapply(seq_along(result_list), function(i) {
  coefs <- tidy(result_list[[i]])
  coefs$model <- paste0("dec_", i)
  coefs
})
coefs <- bind_rows(coef_list)

# Summary Stats
stat_list <- lapply(result_list, function(r) {
  glance(r)
})
names(stat_list) <- paste0("dec_", 1:10)
sumstats <- bind_rows(stat_list)
```
