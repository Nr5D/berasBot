library(RPostgreSQL)

query <- '
CREATE TABLE IF NOT EXISTS tugas (
  No integer,
  Karakter character,
  Angka integer,
  PRIMARY KEY (No)
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

# Membuat Tabel untuk Pertama Kalinya
data <- dbGetQuery(con, query)

# Memanggil Tabel, untuk membuat Primary Key nya berurutan.

query2 <- '
SELECT * FROM tugas
'

data <- dbGetQuery(con, query2)
baris <- nrow(data)

data <- data.frame(No = (baris+1):(baris+4),
                   Karakter = c("A","B","C","D"),
                   Angka = round(rnorm(4,1000,10),0))

dbWriteTable(conn = con, name = "tugas", value = data, append = TRUE, row.names = FALSE, overwrite=FALSE)

on.exit(dbDisconnect(con)) 
