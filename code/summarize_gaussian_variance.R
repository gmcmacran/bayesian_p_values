library(tidyverse)
library(scales)

###############
# Load data
###############
fn <- str_c("results/", "gaussian_variance.rds", collapse = "")
sim_df <- readRDS(fn)


###############
# Boxplots
###############
sim_df %>%
  filter(alt == "less", seed <= 2) %>%
  ggplot(aes(x = factor(mu), y = pvalue)) +
  geom_boxplot() +
  scale_y_continuous(breaks = seq(0, 1, .20), labels = percent, limits = c(0, 1)) +
  facet_grid(rows = vars(seed), cols = vars(N)) +
  labs(title = "Alternative: Less", x = "Mu", y = "P Value")

ggsave(filename = "results/graphs/gaussian_var_less.png", width = 10, height = 10)

sim_df %>%
  filter(alt == "greater", seed <= 2) %>%
  ggplot(aes(x = factor(mu), y = pvalue)) +
  geom_boxplot() +
  scale_y_continuous(breaks = seq(0, 1, .20), labels = percent, limits = c(0, 1)) +
  facet_grid(rows = vars(seed), cols = vars(N)) +
  labs(title = "Alternative: Greater", x = "Mu", y = "P Value")

ggsave(filename = "results/graphs/gaussian_var_greater.png", width = 10, height = 10)

###############
# Which parameter of the prior is driving changes?
###############
# Seed and therefore data is changing within each group.
temp <- sim_df %>%
  group_by(mu, tau, N, alt, mu0, n0, alpha, beta) %>%
  summarize(range_p_value = max(pvalue) - min(pvalue)) %>%
  ungroup()

temp %>%
  ggplot(aes(x = as.factor(alpha), y = as.factor(beta), fill = range_p_value)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red", limit = c(0, 1)) +
  labs(title = "Prior Parameter Effects", x = "Shape", y = "Scale", fill = "Range Of P Value") +
  theme_minimal() +
  facet_grid(rows = vars(alt), cols = vars(N))

ggsave(filename = "results/graphs/gaussian_var_prior_params.png", width = 10, height = 10)

temp %>%
  ggplot(aes(x = as.factor(mu0), y = as.factor(n0), fill = range_p_value)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red", limit = c(0, 1)) +
  labs(title = "Prior Parameter Effects", x = "Shape", y = "Scale", fill = "Range Of P Value") +
  theme_minimal() +
  facet_grid(rows = vars(alt), cols = vars(N))

ggsave(filename = "results/graphs/gaussian_var_prior_params_two.png", width = 10, height = 10)

rm(list = ls())
