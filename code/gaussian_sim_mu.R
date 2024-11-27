library(tidyverse)
library(stringr)
library(furrr)

################
# Define p value calculation
################
# tau ~ gamma(alpha, beta) or gamma(shape, scale) in R's interface.
# mu ~ N(mu0, n0*tau) variance, not standard deviation
# X|mu, tau ~ N(mu, tau)
# See included pdf.
calc_p_value <- function(obs, mu, tau, mu0, n0, alt) {
  x_bar <- mean(obs)
  n <- length(obs)

  mu_star <- (n * tau) / (n * tau + n0 * tau) * x_bar
  mu_star <- mu_star + (n0 * tau) / (n * tau + n0 * tau) * mu0

  var_star <- n * tau + n0 * tau
  sd_star <- var_star^.5

  if (alt == "less") {
    p_value <- pnorm(q = mu, mean = mu_star, sd = sd_star, lower.tail = TRUE)
  } else if (alt == "greater") {
    p_value <- pnorm(q = mu, mean = mu_star, sd = sd_star, lower.tail = FALSE)
  }

  return(p_value)
}

################
# Run sim
################

B <- 2
mus <- seq(-3, 3, 1)
taus <- 5 # Setting to a single value so only priors are changing in README's graphs.
mu0s <- seq(-3, 3, 1)
n0s <- seq(1, 5, 1)
ns <- seq(5, 55, 10)

all(taus > 0)
all(n0s > 0)

total_sim <- B * length(mus) * length(taus) * length(mu0s) * length(n0s)
print(str_c("Total number of iterations: ", total_sim))

sim_results <- tibble()
for (mu in mus) {
  for (tau in taus) {
    for (i in 1:B) {
      for (alt in c("less", "greater")) {
        for (n in ns) {
          # Hold data constant
          testName <- "gaussian_mu"
          set.seed(i)
          obs <- rnorm(n = n, mean = mu, sd = tau^.5)

          # Change prior's parameters.
          for (mu0 in mu0s) {
            for (n0 in n0s) {
              pvalue <- calc_p_value(obs = obs, mu = mu, tau = tau, mu0 = mu0, n0 = n0, alt = alt)
              temp <- tibble(
                test = testName,
                mu = mu,
                tau = tau,
                seed = i,
                alt = alt,
                N = n,
                mu0 = mu0,
                n0 = n0,
                pvalue = pvalue
              )
              sim_results <- sim_results %>% bind_rows(temp)
            }
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
  saveRDS("results/gaussian_mu.rds")

rm(list = ls())
