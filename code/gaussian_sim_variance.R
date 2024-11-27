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
calc_p_value <- function(obs, tau, mu0, n0, alpha, beta, alt) {
  x_bar <- mean(obs)
  n <- length(obs)

  alpha_star <- alpha + n / 2

  beta_star <- beta + (1 / 2) * sum((obs - x_bar)^2)
  beta_star <- beta_star + (n * n0) / (2 * (n + n0)) * (x_bar - mu0)^2


  if (alt == "less") {
    p_value <- pgamma(q = tau, shape = alpha_star, scale = beta_star, lower.tail = TRUE)
  } else if (alt == "greater") {
    p_value <- pgamma(q = tau, shape = alpha_star, scale = beta_star, lower.tail = FALSE)
  }

  return(p_value)
}

################
# Run sim
################

B <- 2
mus <- 0 # Setting to a single value so only priors are changing in README's graphs.
taus <- seq(1, 5, 1)
mu0s <- seq(-3, 3, 1)
n0s <- seq(1, 5, 1)
alphas <- seq(1, 5, 1)
betas <- seq(1, 5, 1)
ns <- seq(5, 55, 10)

all(taus > 0)
all(n0s > 0)
all(alphas > 0)
all(betas > 0)

total_sim <- B * length(mus) * length(taus) * length(mu0s) * length(n0s) * length(alphas) * length(betas)
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
              for (alpha in alphas) {
                for (beta in betas) {
                  pvalue <- calc_p_value(obs = obs, tau = tau, mu0 = mu0, n0 = n0, alpha = alpha, beta = beta, alt = alt)
                  temp <- tibble(
                    test = testName,
                    mu = mu,
                    tau = tau,
                    seed = i,
                    alt = alt,
                    N = n,
                    mu0 = mu0,
                    n0 = n0,
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
  saveRDS("results/gaussian_variance.rds")

rm(list = ls())
