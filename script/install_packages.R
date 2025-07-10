# install_packages.R

# Set CRAN mirror explicitly (important in Docker!)
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install BiocManager first
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Set Bioconductor version if needed (optional)
# BiocManager::install(version = "3.18") # Optional: match with R version

# CRAN packages
cran_packages <- c(
  "tidyverse", "ggplot2", "data.table", "readxl", "ggrepel",
  "ggsci", "ggpubr", "knitr", "rmarkdown", "pheatmap"
)

# Bioconductor packages
bioc_packages <- c(
  "DESeq2", "limma", "edgeR", "GEOquery", "org.Hs.eg.db", "WGCNA"
)

# Install CRAN packages
install.packages(cran_packages, dependencies = TRUE)

# Install Bioconductor packages
BiocManager::install(bioc_packages, ask = FALSE, update = FALSE, dependencies = TRUE)

cat("✅ Packages successfully installed and ready to load.\n")