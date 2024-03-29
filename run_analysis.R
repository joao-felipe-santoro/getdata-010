# Check if needed package is installed
pkgs <- data.frame(installed.packages())
if(nrow(pkgs[(pkgs$Package=="data.table" & pkgs$Version == "1.9.4"),]) == 0){
  stop("Please, install package data.table v1.9.4 and run again!")
}
if(nrow(pkgs[(pkgs$Package=="sqldf" & pkgs$Version == "0.4-10"),]) == 0){
  stop("Please, install package sqldf v0.4-10 and run again!")
}
# Load needed packages
library("data.table","1.9.4")
library("sqldf","0.4-10")
# Downloads the ZIP file
temp <- tempfile()
download.file("http://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",temp)
# Files to Extract 
FEATURES_FILE <- unz(temp, "UCI HAR Dataset/features.txt")
ACTIVITY_LABELS_FILE <- unz(temp, "UCI HAR Dataset/activity_labels.txt")
TEST_DATA_FILE <- unz(temp, "UCI HAR Dataset/test/X_test.txt")
TEST_LABELS_FILE <- unz(temp, "UCI HAR Dataset/test/y_test.txt")
TEST_SUBJECTS_FILE <- unz(temp, "UCI HAR Dataset/test/subject_test.txt")
TRAIN_DATA_FILE <- unz(temp, "UCI HAR Dataset/train/X_train.txt")
TRAIN_LABELS_FILE <- unz(temp, "UCI HAR Dataset/train/y_train.txt")
TRAIN_SUBJECTS_FILE <- unz(temp, "UCI HAR Dataset/train/subject_train.txt")
# read features file
features_list <- read.table(FEATURES_FILE)
# read activity labels file
activity_labels <- read.table(ACTIVITY_LABELS_FILE)
# read all test files
test_data <- read.table(TEST_DATA_FILE)
test_labels <- read.table(TEST_LABELS_FILE)
test_subject <- read.table(TEST_SUBJECTS_FILE)
# read all train files
train_data <- read.table(TRAIN_DATA_FILE)
train_labels <- read.table(TRAIN_LABELS_FILE)
train_subject <- read.table(TRAIN_SUBJECTS_FILE)
# merge test & train files
merged_data <- rbind(test_data,train_data)
merged_labels <- rbind(test_labels,train_labels)
merged_subject <- rbind(test_subject,train_subject)
# removing unnecessary data from memory
rm(test_data,train_data,test_labels,train_labels,test_subject,train_subject,pkgs)
rm(TRAIN_SUBJECTS_FILE,TRAIN_LABELS_FILE,TRAIN_DATA_FILE)
rm(TEST_SUBJECTS_FILE,TEST_LABELS_FILE,TEST_DATA_FILE)
rm(ACTIVITY_LABELS_FILE,FEATURES_FILE)
unlink(temp)
rm(temp)
# naming the columns on data
colnames(merged_data)<- features_list[,2]
# finding which data "columns" have mean and std vars
meanStd_cols <- grep("mean\\(\\)|std\\(\\)", features_list[, 2])
# filtering out unwanted columns 
data <- merged_data[,meanStd_cols]
# improving readability on column names - Capitalizing mean, std to Mean, Std
colnames(data) <- gsub("mean", "Mean", colnames(data))
colnames(data) <- gsub("std", "Std", colnames(data))
# improving readability on column names - striping out "()" and "-"
colnames(data) <- gsub("\\(\\)", "", colnames(data)) 
colnames(data) <- gsub("-", "", colnames(data))
# removing unnecessary data from memory
rm(merged_data,features_list,meanStd_cols)
# naming columns
colnames(activity_labels)<-c("Id","Activity")
colnames(merged_subject)<-c("Subject")
colnames(merged_labels)<-c("Activity")

# improving readability on Acticity Labels - Camel Casing
activity_labels[,2] <- tolower(activity_labels[,2])
activity_labels[,2] <- sub('^(\\w?)', '\\U\\1', activity_labels[,2], perl=T)
activity_labels[,2] <- gsub('\\_(\\w?)', '\\U\\1', activity_labels[,2], perl=T)
#arranging labels to merge
activity_label <- activity_labels[merged_labels[, 1], 2]
#replacing IDs for their description
merged_labels[,1] <- activity_label
#fetching data col names for future usage
columns <- colnames(data)
# putting the whole thing in one place (subjects, activies and measurements)
data <- cbind(merged_subject,merged_labels,data)
# removing unnecessary data from memory
rm(activity_label,merged_subject,merged_labels,activity_labels)
avgs <- c()
for (i in 1:length(columns)){ avgs <- c(avgs, paste("AVG(",columns[i],") ",columns[i],"Avg",sep=""))}

features_avg_groupedby_subject_activity <- sqldf(paste("select Subject,Activity,",paste(avgs,collapse = ",")," from data group by Subject,Activity",sep=""))
write.table(features_avg_groupedby_subject_activity, "features_avg_groupedby_subject_activity.txt",row.name=FALSE)
rm(avgs,columns,i)