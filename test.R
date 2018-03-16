library(ggplot2)
library(dplyr)

source('functions.R')

# Generate test task list

testTaskList = data.frame("taskID" = seq(from = 1, to = 100), "inProgress" = 0, "completed" = 0, "owner" = NA)
testTaskList = rbind.data.frame(testTaskList, data.frame("taskID" = c(101,102, 103), 
                                                         "inProgress" = c(1,1,0), "completed" = c(0,0,1), "owner" = c(Sys.info()['nodename'], "other", "other")))
row.names(testTaskList) = NULL
write.csv(testTaskList, file = '../CT_sim_tasks/taskList.csv', row.names = F)
rm(testTaskList)


# Testing taskIn
reservedTasks = taskIn(debug = F)

while(length(reservedTasks > 0)){
  doNothing(reservedTasks = reservedTasks)
  reservedTasks = taskIn(debug = F)
}


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
