
library(ggplot2)
library(reshape2)

####

DATA_AOX <- read.table("raws/AA_XY_filtered.dat")
DATA_WAT <- read.table("raws/WA_XY_filtered.dat")

colnames(DATA_AOX) <- c("name", "frame", "Z")
colnames(DATA_WAT) <- c("name", "frame", "Z")

###Center###
CENTER= read.table("CENT_A.dat")
DATA_AOX$Z <- DATA_AOX$Z - CENTER$V4[match(DATA_AOX$frame, CENTER$V1)]
DATA_WAT$Z <- DATA_WAT$Z - CENTER$V4[match(DATA_WAT$frame, CENTER$V1)]
#####/Center###

H2O2 <- DATA_AOX$Z #[DATA_AOX$Z < 18 & DATA_AOX$Z > -5]; rm(DATA_AOX)
H2O <- DATA_WAT$Z #[DATA_WAT$Z < 18 & DATA_WAT$Z > -5]; rm(DATA_WAT)



H2O2 <- data.frame("Z" = H2O2, "mol" = rep("H2O2", length(H2O2)))
H2O <- data.frame("Z" = H2O, "mol" = rep("H2O", length(H2O)))

####

DATA <- rbind(H2O, H2O2); rm(H2O2); rm(H2O)


My_theme <- theme(plot.title = element_text(hjust = 0.5, size = 22, face = "plain", family = "avenir"),
                  axis.title.x = element_text(size = 20, face = "plain", family = "avenir"),
                  axis.title.y = element_text(size = 20, face = "plain", family = "avenir"),
)



p <- ggplot(DATA, aes(x = Z)) + ylim(0,0.1) #+ xlim(18, -5) 
p <- p + geom_density(aes(fill= mol, color=mol), alpha=0.3, size=0.9, bw=0.2) + theme_classic() + coord_flip() +
  labs(x="Eje principal del poro (Å)", y="Densidad", title = "Cadena Abierta - AtPIP28") +  theme(text=element_text(size=30, face = "bold")) + My_theme 


p <- p + scale_fill_manual(values = c("Thistle", "darkred")) + scale_color_manual(values = c("Thistle", "darkred"))

p


ggsave("Cadena_Abierta_Mt23.png" , p, units="px", height=1920, width=1280, dpi=200)
