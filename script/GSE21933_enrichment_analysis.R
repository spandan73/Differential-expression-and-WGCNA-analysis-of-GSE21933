
# Core Bioconductor packages
# if (!requireNamespace("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# 
# # Install enrichment packages
# BiocManager::install(c(
#   "clusterProfiler",
#   "org.Hs.eg.db",
#   "ReactomePA",
#   "enrichplot",
#   "DOSE",
#   "AnnotationHub()"
# ))

library(tidyverse)
library(clusterProfiler)
library(org.Hs.eg.db)
library(ReactomePA)
library(enrichplot)
library(DOSE)
library(AnnotationDbi)
library(AnnotationHub)
library(gridExtra)
library(HGNChelper)

# Get all hub_*.txt files from the output folder
module_files <- list.files("../outputs", pattern = "^hub_.*\\.txt$", full.names = TRUE)


# Extract module names from filenames
module_names <- gsub("hub_(.*)\\.txt", "\\1", basename(module_files))

# Read gene lists into a named list
gene_lists <- setNames(lapply(module_files, read_lines), module_names)
gene_lists$universe <- read_lines(file = "../outputs/universe_WGCNA.txt")

#function
gene_list_transfer <- function(gene_lists) {
  conversion_log <- list()  # logs
  entrez_lists <- list()    # Entrez IDs
  
  for (mod in names(gene_lists)) {
    genes <- trimws(gene_lists[[mod]])  # remove leading/trailing spaces
    
    # Detect Ensembl IDs vs Symbols
    is_ensembl <- grepl("^ENSG", genes)
    genes_ensembl <- unique(genes[is_ensembl])
    genes_symbol  <- unique(genes[!is_ensembl])
    
    # Clean symbols: remove internal spaces and convert to uppercase
    genes_symbol_clean <- toupper(gsub(" ", "", genes_symbol))
    
    # Map Ensembl IDs directly to Entrez
    ensembl2entrez <- mapIds(org.Hs.eg.db,
                             keys = genes_ensembl,
                             column = "ENTREZID",
                             keytype = "ENSEMBL",
                             multiVals = "first")
    
    # Map cleaned symbols to Entrez (official SYMBOL)
    symbol2entrez <- mapIds(org.Hs.eg.db,
                            keys = genes_symbol_clean,
                            column = "ENTREZID",
                            keytype = "SYMBOL",
                            multiVals = "first")
    
    # Map cleaned symbols to Entrez using ALIAS
    alias2entrez <- mapIds(org.Hs.eg.db,
                           keys = genes_symbol_clean,
                           column = "ENTREZID",
                           keytype = "ALIAS",
                           multiVals = "first")
    
    # Combine all mappings and remove NAs
    entrez_ids_all <- unique(na.omit(c(ensembl2entrez, symbol2entrez, alias2entrez)))
    
    # Log unmapped genes
    unmapped_ensembl <- genes_ensembl[is.na(ensembl2entrez)]
    unmapped_symbols <- genes_symbol[is.na(symbol2entrez) & is.na(alias2entrez)]
    
    # Save Entrez IDs for this module
    entrez_lists[[mod]] <- entrez_ids_all
    
    # Log info
    conversion_log[[mod]] <- list(
      total_input = length(genes),
      unmapped_ensembl = unmapped_ensembl,
      n_unmapped_ensembl = length(unmapped_ensembl),
      unmapped_symbols = unmapped_symbols,
      n_unmapped_symbols = length(unmapped_symbols),
      n_mapped_entrez = length(entrez_ids_all)
    )
  }
  
  return(list(
    entrez_lists = entrez_lists,
    conversion_log = conversion_log
  ))
}
# Run enrichment
run_enrichment_all <- function(entrez_lists, universe) {
  enrichment_results <- lapply(names(entrez_lists), function(mod) {
    genes <- na.omit(entrez_lists[[mod]])
    
    list(
      BP      = enrichGO(gene = genes, universe = universe, OrgDb = org.Hs.eg.db,
                         keyType = "ENTREZID", ont = "BP", pAdjustMethod = "BH",
                         pvalueCutoff = 0.05, readable = TRUE),
      MF      = enrichGO(gene = genes, universe = universe, OrgDb = org.Hs.eg.db,
                         keyType = "ENTREZID", ont = "MF", pAdjustMethod = "BH",
                         pvalueCutoff = 0.05, readable = TRUE),
      CC      = enrichGO(gene = genes, universe = universe, OrgDb = org.Hs.eg.db,
                         keyType = "ENTREZID", ont = "CC", pAdjustMethod = "BH",
                         pvalueCutoff = 0.05, readable = TRUE),
      KEGG    = enrichKEGG(gene = genes, universe = universe, organism = "hsa",
                           pAdjustMethod = "BH", pvalueCutoff = 0.05),
      Reactome = enrichPathway(gene = genes, universe = universe,
                               organism = "human", pvalueCutoff = 0.05,
                               pAdjustMethod = "BH", readable = TRUE)
    )
  })
  
  names(enrichment_results) <- names(entrez_lists)
  return(enrichment_results)
}


get <- gene_list_transfer(gene_lists = gene_lists)

unmapped_entrez_universe<- c(get$conversion_log$universe$unmapped_ensembl,get$conversion_log$universe$unmapped_symbols)
get <- get$entrez_lists
get_universe <- get$universe
get <- get[1:15]


all_results <- run_enrichment_all(get, get_universe)

for (module_name in names(all_results)) {
  enrichment_list <- all_results[[module_name]]
  
  for (enrich_type in names(enrichment_list)) {
    enrich_obj <- enrichment_list[[enrich_type]]
    
    # Skip if no significant results
    if (is.null(enrich_obj) || nrow(as.data.frame(enrich_obj)) == 0) next
    
    # Custom ggplot
    df <- as.data.frame(enrich_obj)
    p1 <- ggplot(df, aes(x = FoldEnrichment, y = reorder(Description, FoldEnrichment))) +
      geom_point(aes(size = Count, color = -log10(p.adjust))) +
      labs(title = paste0(enrich_type, " Enrichment - ", module_name),
           x = "Fold Enrichment", y = paste0(enrich_type, " Term"),
           color = "-log10(adj p-value)", size = "Gene Count") +
      theme_minimal()
    
    # clusterProfiler dotplot
    p2 <- dotplot(enrich_obj) + ggtitle(paste0(enrich_type, " Dotplot - ", module_name))
    
    # Arrange side by side
    p <- grid.arrange(p1, p2, ncol = 2)
    
    # Save
    ggsave(filename = paste0("../figures/Enrichment_", enrich_type, "_", module_name, ".png"),
           plot = p, width = 20, height = 20, dpi = 600)
  }
}
