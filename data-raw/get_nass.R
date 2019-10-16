# Get USDA-NASS data from quickstats
# requires the 'rnassqs' package
library(rnassqs)
library(here)
library(jsonlite)
library(dplyr)

today <- format(Sys.time(), "%Y%m%d")

########## Need an API key from NASS.
# Get one here: https://quickstats.nass.usda.gov/api
##########


#### FUNCTIONS -----------------------------------------------------------------

#' wrapper to download quickstats data for different parameters
#' 
#' @param params a named list of parameters.
#' @param api_key character api key for nass quickstats.
#' @return a data.frame.
get_data <- function(params) {
  n_records <- as.integer(nassqs_record_count(params))
  if(n_records < 50000) {
    df_raw <- nassqs(params=params)
    # df <- df_raw[, c("data.year",
    #                  "data.state_name",
    #                  "data.state_alpha", 
    #                  "data.state_ansi",
    #                  "data.state_fips_code",
    #                  "data.county_name",
    #                  "data.county_ansi",
    #                  "data.county_code",
    #                  "data.class_desc",
    #                  "data.prodn_practice_desc",
    #                  "data.domaincat_desc",
    #                  "data.domain_desc",
    #                  "data.unit_desc",
    #                  "data.statisticcat_desc",
    #                  "data.Value")]
    return(df_raw)
  } else {stop("Too many records requested. Revise your query.")}
}



### GET RENT, INCOME, and NON-CROP SPECIFIC ------------------------------------
# NOTES ON VARIABLES:
# Acres: Cropland (not harvested or pastured) = all crops failed + fallow + idle
# Example (Yakima 2012):
# land_irr             <-  224386
# land_ex_hcrop_irr    <-   14073
# cropland_hcrop_irr   <-  210313
# pasture              <- 1433196
# pasture_ex_crop_wood <- 1429157
# cropland             <-  306851
# cropland_ex_hcrop_past <- 86832
# cropland_hcrop       <-  218054
# cropland_past        <-    1965
# woodland             <-    7724
# woodland_past        <-    2074
# woodland_npast       <-    5650
# land_rest            <-   36766
# 
# cropland = cropland_ex_hcrop_past + cropland_hcrop + cropland_past
# 
# land = woodland + pasture + cropland + land_rest
# 
# cropland_hcrop_irr <- land_irr - land_ex_hcrop_irr
# cropland_hcrop_nirr <- cropland_hcrop - cropland_hcrop_irr


