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

find_best <- function(model,subset,full_set,colnames){
    fit <- lm(data=subset,formula=formula(model))
    if( length(colnames) > 1) {
        return(full_set[objective_predict(fit,full_set[,colnames]) == min(objective_predict(fit,full_set[,colnames])), colnames][1,])
    }
    else{
        return(full_set[objective_predict_one(fit, full_set[,colnames], colnames) == min(objective_predict_one(fit, full_set[,colnames], colnames)), colnames][1])
    }
}

set.seed(1) 
runs = 100
df_lm_random <- data.frame()
point_count <- c()
logs <- data.frame()
additional_points <- data.frame()

for(i in 1:runs){
    random_set <- df[sample(1:nrow(df), size = 90, replace = FALSE),]
    best_time <- min(random_set$time_per_pixel)
    tmp <- cbind(random_set, run=rep(i,nrow(random_set)))
    logs <- rbind(logs, tmp)
    point_count[i] <- nrow(random_set)
    
    model <- time_per_pixel ~ y_component_number + I(1/y_component_number) + 
        vector_length + 
        lws_y + I(1/lws_y) +
        threads_number + I(1/threads_number)
    
    best_base <- find_best(model, random_set, df, c("y_component_number", "vector_length", "lws_y", "threads_number")) 

    subset <- random_set[random_set$y_component_number == best_base$y_component_number & random_set$vector_length == best_base$vector_length & random_set$threads_number == best_base$threads_number, ]
    pruned_full_space <- df[df$y_component_number == best_base$y_component_number & df$vector_length == best_base$vector_length & df$threads_number == best_base$threads_number, ]
    
###########################################
                                        #
                                        #               Step 1
                                        #
###########################################      
    
    budget <- 20
    if(nrow(subset) < budget ){
        if(nrow(pruned_full_space) <= budget) { 
            budget <-  nrow(pruned_full_space) 
        } 
        tmp2 <- pruned_full_space[sample(1:nrow(pruned_full_space), size = budget, replace = FALSE),]
        subset <- rbind(subset,tmp2)
        additional_points <- rbind(additional_points,cbind(tmp2, run=rep(i,nrow(tmp2)), step=rep(1,nrow(tmp2))))
        point_count[i] <- point_count[i] + budget
    }
    
    if(best_time > min(subset$time_per_pixel)){
        best_time <- min(subset$time_per_pixel)
    }

    model <- time_per_pixel ~ lws_y + I(1/lws_y)
    
    best_lws_y <- find_best(model, subset, pruned_full_space, c("lws_y"))
    
    subset <- subset[subset$lws_y == best_lws_y, ]
    pruned_full_space <- pruned_full_space[pruned_full_space$lws_y == best_lws_y, ]
    
###########################################
                                        #
                                        #               Step 2
                                        #
###########################################      

    if(nrow(subset) < 5 ){
        tmp2 <- pruned_full_space[sample(1:nrow(pruned_full_space), size = 5, replace = FALSE),]
        additional_points <- rbind(additional_points,cbind(tmp2, run=rep(i,nrow(tmp2)), step=rep(2,nrow(tmp2))))
        subset <- rbind(subset,tmp2)
        point_count[i] <- point_count[i] + 5
    }

    if(best_time > min(subset$time_per_pixel)){
        best_time <- min(subset$time_per_pixel)
    }
    
    model <- time_per_pixel ~ elements_number + I(elements_number^2)
    
    best_elements_number <- find_best(model, subset, pruned_full_space, c("elements_number"))

    subset <- subset[subset$elements_number == best_elements_number, ]
    pruned_full_space <- pruned_full_space[pruned_full_space$elements_number == best_elements_number, ]
    
###########################################
                                        #
                                        #               Step 3
                                        #
###########################################      

    if(nrow(subset) < 5 ){
        tmp2 <- pruned_full_space[sample(1:nrow(pruned_full_space), size = nrow(pruned_full_space), replace = FALSE),]
        additional_points <- rbind(additional_points,cbind(tmp2, run=rep(i,nrow(tmp2)), step=rep(3,nrow(tmp2))))
        subset <- rbind(subset,tmp2)
        point_count[i] <- point_count[i] + nrow(pruned_full_space)
    }

    if(best_time > min(subset$time_per_pixel)){
        best_time <- min(subset$time_per_pixel)
    }

    model <- time_per_pixel ~ load_overlap
    
    fit <- lm(data=subset,formula=model)
    
    best_load_overlap <- pruned_full_space[objective_predict_one(fit,pruned_full_space$load_overlap,"load_overlap") == min(objective_predict_one(fit,pruned_full_space$load_overlap,"load_overlap")),][1,]$load_overlap
    best_load_overlap_time <- pruned_full_space[objective_predict_one(fit,pruned_full_space$load_overlap,"load_overlap") == min(objective_predict_one(fit,pruned_full_space$load_overlap,"load_overlap")),][1,]$time_per_pixel
    
    model <- time_per_pixel ~ temporary_size
    
    fit <- lm(data=subset,formula=model)
    
    best_temporary_size <- pruned_full_space[objective_predict_one(fit,pruned_full_space$temporary_size,"temporary_size") == min(objective_predict_one(fit,pruned_full_space$temporary_size,"temporary_size")),][1,]$temporary_size
    best_temporary_size_time <- pruned_full_space[objective_predict_one(fit,pruned_full_space$temporary_size,"temporary_size") == min(objective_predict_one(fit,pruned_full_space$temporary_size,"temporary_size")),][1,]$time_per_pixel
    
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
                         df$vector_length == best_base$threads_number & 
                         df$lws_y == best_lws_y & 
                         df$elements_number == best_elements_number & 
                         df$load_overlap == best_load_overlap,]
        }
        
        if(nrow(subset > 1)){
            subset <- subset[subset$time_per_pixel==min(subset$time_per_pixel),]
        }
    }
    
    subset$run <- i
    df_lm_random <- rbind(df_lm_random, cbind(subset, best=best_time))
}

