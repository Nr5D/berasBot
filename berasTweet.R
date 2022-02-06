# Read Data from ElephantSQL
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

# Status Message
## Looking for the Latest Data to Make Status Message

library(dplyr)
data <- df %>% 
  filter(as.Date(date, "%d/%m/%Y") == max(as.Date(df$date, "%d/%m/%Y")))

baris <- c(1:nrow(data))
terpilih <- sample(baris, 1)

dataSiap <- data %>%
  filter(provinsi == data$provinsi[terpilih]) %>%
  mutate(price = formatC(as.numeric(price)*1000, format="d", big.mark=".", decimal.mark=","))

# Hashtag

## 1st Hashtag
hashtag <- c("pangan","hargaPangan","hargaPanganIndonesia","hargaHarian","pasarTradisional","pasarModern","pedagangBesar","produsen",
             "github","rvest","rtweet", "ElephantSQL", "SQL", "bot", "opensource", "ggplot2","PostgreSQL","RPostgreSQL")

samp_word <- sample(hashtag, 1)

## 2nd Hashtag
namaprov <- dataSiap$provinsi[1]

# Build the status message (text and price)

status_details <- paste0(
  dataSiap$date[1],": Harga beras di Provinsi ", dataSiap$provinsi[1],
  " di :", "\n","\n",
  "⛺ ",dataSiap$type[1], " : Rp",dataSiap$price[1],",-", "\n",
  "🏪 ",dataSiap$type[2], " : Rp",dataSiap$price[2],",-", "\n",
  "🎪 ",dataSiap$type[3], " : Rp",dataSiap$price[3],",-", "\n",
  "👨🏻‍🌾 ",dataSiap$type[4], " : Rp",dataSiap$price[4],",-", "\n",
  "\n",
  "\n",
  "#",samp_word, " #beras #hargaberas #", paste(gsub(" ", "", namaprov, fixed = TRUE)))


# Create Time Series Plot
## Data Preparation
dataPlot <- df %>%
  group_by(date) %>%
  filter(provinsi == data$provinsi[terpilih]) %>%
  mutate(date = as.Date(date, "%d/%m/%Y")) %>%
  mutate(price = as.numeric(price)*1000) %>%
  na.omit()

## ggplot2
library(ggplot2)
p <- ggplot(dataPlot,aes(x=date,y=price,colour=type,group=type)) +
  geom_line(size = 3)+
  geom_point(size = 6)+
  xlab(dataPlot$provinsi[1])+
  ylab("Harga")+
  labs(color='Sumber Data')+
  scale_y_continuous(labels = function(x) paste0("Rp", x,",-" )) +
  theme_light()

# Download the image to a temporary location
# save to a temp file
file <- tempfile( fileext = ".png")
ggsave(file, plot = p, device = "png", dpi = 144, width = 8, height = 8, units = "in" )


# Publish to Twitter
library(rtweet)

## Create Twitter token
pangan_token <- rtweet::create_token(
  app = "PanganBOT",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

## Post the image to Twitter
rtweet::post_tweet(
  status = status_details,
  media = file,
  token = pangan_token
)

on.exit(dbDisconnect(con))
