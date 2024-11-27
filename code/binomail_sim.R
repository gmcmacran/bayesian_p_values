library(tidyverse)
library(stringr)

################
# Define p value calculation
################
# Based on posterior on page 613 of math stats book
# p ~ beta(alpha, beta) or beta(shape1, shape2) in R's interface
# Y|p ~ binomail(p)
# obs ~ bernoli(p)
# Note obs is a vector of length N where each element is 0 or 1
# X
calc_p_value <- function(obs, p, alpha, beta, alt) {
  n <- length(obs)
  y <- sum(obs)
  alpha_star <- alpha + y
  beta_star <- beta + n - y

  if (alt == "less") {
    p_value <- pbeta(q = p, shape1 = alpha_star, shape2 = beta_star, lower.tail = TRUE)
  } else if (alt == "greater") {
    p_value <- pbeta(q = p, shape1 = alpha_star, shape2 = beta_star, lower.tail = FALSE)
  }

  return(p_value)
}

################
# Run sim
################

B <- 2
ps <- c(.25, .50, .75)
alphas <- seq(1, 10, 1)
betas <- seq(1, 10, 1)
ns <- seq(5, 55, 10)

all(ps > 0)
all(alphas > 0)
all(betas > 0)
all(ns > 0)

total_sim <- B * length(ps) * length(alphas) * length(betas) * length(ns)
print(str_c("Total number of iterations: ", total_sim))

sim_results <- tibble()
for (p in ps) {
  for (i in 1:B) {
    for (alt in c("less", "greater")) {
      for (n in ns) {
        # Hold data constant
        testName <- "binomial"
        set.seed(i)
        obs <- rbinom(n = n, size = 1, prob = p)

        # Change prior's parameters.
        for (alpha in alphas) {
          for (beta in betas) {
            pvalue <- calc_p_value(obs = obs, p = p, alpha = alpha, beta = beta, alt = alt)
            temp <- tibble(
              test = testName,
              p = p,
              seed = i,
              alt = alt,
              N = n,
              alpha = alpha,
              beta = beta,
              pvalue = pvalue
            )
            sim_results <- sim_results %>% bind_rows(temp)
          }
        }
      }
    }
  }
}

# Check structure
sim_results %>%
  distinct(test) %>%
  nrow() == 1

sim_results %>%
  distinct(alt) %>%
  nrow() == 2

sim_results %>%
  pull(pvalue) %>%
  min(na.rm = TRUE) >= 0

sim_results %>%
  pull(pvalue) %>%
  max(na.rm = TRUE) <= 1

# save
sim_results %>%
  saveRDS("results/binomial.rds")

rm(list = ls())
