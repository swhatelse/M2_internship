
args = commandArgs(trailingOnly=TRUE)
output = args[1]
df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
f <- function(x) { x * (0.05 - 1 * (x < 0)) }
g <- function(x) { f(x)/x^2 }
h <- function(x) {pmin(g(x),1e15)}
runs = 100
df_rq_random <- data.frame()
point_count = c()
for(i in 1:runs){
    point_count[i] = 105
    random_set <- df[sample(1:nrow(df), size = 105, replace = FALSE),]
    model <- time_per_pixel ~ y_component_number + I(1/y_component_number) + 
        vector_length + 
        lws_y + I(1/lws_y) +
        threads_number + I(1/threads_number)
    
    fit <- lm(data=random_set,formula=formula(model), na.action="na.exclude")
    for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=random_set,formula=formula(model),weights=h(E), na.action="na.exclude")
    }
    
    pred <- function(x){
        as.numeric(predict(fit,data.frame(y_component_number=x$y_component_number, 
                                          vector_length=x$vector_length, 
                                          threads_number=x$threads_number,
                                          lws_y=x$lws_y,
                                          interval="none")))
    }
    
    best_base <- df[pred(df[,c(2,3,7,8)]) == min(pred(df[,c(2,3,7,8)])), c(2,3,7,8)][1,]
    
    subset <- random_set[random_set$y_component_number == best_base$y_component_number & random_set$vector_length == best_base$vector_length & random_set$threads_number == best_base$threads_number, ]
    pruned_full_space <- df[df$y_component_number == best_base$y_component_number & df$vector_length == best_base$vector_length & df$threads_number == best_base$threads_number, ]
    
###########################################
    
    if(nrow(subset) < 5 ){
        point_count[i] = point_count[i] + 5
        subset <- rbind(subset,pruned_full_space[sample(1:nrow(pruned_full_space), size = 5, replace = FALSE),])
    }
    
    model <- time_per_pixel ~ lws_y + I(1/lws_y)
    
    fit <- lm(data=subset,formula=model, na.action="na.exclude")
    for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=subset,formula=model,weights=h(E), na.action="na.exclude")
    }
    
    
    pred <- function(x){
        as.numeric(predict(fit,data.frame(lws_y=x, interval="none")))
    }
    
    best_lws_y <- pruned_full_space[pred(pruned_full_space$lws_y) == min(pred(pruned_full_space$lws_y)),][1,]$lws_y
    
    subset <- subset[subset$lws_y == best_lws_y, ]
    pruned_full_space <- pruned_full_space[pruned_full_space$lws_y == best_lws_y, ]
    
###########################################
    
    if(nrow(subset) < 5 ){
        point_count[i] = point_count[i] + 5
        subset <- rbind(subset,pruned_full_space[sample(1:nrow(pruned_full_space), size = 5, replace = FALSE),])
    }
    
    model <- time_per_pixel ~ elements_number + I(elements_number^2)
    
    fit <- lm(data=subset,formula=model, na.action="na.exclude")
    for(j in 1:100){
        E <- residuals(fit)
        fit <- lm(data=subset,formula=model,weights=h(E), na.action="na.exclude")
    }
    
    pred <- function(x){
        as.numeric(predict(fit,data.frame(elements_number=x, interval="none")))
    }
    
    best_elements_number <- pruned_full_space[pred(pruned_full_space$elements_number) == min(pred(pruned_full_space$elements_number)),][1,]$elements_number
    
    subset <- subset[subset$elements_number == best_elements_number, ]
    pruned_full_space <- pruned_full_space[pruned_full_space$elements_number == best_elements_number, ]
    
###########################################
    
    if(nrow(subset) < 5 ){
        point_count[i] = point_count[i] + nrow(pruned_full_space)
        subset <- rbind(subset,pruned_full_space[sample(1:nrow(pruned_full_space), size = nrow(pruned_full_space), replace = FALSE),])
    }
    
    model <- time_per_pixel ~ load_overlap
    
    fit <- lm(data=subset,formula=model, na.action="na.exclude")
    for(j in 1:10){
        E <- residuals(fit)
        fit <- lm(data=subset,formula=model,weights=h(E), na.action="na.exclude")
    }
    
    pred <- function(x){
        as.numeric(predict(fit,data.frame(load_overlap=x, interval="none")))
    }
    
    best_load_overlap <- pruned_full_space[pred(pruned_full_space$load_overlap) == min(pred(pruned_full_space$load_overlap)),][1,]$load_overlap
    best_load_overlap_time <- pruned_full_space[pred(pruned_full_space$load_overlap) == min(pred(pruned_full_space$load_overlap)),][1,]$time_per_pixel
    
    model <- time_per_pixel ~ temporary_size
    
    fit <- lm(data=subset,formula=model, na.action="na.exclude")
    for(j in 1:10){
        E <- residuals(fit)
        fit <- lm(data=subset,formula=model,weights=h(E), na.action="na.exclude")
    }
    
    pred <- function(x){
        as.numeric(predict(fit,data.frame(temporary_size=x, interval="none")))
    }
    
    best_temporary_size <- pruned_full_space[pred(pruned_full_space$temporary_size) == min(pred(pruned_full_space$temporary_size)),][1,]$temporary_size
    best_temporary_size_time <- pruned_full_space[pred(pruned_full_space$temporary_size) == min(pred(pruned_full_space$temporary_size)),][1,]$time_per_pixel
    
    subset <- df[df$y_component_number == best_base$y_component_number & 
                 df$vector_length == best_base$vector_length & 
                 df$threads_number == best_base$threads_number & 
                 df$lws_y == best_lws_y & 
                 df$elements_number == best_elements_number & 
                 df$load_overlap == best_load_overlap & 
                 df$temporary_size == best_temporary_size,]
    
    if(nrow(subset) < 1){
        if(best_temporary_size_time < best_load_overlap_time){
            subset <- df[df$y_component_number == best_base$y_component_number & 
                         df$vector_length == best_base$vector_length & 
                         df$threads_number == best_base$threads_number & 
                         df$lws_y == best_lws_y & 
                         df$elements_number == best_elements_number & 
                         df$temporary_size == best_temporary_size,]
        } else {
            subset <- df[df$y_component_number == best_base$y_component_number & 
                         df$vector_length == best_base$vector_length & 
                         df$threads_number == best_base$threads_number & 
                         df$lws_y == best_lws_y & 
                         df$elements_number == best_elements_number & 
                         df$load_overlap == best_load_overlap,]
        }
        
        if(nrow(subset > 1)){
            
        }
    }
    
    df_rq_random <- rbind(df_rq_random, subset)
}

df_rq_random <- cbind(df_rq_random, point_number=point_count, method=rep("RQ",nrow(df_rq_random)))
df_rq_random$slowdown <- df_rq_random$time_per_pixel / min(df$time_per_pixel) 
write.csv(df_rq_random, output, row.names=FALSE)
