setwd("./raws")
CENTA <- read.table("../CENTER.dat")[-c(1,5:7)]; colnames(CENTA) <- c("x","y","z")
FILES <- list.files(pattern="WA_dipo_")
DATA <- data.frame(matrix(ncol = 3, nrow = 0))
colnames(DATA) <- c("name", "frame", "Z")
y=0

for (ARCHIVO in FILES){
  y=y+1
  
  
  
  print(paste0(ARCHIVO, " restantes: ", length(FILES) - y ))
  
  #if(y==10){break}
  
  filt_Z <- c(); filt_frame<-c(); filt_name <- c()
  temp <- read.table(ARCHIVO)[-c(2:4,8)]; colnames(temp) <- c("frame","x","y","z")
  temp$x <- temp$x - CENTA$x; temp$y <- temp$y - CENTA$y
  filt_Z <- temp$z[(  (temp$x^2)+(temp$y^2)  ) < 32 ]
  filt_frame <- temp$frame[(  (temp$x^2)+(temp$y^2)  ) < 32 ]
  filt_name <- gsub("_dipo_", "", ARCHIVO); filt_name <- rep(filt_name, length(filt_frame))
  TAB_DATA <- data.frame(filt_name, filt_frame, filt_Z)
  DATA <- rbind(DATA,TAB_DATA)
  
}

write.table(DATA, "WA_XY_filtered.dat", col.names = FALSE, row.names = FALSE )