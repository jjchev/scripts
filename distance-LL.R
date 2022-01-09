
library(reshape2)
library(ggplot2)


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


p <- ggplot(Melted, aes(x=Frame*2/10, y=value)) + theme_classic() + size + xlab("Time(ns)") + ylab("Distance(Å)") + ggtitle("Distance L114-L203") + ylim(0,25)
p <- p + geom_line(aes(color=Chain), alpha=0.35)+ geom_smooth(aes(color=Chain), lwd =1.1, position = "identity") + scale_color_manual(values=c("violetred4", "steelblue4", "orange", "green4"))

ggsave("distance.png" , p, units="px", height=1080, width=1920, dpi=200)
