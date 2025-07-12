


# install_packages.R

# Set CRAN mirror explicitly (important in Docker!)
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Make sure R_LIBS_USER exists and set as library path
user_lib <- Sys.getenv("R_LIBS_USER")
dir.create(user_lib, showWarnings = FALSE, recursive = TRUE)
.libPaths(user_lib)

# Install BiocManager
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", lib = user_lib)
}

# CRAN packages
cran_packages <- c("pheatmap","ggplot2","ggrepel","tidyr","tidyverse","stats","ggsci","rmarkdown","knitr","ggpubr")

# Bioconductor packages
bioc_packages <- c("WGCNA","DESeq2","limma","edgeR","GEOquery","org.Hs.eg.db")

# Install CRAN packages to user lib
install.packages(cran_packages, lib = user_lib, dependencies = TRUE)

# Install Bioconductor packages to user lib
BiocManager::install(bioc_packages, lib = user_lib, ask = FALSE, update = FALSE, dependencies = TRUE)

cat("Packages successfully installed into", user_lib, "\n")
