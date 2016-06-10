
df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
df_uniform <- data.frame()
for (i in 1:1000){
    s <- df[sample(1:nrow(df), size = 120, replace = FALSE),]
    df_uniform <- rbind(df_uniform, s[s$time_per_pixel==min(s$time_per_pixel) ,])
}

df_uniform <- cbind(df_uniform, point_number=rep(120,nrow(df_uniform)), method=rep("RS",nrow(df_uniform)))
write.csv(df_uniform, "../data/2016_04_08/pilipili2/18_08_24/uniform_search_1000.csv", row.names=FALSE)
