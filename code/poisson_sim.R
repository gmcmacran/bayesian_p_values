library(tidyverse)
library(stringr)

################
# Define p value calculation
################
# Based on posterior on page 611 of math stats book
# theta ~ gamma(alpha, beta) or gamma(shape, scale) in R's interface
# X|theta ~ poisson(theta) or poisson(lambda) in R's interface
calc_p_value <- function(obs, theta, alpha, beta, alt) {
  n <- length(obs)
  alpha_star <- sum(obs + alpha)
  beta_star <- beta / (n * beta + 1)

  if (alt == "less") {
    p_value <- pgamma(q = theta, shape = alpha_star, scale = beta_star, lower.tail = TRUE)
  } else if (alt == "greater") {
    p_value <- pgamma(q = theta, shape = alpha_star, scale = beta_star, lower.tail = FALSE)
  }

  return(p_value)
}

################
# Type I
################

B <- 50
thetas <- c(1, 5, 10, 15, 20, 25)
alphas <- seq(1, 5, 1)
betas <- seq(1, 5, 1)
ns <- seq(5, 55, 10)

all(thetas > 0)
all(alphas > 0)
all(betas > 0)
all(ns > 0)

total_sim <- B * length(thetas) * length(alphas) * length(betas) * length(ns)
print(str_c("Total number of iterations: ", total_sim))

sim_results <- tibble()
for (theta in thetas) {
  for (i in 1:B) {
    for (alt in c("less", "greater")) {
      for (n in ns) {
        # Hold data constant
        testName <- "poisson"
        set.seed(i)
        obs <- rpois(n = n, lambda = theta)

        # Change prior's parameters.
        for (alpha in alphas) {
          for (beta in betas) {
            pvalue <- calc_p_value(obs = obs, theta = theta, alpha = alpha, beta = beta, alt = alt)
            temp <- tibble(
              test = testName,
              theta = theta,
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
  saveRDS("results/poisson.rds")

rm(list = ls())
