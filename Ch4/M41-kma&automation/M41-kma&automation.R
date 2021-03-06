# 0. setup environment  
source("../../LSR.R")
activate(c("dplyr", "tidyverse", "jsonlite"))

# 1. setup API  
svc_key <- paste0("uEID6no5WOeFLEu%2FYZpdjKHQVrE2HtFEig4lJ7iHWiE5w",
                  "GS1L3RvmusPMDkumoj8f%2BSffvPYWO%2B5xXu%2FrQ%2Bvzg%3D%3D")
today   <- gsub("-", "", Sys.Date())
url     <- paste0("http://newsky2.kma.go.kr/service/SecndSrtpdFrcstInfoService2",
                  "/ForecastSpaceData")
# 2. get maxPage  
fields  <- c("ServiceKey", "base_date", "base_time", "nx", "ny" , "_type")
values  <- c(svc_key     , today      , "0800"     , "60", "127", "json")
request <- paste(fields, values, sep = "=") %>% paste(collapse="&")
query   <- paste0(url, "?", request)
raw     <- readLines(query, warn = "F", encoding = "UTF-8") %>% fromJSON()
maxPage <- ceiling(raw$response$body$totalCount/raw$response$body$numOfRows)

# 3. collect all pages  
fields  <- c("ServiceKey", "base_date", "base_time", "nx", "ny" , "_type", "pageNo")
dataset <- data.frame()
for (i in 1:maxPage) {
  values_i  <- c(svc_key  , today      , "0800"    , "60", "127", "json" , i)
  request_i <- paste(fields, values_i, sep = "=") %>% paste(collapse="&")
  query_i   <- paste0(url, "?", request_i)
  raw_i     <- readLines(query_i, warn = "F", encoding = "UTF-8") %>% fromJSON()
  dataset_i <- raw_i$response$body$items$item
  dataset   <- rbind(dataset, dataset_i)
}

# 4. deliver output
# print(dataset)

# 4. Relevant infos
sapply(dataset[,1:5], unique)
title <- paste("Good Morning", dataset[1,1])
dataset <- dataset %>% 
  filter(category %in% c("PTY", "POP", "T3H")) %>%
  filter(fcstTime %in% c(1500, 2100)) %>%
  select(fcstDate, fcstTime, category, fcstValue)
dataset <- dataset %>% 
  spread(key = category, value = fcstValue) %>%
  mutate(PTYword = ifelse(PTY==0, "No rain",
                          ifelse(PTY==1, "Rainy",
                                 ifelse(PTY==2, "Rain_Snow", "Snowy")))) %>%
  rename(Date = fcstDate, Time = fcstTime, Temp = T3H, PrecipPCT = POP, SKY = PTYword) %>%
  select(Date, Time, Temp, PrecipPCT, SKY)

# 5. mailR
activate("mailR", "htmlTable")
quote   <- rndQuote()
weather <- htmlTable(dataset, rnames = FALSE)
  
email <- send.mail(
  from = "LearningSpoonsR@gmail.com",
  to   = "LearningSpoonsR@gmail.com",
  subject = title,
  body = paste0(quote, weather),
  smtp = list(host.name = "smtp.gmail.com", port = 465,
              user.name = "learningspoonsr",
              passwd = readLines("../../password.txt"),
              ssl = TRUE),
  authenticate = TRUE,
  html = TRUE,
  send = TRUE)

# 6. Task Scheduler
# activate("taskscheduleR")
# Addins - Schedule R scripts on Windows

