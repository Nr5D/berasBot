library(rvest)

# URL from hargapangan.ID
# Pasar Tradisional (PT) : https://hargapangan.id/tabel-harga/pasar-tradisional/komoditas
# Pasar Modern (PM) : https://hargapangan.id/tabel-harga/pasar-modern/komoditas
# Pedagang Besar (PB) : https://hargapangan.id/tabel-harga/pedagang-besar/komoditas
# Produsen (PD) : https://hargapangan.id/tabel-harga/produsen/komoditas

# Latest Price Data from Traditional Market

urlPT <- "https://hargapangan.id/tabel-harga/pasar-tradisional/komoditas"
tabelPT <- read_html(urlPT)
dataPT <- html_table(tabelPT)
dataPT <- dataPT[[1]][,c(1,2,8)]

# Data from Modern Market

urlPM <- "https://hargapangan.id/tabel-harga/pasar-modern/komoditas"
tabelPM <- read_html(urlPM)
dataPM <- html_table(tabelPM)
dataPM <- dataPM[[1]][,c(1,2,8)]

# Data from Wholesaler

urlPB <- "https://hargapangan.id/tabel-harga/pedagang-besar/komoditas"
tabelPB <- read_html(urlPB)
dataPB <- html_table(tabelPB)
dataPB <- dataPB[[1]][,c(1,2,8)]

# Data from Producer

urlPD <- "https://hargapangan.id/tabel-harga/produsen/komoditas"
tabelPD <- read_html(urlPD)
dataPD <- html_table(tabelPD)
dataPD <- dataPD[[1]][,c(1,2,8)]

# Make it Tidy
library(tidyr)

# Traditional Market
rapiPT <- gather(dataPT, "date","price", -'Provinsi (Rp)', -'No.')
rapiPT$type <- rep("Pasar Tradisional", nrow(rapiPT))

# Modern Market
rapiPM <- gather(dataPM, "date","price", -'Provinsi (Rp)', -'No.')
rapiPM$type <- rep("Pasar Modern", nrow(rapiPM))

# Wholesaler
rapiPB <- gather(dataPB, "date","price", -'Provinsi (Rp)', -'No.')
rapiPB$type <- rep("Pedagang Besar", nrow(rapiPB))

# Producer
rapiPD <- gather(dataPD, "date","price", -'Provinsi (Rp)', -'No.')
rapiPD$type <- rep("Produsen", nrow(rapiPD))

# Read Data from Elephant SQL
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv,
                 dbname = Sys.getenv("ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("ELEPHANT_SQL_USER"),
                 password = Sys.getenv("ELEPHANT_SQL_PASSWORD")
)

df <- dbGetQuery(con, statement = paste("SELECT * FROM beras"))


# Bind Them All
rapi <-rbind(rapiPT, rapiPM, rapiPB, rapiPD)
colnames(rapi) <- c("no", "provinsi", "date", "price","type")
rapi$no <- (nrow(df)+1):(nrow(df)+nrow(rapi))

# Upload Data

## To compare date, from previously saved data in database (d1), and date from fresh harvested data using rvest (d2)
d1 <- strptime(df$date[nrow(df)], "%d/%m/%Y")
d2 <- strptime(rapi$date[nrow(rapi)], "%d/%m/%Y")

## If d1 and d2 different, this script will send the fresh harvested data to Elephant SQL
if (! d1==d2) {
  dbWriteTable(conn = con, name = "pangan", value = rapi, append = T, row.names = F)
}

on.exit(dbDisconnect(con))   
