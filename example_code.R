# Setup
library(boot)
library(tidyverse)

get_mpg_mean <- function(data, indices){
  # Function has to take in data and indices
  new_data = data[indices,] # Resample based on indices
  return(mean(new_data$mpg)) # Return statistic of interest
}  

# Create the boot object
boot_obj = boot(data = mtcars,
                statistic = get_mpg_mean,
                R = 1000)


## Visualizing the bootstrapped means

boot_obj$t %>% as.tibble %>% 
  ggplot() +
  geom_histogram(aes(x=V1), fill = 'orange',binwidth=.2) +
  xlab('Mean weight in bootstrapped samples') + 
  theme_light()

## Example of bootstrapped coefficients

# Function that will be repeated many times
get_coefs <- function(data, indices){
  new_data = data[indices,]
  fit_obj = lm(mpg ~ wt + hp + disp, data = new_data) 
  return(coef(fit_obj))
}

boot_obj = boot(data = mtcars,
                statistic = get_coefs,
                R = 2000)

# Visualizing bootstrapped coefficients

boot_df <- as.data.frame(boot_obj$t)

var_names = names(boot_obj$t0)
colnames(boot_df) <- var_names

library(ggridges)

boot_df %>% stack %>% 
  filter(ind != '(Intercept)') %>%
  ggplot() + theme_light() +
  geom_density_ridges(aes(x=values, y=ind), fill='orange', alpha=.4)

## Calculate confidence intervals

# Simple version - get quantiles
simple_cis <- sapply(boot_df, quantile, probs=c(.025, .975))

print(simple_cis)

# Bias corrected version
cis <- sapply(1:length(var_names), 
              function(x) boot.ci(boot_obj, 
                                  index=x,
                                  type = 'bca')$bca[4:5])

colnames(cis) <- var_names

print(cis)


## Using dot-whisker plots for visualizing bootstrapped coefficients
library(dotwhisker)
library(broom)

tidy(lm(mpg ~ wt + hp + disp, data=mtcars), conf.int = T) %>%
  mutate(conf.low = as.numeric(cis[1,]),
         conf.high = as.numeric(cis[2,])) %>%
  by_2sd(mtcars) %>% # Scale by sd of the measure
  dwplot(show_intercept = F) + theme_bw() +
  theme(legend.position="none") + 
  xlab('Beta coefficient with bootstrapped 95% CIs') + ylab('Variable') + 
  geom_vline(xintercept = 0, colour = "grey60", linetype = 2)