## List of variables to get. Variables that apply to all are defined first.
param_list <- list(
  cash_rent_landbuildings = list(sector_desc = "ECONOMICS",
                                 commodity_desc = "RENT",
                                 class_desc = "CASH, LAND & BUILDINGS",
                                 unit_desc = "$",
                                 agg_level_desc = "COUNTY",
                                 domaincat_desc = "NOT SPECIFIED",
                                 year__GE = 1997, 
                                 year__LE = 2017),
  cash_rent_cropland_irr = list(sector_desc = "ECONOMICS",
                                commodity_desc = "RENT",
                                prodn_practice_desc = "IRRIGATED",
                                class_desc = "CASH, CROPLAND",
                                agg_level_desc = "COUNTY",
                                domaincat_desc = "NOT SPECIFIED",
                                year__GE = 2008,
                                year__LE = 2017),
  cash_rent_cropland_nirr = list(sector_desc = "ECONOMICS",
                                 commodity_desc = "RENT",
                                 prodn_practice_desc = "NON-IRRIGATED",
                                 class_desc = "CASH, CROPLAND",
                                 agg_level_desc = "COUNTY",
                                 domaincat_desc = "NOT SPECIFIED",
                                 year__GE = 2008,
                                 year__LE = 2017),
  cash_rent_pastureland = list(sector_desc = "ECONOMICS",
                               commodity_desc = "RENT",
                               class_desc = "CASH, PASTURELAND",
                               agg_level_desc = "COUNTY",
                               domaincat_desc = "NOT SPECIFIED",
                               year__GE = 2008,
                               year__LE = 2017),
  net_income = list(sector_desc = "ECONOMICS",
                    commodity_desc = "INCOME, NET CASH FARM",
                    class_desc = "OF OPERATIONS",
                    statisticcat_desc = "NET INCOME",
                    unit_desc = "$",
                    agg_level_desc = "COUNTY",
                    domaincat_desc = "NOT SPECIFIED",
                    year__GE = 1997, 
                    year__LE = 2017),
  ag_land_rented = list(source_desc = "CENSUS",
                        sector_desc = "DEMOGRAPHICS",
                        commodity_desc = "AG LAND",
                        agg_level_desc = "COUNTY",
                        prodn_practice_desc = "RENTED FROM OTHERS, IN FARMS",
                        unit_desc = "ACRES",
                        domain_desc = "TENURE",
                        year__GE = 1997, 
                        year__LE = 2017),
  ag_land_other = list(sector_desc = "ECONOMICS",
                       commodity_desc = "AG LAND",
                       agg_level_desc = "COUNTY",
                       class_desc = "(EXCL CROPLAND & PASTURELAND & WOODLAND)",
                       unit_desc = "ACRES",
                       domain_desc = "TOTAL",
                       domaincat_desc = "NOT SPECIFIED",
                       year__GE = 1997, 
                       year__LE = 2017),
  ag_land_excl_harvested_irr = list(sector_desc = "ECONOMICS",
                                    commodity_desc = "AG LAND",
                                    agg_level_desc = "COUNTY",
                                    prodn_practice_desc = "IRRIGATED",
                                    class_desc = "(EXCL HARVESTED CROPLAND)",
                                    unit_desc = "ACRES",
                                    domain_desc = "TOTAL",
                                    domaincat_desc = "NOT SPECIFIED",
                                    year__GE = 1997,
                                    year__LE = 2017),
  ag_land_irr = list(sector_desc = "ECONOMICS",
                     commodity_desc = "AG LAND",
                     agg_level_desc = "COUNTY",
                     prodn_practice_desc = "IRRIGATED",
                     class_desc = "ALL CLASSES",
                     unit_desc = "ACRES",
                     domain_desc = "TOTAL",
                     domaincat_desc = "NOT SPECIFIED",
                     year__GE = 1997, 
                     year__LE = 2017),
  ag_woodland = list(sector_desc = "ECONOMICS",
                     commodity_desc = "AG LAND",
                     agg_level_desc = "COUNTY",
                     class_desc = "WOODLAND",
                     unit_desc = "ACRES",
                     domaincat_desc = "NOT SPECIFIED",
                     statisticcat_desc = "AREA",
                     year__GE = 1997, 
                     year__LE = 2017),
  ag_pastureland = list(sector_desc = "ECONOMICS",
                        commodity_desc = "AG LAND",
                        agg_level_desc = "COUNTY",
                        class_desc = "PASTURELAND, (EXCL CROPLAND & WOODLAND)",
                        unit_desc = "ACRES",
                        domaincat_desc = "NOT SPECIFIED",
                        statisticcat_desc = "AREA",
                        year__GE = 1997, 
                        year__LE = 2017),
  ag_cropland = list(sector_desc = "ECONOMICS",
                     commodity_desc = "AG LAND",
                     agg_level_desc = "COUNTY",
                     class_desc = "CROPLAND",
                     unit_desc = "ACRES",
                     domaincat_desc = "NOT SPECIFIED",
                     statisticcat_desc = "AREA",
                     year__GE = 1997, 
                     year__LE = 2017),
  ag_cropland_excl_harvested = list(sector_desc = "ECONOMICS",
                                    commodity_desc = "AG LAND",
                                    agg_level_desc = "COUNTY",
                                    class_desc = "CROPLAND, (EXCL HARVESTED & PASTURED)",
                                    unit_desc = "ACRES",
                                    domaincat_desc = "NOT SPECIFIED",
                                    statisticcat_desc = "AREA",
                                    year__GE = 1997, 
                                    year__LE = 2017),
  ag_cropland_harvested = list(sector_desc = "ECONOMICS",
                               commodity_desc = "AG LAND",
                               agg_level_desc = "COUNTY",
                               class_desc = "CROPLAND, HARVESTED",
                               unit_desc = "ACRES",
                               prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                               statisticcat_desc = "AREA",
                               domaincat_desc = "NOT SPECIFIED",
                               year__GE = 1997, 
                               year__LE = 2017),
  ag_cropland_harvested_irr = list(sector_desc = "ECONOMICS",
                                   commodity_desc = "AG LAND",
                                   agg_level_desc = "COUNTY",
                                   class_desc = "CROPLAND, HARVESTED",
                                   unit_desc = "ACRES",
                                   prodn_practice_desc = "IRRIGATED",
                                   domaincat_desc = "NOT SPECIFIED",
                                   statisticcat_desc = "AREA",
                                   year__GE = 1997, 
                                   year__LE = 2017),
  ag_sales = list(sector_desc = "ECONOMICS",
                  commodity_desc = "COMMODITY TOTALS",
                  agg_level_desc = "COUNTY",
                  statisticcat_desc = "SALES",
                  util_practice_desc = "ALL UTILIZATION PRACTICES",
                  prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                  unit_desc = "$",
                  domain_desc = "TOTAL",
                  domaincat_desc = "NOT SPECIFIED",
                  year__GE = 1997,
                  year__LE = 2017),
  land_value = list(sector_desc = "ECONOMICS",
                    commodity_desc = "AG LAND",
                    agg_level_desc = "COUNTY",
                    statisticcat_desc = "ASSET VALUE",
                    #util_practice_desc = "ALL UTILIZATION PRACTICES",
                    unit_desc = "$",
                    domain_desc = "TOTAL",
                    #domaincat_desc = "NOT SPECIFIED",
                    year__GE = 1997, 
                    year__LE = 2017),
  land_value_per_acre = list(sector_desc = "ECONOMICS",
                             commodity_desc = "AG LAND",
                             agg_level_desc = "COUNTY",
                             statisticcat_desc = "ASSET VALUE",
                             #util_practice_desc = "ALL UTILIZATION PRACTICES",
                             unit_desc = "$ / ACRE",
                             domain_desc = "TOTAL",
                             #domaincat_desc = "NOT SPECIFIED",
                             year__GE = 1997, 
                             year__LE = 2017),
  expenses = list(sector_desc = "ECONOMICS",
                  commodity_desc = "EXPENSE TOTALS",
                  class_desc = "OPERATING",
                  unit_desc = "$",
                  agg_level_desc = "COUNTY",
                  domaincat_desc = "NOT SPECIFIED",
                  year__GE = 1997, 
                  year__LE = 2017),
  expense_seeds = list(sector_desc = "ECONOMICS",
                       group_desc = "EXPENSES",
                       commodity_desc = "SEEDS & PLANTS TOTALS",
                       agg_level_desc = "COUNTY",
                       unit_desc = "$",
                       year__GE = 1997,
                       year__LE = 2017
  ),
  expense_fert = list(sector_desc = "ECONOMICS",
                      group_desc = "EXPENSES",
                      commodity_desc = "FERTILIZER TOTALS",
                      agg_level_desc = "COUNTY",
                      unit_desc = "$",
                      year__GE = 1997,
                      year__LE = 2017
  ),
  expense_chem = list(sector_desc = "ECONOMICS",
                      group_desc = "EXPENSES",
                      commodity_desc = "CHEMICAL TOTALS",
                      agg_level_desc = "COUNTY",
                      unit_desc = "$",
                      year__GE = 1997,
                      year__LE = 2017
  ),
  expense_fuel = list(sector_desc = "ECONOMICS",
                      group_desc = "EXPENSES",
                      commodity_desc = "FUELS",
                      agg_level_desc = "COUNTY",
                      unit_desc = "$",
                      year__GE = 1997,
                      year__LE = 2017
  ),
  expense_hired = list(sector_desc = "ECONOMICS",
                       group_desc = "EXPENSES",
                       commodity_desc = "LABOR",
                       class_desc = "HIRED",
                       agg_level_desc = "COUNTY",
                       unit_desc = "$",
                       domaincat_desc = "NOT SPECIFIED",
                       year__GE = 1997,
                       year__LE = 2017
  ),
  farms_fullown = list(sector_desc = "DEMOGRAPHICS",
                       commodity_desc = "FARM OPERATIONS",
                       agg_level_desc = "COUNTY",
                       class_desc = "ALL CLASSES",
                       #prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                       statisticcat_desc = "OPERATIONS",
                       unit_desc = "OPERATIONS",
                       domaincat_desc = "TENURE: (FULL OWNER)",
                       year__GE = 1997, 
                       year__LE = 2017
  ),
  farms_partown = list(sector_desc = "DEMOGRAPHICS",
                       commodity_desc = "FARM OPERATIONS",
                       agg_level_desc = "COUNTY",
                       class_desc = "ALL CLASSES",
                       #prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                       statisticcat_desc = "OPERATIONS",
                       unit_desc = "OPERATIONS",
                       domaincat_desc = "TENURE: (PART OWNER)",
                       year__GE = 1997, 
                       year__LE = 2017
  ),
  farms_tenant = list(sector_desc = "DEMOGRAPHICS",
                      commodity_desc = "FARM OPERATIONS",
                      agg_level_desc = "COUNTY",
                      class_desc = "ALL CLASSES",
                      #prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                      statisticcat_desc = "OPERATIONS",
                      unit_desc = "OPERATIONS",
                      domaincat_desc = "TENURE: (TENANT)",
                      year__GE = 1997, 
                      year__LE = 2017
  ),
  farms_anyirr = list(sector_desc = "ECONOMICS",
                      commodity_desc = "AG LAND",
                      agg_level_desc = "COUNTY",
                      class_desc = "ALL CLASSES",
                      prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                      unit_desc = "OPERATIONS",
                      domain_desc = "IRRIGATION STATUS",
                      year__GE = 1997, 
                      year__LE = 2017
  ),
  farms_cropland_harvested_anyirr = list(sector_desc = "ECONOMICS",
                                         commodity_desc = "AG LAND",
                                         agg_level_desc = "COUNTY",
                                         class_desc = "ALL CLASSES",
                                         prodn_practice_desc = "ALL PRODUCTION PRACTICES",
                                         unit_desc = "OPERATIONS",
                                         domain_desc = "IRRIGATION STATUS",
                                         year__GE = 1997, 
                                         year__LE = 2017
  )
)

for(data_source in names(param_list)) {
  print(paste0("Downloading ", data_source, "..."))
  params <- param_list[[data_source]]
  
  # Check the size of the request - must be < 50000
  n <- nassqs_record_count(params)
  if(n >= 50000) {
    d <- get_data(params)
  } else {
    dlist <- lapply(state.abb, function(st) {
      params$state_alpha <- st
      get_data(params)
    })
    d <- bind_rows(dlist)
  }
  d$variable <- data_source
  saveRDS(d, paste0(data_dir, "/nass_county_", data_source, "_", today, ".rds"))
  
  # clean up
  remove(d); gc()
  return(TRUE)
}
