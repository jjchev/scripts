library(reshape2)
library(ggplot2)
######## Distancia Leu Leu ############## 
for (i in c("A", "B", "C", "D")) {
  assign(paste0("DATA_", i), read.table(paste0("LL",i,".dat")))
}
DATAPLOT <- cbind(DATA_A, DATA_B$V2, DATA_C$V2, DATA_D$V2)
colnames(DATAPLOT) <- c("Time", "A", "B", "C", "D")
Melted <- melt(DATAPLOT, id.vars = c("Time"))
colnames(Melted) <- c("Frame", "Chain", "value")


size <- theme(axis.text.x = element_text(size = 10, face = "bold"),
              axis.text.y = element_text(size = 10, face = "bold"),
              axis.title.x = element_text(size = 15),
              axis.title.y = element_text(size = 15),
              plot.title = element_text(size = 20, hjust = 0.5, family = "Arial")
)


p <- ggplot(Melted, aes(x=Frame*2/10, y=value)) + theme_classic() + size + xlab("Time(ns)") + ylab("Distance(Å)") + ggtitle("Mt23O(500AOX) - Distance L114-L203") + ylim(0,25)
p <- p + geom_line(aes(color=Chain), alpha=0.35)+ geom_smooth(aes(color=Chain), lwd =1.1, position = "identity") + scale_color_manual(values=c("violetred4", "steelblue4", "orange", "green4"))

ggsave("distance.png" , p, units="px", height=1080, width=1920, dpi=200)


######## RMSD LEAST #######

AR <- read.table("rmsdA80.dat")
BR <- read.table("rmsdB80.dat")
CR <- read.table("rmsdC80.dat")
DR <- read.table("rmsdD80.dat")

DATA <- AR
DATA$V3 <- NULL; DATA$V4 <- NULL; 
DATA$B <- BR$V2
DATA$C <- CR$V2
DATA$D <- DR$V2
colnames(DATA) <- c("ns", "A", "B", "C", "D")
DATA$ns <- DATA$ns / 5
Melted <- melt(DATA, id.vars = c("ns"))
colnames(Melted) <- c("ns", "Cadena", "value")


size <- theme(axis.text.x = element_text(size = 10, face = "bold"),
              axis.text.y = element_text(size = 10, face = "bold"),
              axis.title.x = element_text(size = 15),
              axis.title.y = element_text(size = 15),
              plot.title = element_text(size = 20, hjust = 0.5)
              ) 


p <- ggplot(Melted, aes(x=ns, y=value)) + theme_classic() + size + xlab("Tiempo (ns)") + ylab("RMSD(Å)") + ggtitle(expression("Sistema con H"[2]*"O"[2]*" - 80% menos movil"))
p <- p  + geom_line(aes(color=Cadena),alpha=0.35) + geom_smooth(aes(color=Cadena), lwd =1.1, position = "identity") + scale_color_manual(values=c("violetred4", "steelblue4", "orange", "green4")) + ylim(0,2.5)
p
ggsave("w_least.png" , p, units="px", height=1080, width=1920, dpi=200)


######## RMSD MOST #######

DATA <- AR
DATA$V2 <- NULL; DATA$V4 <- NULL; 
DATA$B <- BR$V3
DATA$C <- CR$V3
DATA$D <- DR$V3
colnames(DATA) <- c("ns", "A", "B", "C", "D")
DATA$ns <- DATA$ns / 5
Melted <- melt(DATA, id.vars = c("ns"))
colnames(Melted) <- c("ns", "Cadena", "value")


size <- theme(axis.text.x = element_text(size = 10, face = "bold"),
              axis.text.y = element_text(size = 10, face = "bold"),
              axis.title.x = element_text(size = 15),
              axis.title.y = element_text(size = 15),
              plot.title = element_text(size = 20, hjust = 0.5)
) 


p <- ggplot(Melted, aes(x=ns, y=value)) + theme_classic() + size + xlab("Tiempo (ns)") + ylab("RMSD(Å)") + ggtitle(expression("Sistema con H"[2]*"O"[2]*" - 20% mas movil"))
p <- p  + geom_line(aes(color=Cadena),alpha=0.35) + geom_smooth(aes(color=Cadena), lwd =1.1, position = "identity") + scale_color_manual(values=c("violetred4", "steelblue4", "orange", "green4")) + ylim(0,30)
p
ggsave("w_most.png" , p, units="px", height=1080, width=1920, dpi=200)


######## RMSF #######

ARF <- read.table("rmsfA.dat")
BRF <- read.table("rmsfB.dat")
CRF <- read.table("rmsfC.dat")
DRF <- read.table("rmsfD.dat")

DATA <- ARF
DATA$V3 <- BRF$V2 ; DATA$V4 <- CRF$V2; DATA$V5 <- DRF$V2
colnames(DATA) <- c("Residuo", "A", "B", "C", "D")
Melted <- melt(DATA, id.vars = c("Residuo"))
colnames(Melted) <- c("Residuo", "Cadena", "value")

p <- ggplot(Melted, aes(x=Residuo, y=value)) + theme_classic() + xlab("Residuo") + ylab("RMSF(Å)") + ggtitle(expression("Sistema con 500 H"[2]*"O"[2]*" - RMSF"))
p <- p  + geom_area(aes(fill=Cadena),alpha=0.35, position = "dodge") + scale_color_manual(values=c("violetred4", "steelblue4", "orange", "green4")) #+ ylim(0,30)
p
ggsave("RMSF.png" , p, units="px", height=1080, width=1920, dpi=200)

