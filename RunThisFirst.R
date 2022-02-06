library(rvest)

# URL from hargapangan.id
# Pasar Tradisional (PT) : https://hargapangan.id/tabel-harga/pasar-tradisional/komoditas
# Pasar Modern (PM) : https://hargapangan.id/tabel-harga/pasar-modern/komoditas
# Pedagang Besar (PB) : https://hargapangan.id/tabel-harga/pedagang-besar/komoditas
# Produsen (PD) : https://hargapangan.id/tabel-harga/produsen/komoditas


# Data from Traditional Market
urlPT <- "https://hargapangan.id/tabel-harga/pasar-tradisional/komoditas"
tabelPT <- read_html(urlPT)
dataPT <- html_table(tabelPT)
dataPT <- dataPT[[1]]

# Data from Modern Market
urlPM <- "https://hargapangan.id/tabel-harga/pasar-modern/komoditas"
tabelPM <- read_html(urlPM)
dataPM <- html_table(tabelPM)
dataPM <- dataPM[[1]]

# Data from Wholesaler
urlPB <- "https://hargapangan.id/tabel-harga/pedagang-besar/komoditas"
tabelPB <- read_html(urlPB)
dataPB <- html_table(tabelPB)
dataPB <- dataPB[[1]]

# Data from Producer
urlPD <- "https://hargapangan.id/tabel-harga/produsen/komoditas"
tabelPD <- read_html(urlPD)
dataPD <- html_table(tabelPD)
dataPD <- dataPD[[1]]

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


# Bind Them All
rapi <-rbind(rapiPT, rapiPM, rapiPB, rapiPD)
colnames(rapi) <- c("no", "provinsi", "date", "price","type")
rapi$no <- 1:nrow(rapi)

# Upload to ElephantSQL

library(RPostgreSQL)

query <- '
CREATE TABLE IF NOT EXISTS beras (
  no integer,
  komoditas character,
  date date,
  price decimal,
  type character,
  PRIMARY KEY (no)
)
'

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname = Sys.getenv("ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("ELEPHANT_SQL_USER"),
                 password = Sys.getenv("ELEPHANT_SQL_PASSWORD")
)

data = rapi

#Upload data
dbWriteTable(conn = con, name = "beras", value = data, append = T, row.names = F)

# Disconnect from DB
on.exit(dbDisconnect(con))  
