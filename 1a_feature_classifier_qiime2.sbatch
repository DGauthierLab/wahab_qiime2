#!/bin/bash -l

#This script will train the feature classifier for use in taxonomy analysis.  
#see: https://docs.qiime2.org/2021.4/tutorials/feature-classifier/ for details
 
#SBATCH --job-name=qiime2_classifier
#SBATCH -o qiime2-%j.out
#SBATCH --time=00:00:00
#SBATCH --cpus-per-task=32

enable_lmod
module load container_env qiime2

#mkdir training_feature_classifiers
#cd training_feature_classifiers

##Download and decompress classifier file (Silva_138)
#wget https://www.arb-silva.de/fileadmin/silva_databases/release_138_1/Exports/taxonomy/tax_slv_ssu_138.1.txt.gz
#gunzip tax_slv_ssu_138.1.txt.gz
#wget https://www.arb-silva.de/fileadmin/silva_databases/release_138_1/Exports/SILVA_138.1_SSURef_NR99_tax_silva.fasta.gz
#gunzip SILVA_138.1_SSURef_NR99_tax_silva.fasta.gz

#crun qiime tools import \
#--type 'FeatureData[Taxonomy]' \
#--input-format HeaderlessTSVTaxonomyFormat \
#--input-path tax_slv_ssu_138.1.txt \
#--output-path slv_ssu_138.1_ref_taxonomy.qza

#crun qiime tools import \
#--type 'FeatureData[Sequence]' \
#--input-path SILVA_138.1_SSURef_NR99_tax_silva.fasta \
#--output-path SILVA_138.1_SSURef_NR99_tax_silva.fasta.qza

#crun qiime rescript get-silva-data \
#--p-version '138.1' \
#--p-target 'SSURef_NR99' \
#--p-include-species-labels \
#--p-download-sequences \
#--o-silva-sequences silva-138.1-ssu-nr99-seqs.qza \
#--o-silva-taxonomy silva-138.1-ssu-nr99-tax.qza

#crun qiime rescript cull-seqs \
#--i-sequences silva-138.1-ssu-nr99-seqs.qza \
#--o-clean-sequences silva-138.1-ssu-nr99-seqs_cleaned.qza

#crun qiime rescript filter-seqs-length-by-taxon \
#--i-sequences silva-138.1-ssu-nr99-seqs_cleaned.qza \
#--i-taxonomy silva-138.1-ssu-nr99-tax.qza \
#--p-labels Archaea Bacteria Eukaryota \
#--p-min-lens 900 1200 1400 \
#--o-filtered-seqs silva-138.1-ssu-nr99-seqs_cleaned_filt.qza \
#--o-discarded-seqs silva-138-ssu-nr99-seqs_discard.qza

#crun qiime rescript dereplicate \
#--i-sequences silva-138.1-ssu-nr99-seqs_cleaned_filt.qza \
#--i-taxa silva-138.1-ssu-nr99-tax.qza \
#--p-rank-handles 'silva' \
#--p-mode 'uniq' \
#--o-dereplicated-sequences silva-138.1-ssu-nr99-seqs_cleaned_filt_derep.qza \
#--o-dereplicated-taxa silva-138.1-ssu-nr99-tax_derep.qza

#Seems not to be necessary if previous steps run.  If no cleaning was done, this is necessary.

#crun qiime rescript reverse-transcribe \
#--i-rna-sequences silva-138.1-ssu-nr99-seqs_cleaned_filt_derep.qza \
#--o-dna-sequences silva-138.1-ssu-nr99-seqs_cleaned_filt_derep_dna.qza

crun qiime feature-classifier extract-reads \
--i-sequences silva-138.1-ssu-nr99-seqs_cleaned_filt_derep.qza \
--p-f-primer CCTACGGGNGGCWGCAG \
--p-r-primer GACTACHVGGGTATCTAATCC \
--p-min-length 350 \
--p-max-length 550 \
--o-reads ref-seqs_silva138_NR99.qza

crun qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads ref-seqs_silva138_NR99.qza \
--i-reference-taxonomy silva-138.1-ssu-nr99-tax_derep.qza \
--o-classifier slv_ssu_138.1_classifier.qza

