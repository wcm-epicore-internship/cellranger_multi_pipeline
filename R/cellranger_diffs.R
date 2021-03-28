library(tidyverse)
library(patchwork)

df <- tribble(
  ~"Ig #Cells", ~"Ig #Prod", ~"Multi VDJ-B #Cells", ~"Multi VDJ-B #Prod", 
  4504,	3785, 4408, 3741,
  4164,	3359, 4069, 3303,
  4968,	3976, 4850, 3900,
  5365,	4209, 5140, 4060,
  5248,	4477, 5179, 4428,
  5719,	4825, 5662, 4792)

df['sample_name'] <- 
  c('CTRL_1', 'CTRL_2', 'CTRL_3', 
    'MYD88_1', 'MYD88_2', 'MYD88_3')


plot_df <- 
  df %>% pivot_longer(-c(sample_name))

p1 <- plot_df %>% 
  filter(grepl('Cells', name)) %>% 
  ggplot() + 
    geom_col(aes(x = sample_name, y = value, fill=name), 
             position = position_dodge2()) + 
  xlab('') + ylab('Cellranger Result') + 
  theme(legend.title = element_blank())

p2 <- plot_df %>% 
  filter(grepl('Prod', name)) %>% 
  ggplot() + 
    geom_col(aes(x = sample_name, y = value, fill=name), 
             position = position_dodge2()) + 
  xlab('') + ylab('Cellranger Result') + 
  theme(legend.title = element_blank())

p1 / p2 + plot_annotation
