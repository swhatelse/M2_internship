
#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
output = args[1]

df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
df_uniform <- data.frame()
for (i in 1:100){
    s <- df[sample(1:nrow(df), size = 120, replace = FALSE),]
    df_uniform <- rbind(df_uniform, s[s$time_per_pixel==min(s$time_per_pixel) ,])
}

df_uniform <- cbind(df_uniform, point_number=rep(120,100), method=rep("RS",nrow(df_uniform)))
df_uniform$slowdown <- df_uniform$time_per_pixel / min(df$time_per_pixel)
write.csv(df_uniform, output, row.names=FALSE)