df_lm_random <- cbind(df_lm_random, point_number=point_count, method=rep("LM",nrow(df_lm_random)))
df_lm_random$slowdown <- df_lm_random$time_per_pixel / min(df$time_per_pixel)
## write.csv(df_lm_random, "../data/2016_04_08/pilipili2/18_08_24/lm_random_new_strat.csv", row.names=FALSE)
## write.csv(logs, "../data/2016_04_08/pilipili2/18_08_24/lm_random_logs_new_strat.csv", row.names=FALSE)
## write.csv(additional_points, "../data/2016_04_08/pilipili2/18_08_24/lm_random_logs_additional_points_new_strat.csv", row.names=FALSE)

library(ggplot2)
        library(plyr)

        df_mean = ddply(df_lm_random,.(method), summarize, 
                        mean = mean(slowdown))

        df_median = ddply(df_lm_random,.(method), summarize, 
                          median = median(slowdown))

        df_err = ddply(df_lm_random,.(method), summarize,
                      mean = mean(slowdown), err = 2*sd(slowdown)/sqrt(length(slowdown)))

        ggplot(df_lm_random) + 
            facet_grid(method~.) +
            theme_bw() +
            geom_histogram(aes(slowdown),binwidth=.05,color="white", fill="gray48") +
            geom_rect(data = df_err, aes(xmin=mean-err, xmax=mean+err, ymin=0, ymax=60, fill="red"), alpha=0.3) +
            geom_vline( aes(xintercept = median), df_median, color="darkgreen", linetype=2 ) +
            geom_vline( aes(xintercept = mean), df_mean, color="red", linetype=2 ) +
            labs(y="Density", x="Slowdown compared best combination of the entire search space") +
            scale_fill_discrete(name="",breaks=c("red"), labels=c("Mean error")) +
            ggtitle("") + 
            theme(legend.position="top") +
            coord_cartesian(xlim=c(.9,3), ylim=c(0,60))
