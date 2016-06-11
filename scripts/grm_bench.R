
kernel_size <- function(point) {
     vector_number <- ceiling((point$elements_number / point$y_component_number) / point$vector_length)
     
     tempload <- (1 - point$load_overlap) * (vector_number * point$vector_length) / point$vector_length * point$vector_length
     temp <-  point$load_overlap * 3 * vector_number * (point$y_component_number+2) * point$vector_length
     res <- vector_number * point$y_component_number * point$vector_length
     tempc <- 3 * vector_number * (point$y_component_number + 2) * point$temporary_size * point$vector_length
     out_vec = (1 - point$load_overlap) * tempc
     resc <- vector_number * point$y_component_number * point$temporary_size * point$vector_length
     
     tot <- (tempload + temp + res + tempc + out_vec + resc) * point$threads_number
 }

 check_constraint <- function(point){
     res <- if(point$load_overlap %in% 0:1 &
               point$lws_y <= point$threads_number &
               point$elements_number %% point$y_component_number == 0 &
               point$elements_number %/% point$y_component_number <= 4 &
               kernel_size(point) < kernel_size(data.frame(elements_number=6, y_component_number=6, vector_length=8, temporary_size=2, load_overlap=0, threads_number=1024))
               ) T else F
 }

 point_equal <- function(p1,p2){
     res <- if(p1$elements_number == p2$elements_number &
               p1$y_component_number == p2$y_component_number &
               p1$vector_length == p2$vector_length &
               p1$temporary_size == p2$temporary_size &
               p1$load_overlap == p2$load_overlap &
               p1$threads_number == p2$threads_number) T else F
 }

 gradient_descent <- function(point, limit=100){
     elements_number    <- c(1,0,0,0,0,0,0,-1,0,0,0,0,0,0)
     y_component_number <- c(0,1,0,0,0,0,0,0,-1,0,0,0,0,0)
     vector_length      <- c(0,0,1,0,0,0,0,0,0,-1,0,0,0,0)
     temporary_size     <- c(0,0,0,1,0,0,0,0,0,0,-1,0,0,0)
     load_overlap       <- c(0,0,0,0,1,0,0,0,0,0,0,-1,0,0)
     threads_number     <- c(0,0,0,0,0,1,0,0,0,0,0,0,-1,0)
     lws_y              <- c(0,0,0,0,0,0,1,0,0,0,0,0,0,-1)
     
     factors <- list(elements_number = as.numeric(levels(as.factor(df$elements_number))), 
                     y_component_number = as.numeric(levels(as.factor(df$y_component_number))), 
                     vector_length = as.numeric(levels(as.factor(df$vector_length))), 
                     temporary_size = as.numeric(levels(as.factor(df$temporary_size))), 
                     threads_number= as.numeric(levels(as.factor(df$threads_number))), 
                     lws_y= as.numeric(levels(as.factor(df$lws_y)))) 
     
     directions <- data.frame(elements_number, y_component_number, vector_length, temporary_size, load_overlap, threads_number, lws_y)
     count <- 0
     
     repeat{
         old_point <- point
         candidates <- data.frame()
         
         i <- 0
         while( i <= nrow(directions) & count < limit){
             i <- i + 1
             idx_elements_number = match(point$elements_number, factors$elements_number) + directions[i,]$elements_number
             idx_y_component_number = match(point$y_component_number, factors$y_component_number) + directions[i,]$y_component_number
             idx_vector_length = match(point$vector_length, factors$vector_length) + directions[i,]$vector_length
             idx_temporary_size = match(point$temporary_size, factors$temporary_size) + directions[i,]$temporary_size
             idx_threads_number = match(point$threads_number, factors$threads_number) + directions[i,]$threads_number
             idx_lws_y = match(point$lws_y, factors$lws_y) + directions[i,]$lws_y
             
             if(!(idx_elements_number %in% 1:length(levels(as.factor(df$elements_number))))) next
             if(!(idx_y_component_number %in% 1:length(levels(as.factor(df$y_component_number))))) next
             if(!(idx_vector_length %in% 1:length(levels(as.factor(df$vector_length))))) next
             if(!(idx_temporary_size %in% 1:length(levels(as.factor(df$temporary_size))))) next
             if(!(idx_threads_number %in% 1:length(levels(as.factor(df$threads_number))))) next
             if(!(idx_lws_y %in% 1:length(levels(as.factor(df$lws_y))))) next
             
             p <- data.frame(elements_number = factors$elements_number[idx_elements_number],
                             y_component_number = factors$y_component_number[idx_y_component_number],
                             vector_length = factors$vector_length[idx_vector_length],
                             temporary_size = factors$temporary_size[idx_temporary_size],
                             load_overlap = if(point$load_overlap == "true") 1 + directions[i,]$load_overlap else 0 + directions[i,]$load_overlap,
                             threads_number = factors$threads_number[idx_threads_number],
                             lws_y = factors$lws_y[idx_lws_y]
                             )

             
             
             
             
             if(check_constraint(p) == T){
                 p <- df[df$elements_number == p$elements_number & 
                         df$y_component_number == p$y_component_number & 
                         df$vector_length == p$vector_length &
                         df$temporary_size == p$temporary_size &
                         df$load_overlap == (if (p$load_overlap == 0) "false" else "true") &
                                         #df$load_overlap == "true" &
                         df$threads_number == p$threads_number &
                         df$lws_y == p$lws_y,]
                 candidates <- rbind(p, candidates)
                 count <- count + 1
             }
         }

         if(nrow(candidates) > 0){
             if(candidates[candidates$time_per_pixel == min(candidates$time_per_pixel),]$time_per_pixel < point$time_per_pixel){
                 point <- candidates[candidates$time_per_pixel == min(candidates$time_per_pixel),]
             }
         }
         
         if(count >= limit | point_equal(old_point,point) == T){
             break
         }
     }

     result <- list()
     # point <- cbind(point,point_number=count)
     result[[1]] <- point
     result[[2]] <- limit - count
     result
 }

 row_to_coordinate <- function(row){
     drops <- c("time_per_pixel", "vector_recompute")
     row[, !(names(row) %in% drops)]
 }

df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
df_greedy <- data.frame()
df_greedy_start <- data.frame()
for(k in 1:1000){
    budget <- 120
    solutions <- data.frame()
    while(budget > 0){ 
        p <- df[sample(1:nrow(df), size = 1, replace = FALSE),]
        budget <- budget - 1
        df_greedy_start <- rbind(df_greedy_start,p)
        res <- gradient_descent(p,budget)
            solutions <- rbind(solutions,res[[1]])
        budget <- res[[2]]
    }
    sol <- solutions[solutions$time_per_pixel == min(solutions$time_per_pixel),][1,]
    sol$point_number <- 120 - budget
    df_greedy <- rbind(df_greedy, sol)
}
df_greedy <- cbind(df_greedy, method=rep("GRM",nrow(df_greedy))) 

write.csv(df_greedy, "../data/2016_04_08/pilipili2/18_08_24/greedy_search_multiple_1000.csv", row.names=FALSE)
write.csv(df_greedy_start, "../data/2016_04_08/pilipili2/18_08_24/greedy_search_start_multiple_1000.csv", row.names=FALSE)
