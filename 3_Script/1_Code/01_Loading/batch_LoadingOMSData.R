source("3_Script/1_Code/00_init.R")
source("1_Input/config.txt")
source("3_Script/1_Code/01_Loading/UpdateSOIData.R")
source("3_Script/1_Code/01_Loading/UpdateSOITimeStamp.R")
source("3_Script/1_Code/01_Loading/UpdateSOIBaseData.R")

if (exists("1_Input/RData/soiData.RData")) {
  load("1_Input/RData/soiData.RData")
} else {
  soiData <- NULL
}
if (exists("1_Input/RData/soiData.RData")) {
  load("1_Input/RData/soiHistoryData.RData")
} else {
  soiHistoryData <- NULL
}


soiData <- UpdateSOIData(soiData, upToDate = "2015-08-01", 
                         server = serverIP, username = user, password = password)
save(soiData, file = "1_Input/RData/soiData.RData")

soiHistoryData <- UpdateSOITimeStamp(soiHistoryData, upToDate = "2015-08-01", 
                   server = serverIP, username = user, password = password)
save(soiHistoryData, file = "1_Input/RData/soiHistoryData.RData")
soiBasedData <- UpdateSOIBaseData(soiData, soiHistoryData)
save(soiBasedData, file = "1_Input/RData/soiBasedData.RData")
