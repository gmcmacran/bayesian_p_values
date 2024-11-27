library(tidyverse)
library(purrr)

check_dataset <- function(fn) {
  fn <- str_c("results/", fn, collapse = "")
  sim_results <- readRDS(fn)

  # Check structure
  B0 <- sim_results %>%
    nrow() > 0

  B1 <- sim_results %>%
    nrow() == sim_results %>%
    drop_na() %>%
    nrow()

  B2 <- sim_results %>%
    distinct(test) %>%
    nrow() == 1

  B3 <- sim_results %>%
    distinct(alt) %>%
    nrow() == 2

  B4 <- sim_results %>%
    pull(pvalue) %>%
    min(na.rm = TRUE) >= 0

  B5 <- sim_results %>%
    pull(pvalue) %>%
    max(na.rm = TRUE) <= 1

  out <- B1 && B2 && B3 && B4 && B5
  return(out)
}

fns <- c("binomial.rds", "poisson.rds", "gaussian_mu.rds", "gaussian_variance.rds")
results <- map_lgl(fns, check_dataset)
all(results)
