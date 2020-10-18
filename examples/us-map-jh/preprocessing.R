library(dplyr)
library(purrr)
library(magrittr)
library(ggplot2)
library(stringr)
library(reshape2)
library(jsonlite)

jhu_df <- read.csv("time_series_covid19_confirmed_US.csv") %>%
  select(Province_State, starts_with("X")) %>%
  rename(state = Province_State) %>%
  melt(id.vars = "state", value.name = "case_count") %>%
  mutate(date = as.Date(variable, format = "X%m.%d.%y")) %>%
  filter(date <= "2020-10-16", date > "2020-10-08") %>%
  group_by(state, date) %>%
  summarise(daily_total = sum(case_count))

jhu_states <- unique(jhu_df$state)
jhu_list <- map(.x = jhu_states,
                .f = ~ filter(jhu_df, state == .x))
names(jhu_list) <- jhu_states

income_list <- read_json("income.json") %>%
  keep(~ .x$group == "200000+")

census_df <- read.csv("nst-est2019-alldata.csv") %>%
  select(NAME, POPESTIMATE2019)

census_list <- as.list(census_df$POPESTIMATE2019)
names(census_list) <- census_df$NAME

result <- list()
for (ix in 1:length(income_list)) {
  record <- income_list[[ix]]
  state_name <- record$name
  record$daily_average <- jhu_list[[state_name]]$daily_total %>%
    diff %>%
    mean
  record$population <- census_list[[state_name]]
  record$cases_per_million <- 1e6 * record$daily_average / record$population
  result <- c(result, list(record))
}

write_json(x = result,
           auto_unbox = TRUE,
           digits = 4,
           pretty = TRUE,
           path = "jhu-clean.json")

min_cases_per_million <- result %>%
  map(~ .x$cases_per_million) %>%
  unlist %>%
  sort(decreasing = TRUE) %>%
  head(4) %>%
  min
top_states <- result %>%
  keep(.p = ~ .x$cases_per_million >= 524) %>%
  map(.f = ~ .x$name)

print(top_states)
