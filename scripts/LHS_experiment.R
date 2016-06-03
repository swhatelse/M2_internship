
df <- read.csv("/tmp/test.csv",strip.white=T,header=T)
   
library(DoE.base)
library(DoE.wrapper)

args = commandArgs(trailingOnly=TRUE)
output = args[1]

elements_number_val <- as.numeric(levels(as.factor(df$elements_number)))
y_component_number_val <- as.numeric(levels(as.factor(df$y_component_number)))
vector_length_val <- as.numeric(levels(as.factor(df$vector_length)))
threads_number_val <- as.numeric(levels(as.factor(df$threads_number)))
lws_y_val <- as.numeric(levels(as.factor(df$lws_y)))
temporary_size_val <- as.numeric(levels(as.factor(df$temporary_size)))
load_overlap_val <- levels(df$load_overlap)

df_lhs <- data.frame()
point_count <- c()
runs = 100  
for(j in 1:runs){
    Design.1 <- lhs.design( type= "maximin" , nruns= 441 ,nfactors= 7, randomize=TRUE ,digits= NULL, factor.names=list(idx_elements_number = c(1,length(elements_number_val)), 
                                                                                                                       idx_y_component_number = c(1,length(y_component_number_val)),
                                                                                                                       idx_vector_length = c(1,length(vector_length_val)), 
                                                                                                                       idx_threads_number = c(1,length(threads_number_val)),
                                                                                                                       idx_temporary_size = c(1,length(temporary_size_val)), 
                                                                                                                       idx_lws_y = c(1,length(lws_y_val)), 
                                                                                                                       idx_load_overlap = c(1,length(load_overlap_val)) 
                                                                                                                       ) 
                           )

    Design.1.rounded <- round(Design.1) 

    set <- data.frame()
    for(i in 1:nrow(Design.1.rounded)){
        set <- rbind(set, df[ df$elements_number == elements_number_val[Design.1.rounded$idx_elements_number[i]]
                             & df$y_component_number == y_component_number_val[Design.1.rounded$idx_y_component_number[i]]
                             & df$vector_length == vector_length_val[Design.1.rounded$idx_vector_length[i]]
                             & df$threads_number == threads_number_val[Design.1.rounded$idx_threads_number[i]]
                             & df$lws_y == lws_y_val[Design.1.rounded$idx_lws_y[i]]
                             & df$temporary_size == temporary_size_val[Design.1.rounded$idx_temporary_size[i]]
                             & df$load_overlap == load_overlap_val[Design.1.rounded$idx_load_overlap[i]], ])
    }
    point_count[j] <- nrow(set)
    df_lhs <- rbind(df_lhs, set[set$time_per_pixel==min(set$time_per_pixel) ,])
}
df_lhs <- cbind(df_lhs, point_number=point_count, method=rep("LHS",nrow(df_lhs)))
df_lhs$slowdown <- df_lhs$time_per_pixel / min(df$time_per_pixel) 
write.csv(df_lhs, output, row.names=FALSE)
