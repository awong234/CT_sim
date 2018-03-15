library(ggplot2)
library(dplyr)


# Testing taskIn

taskIN(debug = F, taskURL = 'taskList.csv')


# Testing getDesign

xlim = c(0,100)
ylim = c(0,100)

getDesign(noTraps = 100, noClust = 50)

# Testing make Vogelcluster

points = makeVogelCluster(noPoints = 20)

points = data.frame(points)
names(points) = c('x', 'y')

ggplot(data = points) + 
  geom_point(aes(x = x, y = y)) + 
  coord_equal()

summary(as.numeric(fields::rdist(points)))
