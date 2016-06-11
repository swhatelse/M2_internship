
f <- function(x) { x * (0.05 - 1 * (x < 0)) }
g <- function(x) { f(x)/x^2 }
h <- function(x) {pmin(g(x),1e15)}

 objective_predict <- function(fit,x){
     names <- colnames(x)
     s <- paste("values <-data.frame(", paste(paste(names,names,sep="=x$"),collapse=","), ")")
     eval(parse(text=s))
     as.numeric(predict(fit, values, interval="none"))
 }

 objective_predict_one <- function(fit,x,colname){
     s <- paste("values <-data.frame(", paste(paste(colname,"=x",sep=""),collapse=","), ")")
     eval(parse(text=s))
     as.numeric(predict(fit, values, interval="none"))
 }

 find_best <- function(fit,full_set,colnames){         
     if( length(colnames) > 1) {
         return(full_set[objective_predict(fit,full_set[,colnames]) == min(objective_predict(fit,full_set[,colnames])), colnames][1,])
     }
     else{
         return(full_set[objective_predict_one(fit, full_set[,colnames], colnames) == min(objective_predict_one(fit, full_set[,colnames], colnames)), colnames][1])
     }
 }

 df_rq_random <- data.frame()
 df <- read.csv("/tmp/test.csv",strip.white=T,header=T)

 runs <- 1000
 logs <- list()
 for(i in 1:runs){
     l <- list()

     # Step 1
     working_set <- df[sample(1:nrow(df), size = 50, replace = FALSE),]
     l[["starting_set"]] <- working_set
     point_count <- 50

    model <- time_per_pixel ~ vector_length + lws_y 
    fit <- lm(data=working_set,formula=formula(model), na.action="na.exclude")
    for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=working_set,formula=formula(model),weights=h(E), na.action="na.exclude")
    }
    best1 <- find_best(fit, df, c("vector_length", "lws_y")) 

     # Pruning the working set and the search space
     subset1 <- working_set[working_set$vector_length == best1$vector_length & 
                            working_set$lws_y == best1$lws_y,]

     pruned1 <- df[df$vector_length == best1$vector_length & 
                   df$lws_y == best1$lws_y,]

     # Step 2          
     # Adding new points
     added1 <- pruned1[sample(1:nrow(pruned1), size = 40, replace = FALSE),]
     l[["added1"]] <- added1
     subset1 <- subset1[, !names(working_set) %in% c("run") ] 
     subset1 <- rbind(subset1, added1)     
     point_count <- point_count + 40

     model <- time_per_pixel ~ y_component_number
    fit <- lm(data=subset1,formula=formula(model), na.action="na.exclude")
    for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=subset1,formula=formula(model),weights=h(E), na.action="na.exclude")
    }
     best2 <- data.frame()
     best2 <- find_best(fit, pruned1, c("y_component_number")) 

     subset2 <- subset1[subset1$y_component_number == best2,]
     pruned2 <- pruned1[pruned1$y_component_number == best2,]

     # Step 3
     added2 <- pruned2[sample(1:nrow(pruned2), size = 20, replace = FALSE),]
     l[["added2"]] <- added2
     subset2 <- rbind(subset2, added2)   
     point_count <- point_count + 20  

     model <- time_per_pixel ~ elements_number 
     fit <- lm(data=subset2,formula=formula(model), na.action="na.exclude")
     for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=subset2,formula=formula(model),weights=h(E), na.action="na.exclude")
     }
     best3 <- data.frame()
     best3 <- find_best(fit, pruned2, c("elements_number")) 
     best3    

     subset3 <- subset2[subset2$elements_number == best3,]
     pruned3 <- pruned2[pruned2$elements_number == best3,]

     # Step 4
     added3 <- pruned3[sample(1:nrow(pruned3), size = 5, replace = FALSE),]
     l[["added3"]] <- added3
     subset3 <- rbind(subset3, added3)     
     point_count <- point_count + 5  

     model <- time_per_pixel ~ threads_number + I(1/threads_number)
     fit <- lm(data=subset3,formula=formula(model), na.action="na.exclude")
     for(j in 1:50){
        E <- residuals(fit)
        fit <- lm(data=subset3,formula=formula(model),weights=h(E), na.action="na.exclude")
     }
     best4 <- data.frame()
     best4 <- find_best(fit, pruned3, c("threads_number")) 
     best4   

     subset4 <- subset3[subset3$threads_number == best4,]
     pruned4 <- pruned3[pruned3$threads_number == best4,]

     nrow(subset4)
     nrow(pruned4)
     min(pruned4$time_per_pixel) / min(df$time_per_pixel) 

     added4 <- pruned4[sample(1:nrow(pruned4), size = nrow(pruned4), replace = FALSE),]
     point_count <- point_count + nrow(pruned4)  
     l[["added4"]] <- added4
     subset4 <- rbind(subset4, added4)
     solution <- subset4[subset4$time_per_pixel == min(subset4$time_per_pixel),][1,]
     solution$time_per_pixel / min(df$time_per_pixel)
     solution$point_number <- point_count 

     l[["solution"]] <- solution
     l[["slowdown"]] <- solution$time_per_pixel / min(df$time_per_pixel)
     logs[[i]] <- l    

     df_rq_random <- rbind(df_rq_random,solution)
 }

 df_rq_random <- cbind(df_rq_random, method=rep("RQ",nrow(df_rq_random)))
 summary(df_rq_random)

 write.csv(df_rq_random, "../data/2016_04_08/pilipili2/18_08_24/rq_random_new_strat_1000.csv", row.names=FALSE)
 saveRDS(logs, "../data/2016_04_08/pilipili2/18_08_24/rq_random_logs_new_strat_1000.rds")
 summary(df_rq_random)
