
df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
df_greedy <- data.frame()
df_greedy_start <- data.frame()
for(k in 1:1000){
    budget <- 120
    solutions <- data.frame()

    p <- df[sample(1:nrow(df), size = 1, replace = FALSE),]
    budget <- budget - 1
    df_greedy_start <- rbind(df_greedy_start,p)
    res <- gradient_descent(p,budget)
    solutions <- rbind(solutions,res[[1]])

    df_greedy <- rbind(df_greedy, solutions[solutions$time_per_pixel == min(solutions$time_per_pixel),])
}
df_greedy <- cbind(df_greedy, method=rep("GR",nrow(df_greedy))) 

write.csv(df_greedy, "../data/2016_04_08/pilipili2/18_08_24/greedy_search_1000.csv", row.names=FALSE)
write.csv(df_greedy_start, "../data/2016_04_08/pilipili2/18_08_24/greedy_search_start_1000.csv", row.names=FALSE)
