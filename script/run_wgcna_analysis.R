# Run WGCNA analysis
library(rmarkdown)

#Default Parameters: 
args <- commandArgs(trailingInly = TRUE)
dataset <- ifelse(length(args) >=1, args[1], "GSE21933")
soft_powr <- ifelse(length(args) >=2, args[2],15)


rmarkdown::render(
  input = "script/GSE21933_analysis.Rmd"
  output_file = past0("../outputs",dataset,"_analysis.html")
  params = list(dataset_name = dataset, soft_power = soft_power)
  envir = new.env()
)
