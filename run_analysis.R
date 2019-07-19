## Load packages and get data

packages <- c("data.table", "reshape2")
sapply(packages, require, character.only=TRUE, quietly=TRUE)
path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")

## Read labels and measurements, reduce output to standard deviation and mean

activity_labels <- fread(file.path(path,"UCI HAR Dataset/activity_labels.txt")
                         , col.names = c("classLabels", "activityName"))                         
features <- fread(file.path(path, "UCI HAR Dataset/features.txt")
                  , col.names = c("index", "featurenames"))
featureswanted <- grep("(mean|std)\\(\\)", features[, featurenames])
measurements <- features[featureswanted, featurenames]
measurements <- gsub('[()]', '', measurements)

## Load desired featers from train data and combine
train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, featureswanted, with = FALSE]
data.table::setnames(train, colnames(train), measurements)
trainActivities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                         , col.names = c("Activity"))
trainSubjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                       , col.names = c("SubjectNum"))
train <- cbind(trainSubjects, trainActivities, train)

# Load test data and repeat previous
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, featureswanted, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
testActivities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                         , col.names = c("Activity"))
testSubjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                       , col.names = c("SubjectNum"))
test <- cbind(testSubjects, testActivities, test)

## merge test and train
Merged <- rbind(test, train)

## Appropriately label the data set with descriptive variable names.
Merged[["Activity"]] <- factor(Merged[, Activity]
                               , levels = activity_labels[["classLabels"]]
                               , labels = activity_labels[["activityName"]])
Merged[["SubjectNum"]] <- as.factor(Merged[, SubjectNum])
Merged <- reshape2::melt(data = Merged, id = c("SubjectNum", "Activity"))
Merged <- reshape2::dcast(data = Merged, SubjectNum + Activity ~ variable, fun.aggregate = mean)

## Write dataset as new text file "tidyData"
data.table::fwrite(x = Merged, file = "tidyData.txt", quote = FALSE)
