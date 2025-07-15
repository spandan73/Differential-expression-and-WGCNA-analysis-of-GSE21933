# Run WGCNA analysis
#setwd("~/WGCNA/script") #Only if you try to execute this form Rstuio in docker. 

library(rmarkdown)

#Default Parameters: 
args <- commandArgs(trailingOnly = TRUE)
dataset <- ifelse(length(args) >= 1, args[1], "GSE21933")
soft_power <- as.numeric(ifelse(length(args) >= 2, args[2], 15))

# Render Markdown
rmarkdown::render(
  input = "GSE21933_analysis.Rmd",
  output_file = paste0("../outputs/", dataset, "_analysis.html"),
  params = list(dataset_name = dataset, soft_power = soft_power),
  envir = new.env()
)

cat("Output created go to the Output folder","\n")
cat("Make sure you push your changes to to github at the end of the day")
