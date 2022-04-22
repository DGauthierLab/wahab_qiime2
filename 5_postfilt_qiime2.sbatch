#!/bin/bash -l

#This script is designed to perform post-filtration analyses 
#Sections are intended to be run sequentially, and should be commented out as needed

#SBATCH --job-name=qiime2_postfilt
#SBATCH -o qiime2_postfilt-%j.out
#SBATCH --time=00:00:00
#SBATCH --cpus-per-task=32

enable_lmod
module load container_env qiime2

##SET metadata path, filtering conditions (must match filter_coremetrics script)

METAPATH=/cm/shared/courses/gauthier/Microbiome/metadata/metadata_19_21b.txt
FILTCOV=10000
FILTMETA=nocontrol_wild_noSI
FILTTAX=allassigned

##SET metadata column for beta comparisons

BETACOMPVAR=Rp_status

##SET diversity measure

DMALPHA=shannon
DMBETA=bray_curtis

##SET taxonomic level at which to collapse (optional)
#1-Kingdom, 2-Phylum, 3-Class, 4-Order, 5-Family, 6-Genus, 7-Species (no collapse)

COLV=5

##AUTOSET, Don't change
if [ -z $FILTCOV ]
then
echo "coverage filter not specified"
else
FILTCOV=_$FILTCOV
fi

if [ -z $FILTMETA ]
then
echo "metadata filter not specified"
else
FILTMETA=_$FILTMETA
fi

if [ -z $FILTTAX ]
then
echo "taxonomy filter not specified"
else
FILTTAX=_$FILTTAX
fi

COREMETRICS=core-metrics-results${FILTTAX}${FILTCOV}${FILTMETA}

##RUNSCRIPTS, don't change

crun qiime diversity alpha-group-significance \
  --i-alpha-diversity ${COREMETRICS}/${DMALPHA}_vector${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --m-metadata-file $METAPATH \
  --o-visualization ${COREMETRICS}/${DMALPHA}-group-significance${FILTTAX}${FILTCOV}${FILTMETA}.qzv

##Beta group significance comparisons
#Performs both permdisp routine for dispersion analysis and permanova for centroids

crun qiime diversity beta-group-significance \
  --i-distance-matrix ${COREMETRICS}/${DMBETA}_distance_matrix${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --m-metadata-file $METAPATH \
  --m-metadata-column ${BETACOMPVAR} \
  --p-method 'permdisp' \
  --o-visualization ${COREMETRICS}/${DMBETA}-significance_permdisp_${BETACOMPVAR}${FILTTAX}${FILTCOV}${FILTMETA}.qzv \
  --p-pairwise

crun qiime diversity beta-group-significance \
  --i-distance-matrix ${COREMETRICS}/${DMBETA}_distance_matrix${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --m-metadata-file $METAPATH \
  --m-metadata-column ${BETACOMPVAR} \
  --p-method 'permanova' \
  --o-visualization ${COREMETRICS}/${DMBETA}-significance_permanova_${BETACOMPVAR}${FILTTAX}${FILTCOV}${FILTMETA}.qzv \
  --p-pairwise

##Adonis script: allows multifactorial PERMANOVA

crun qiime diversity adonis \
  --i-distance-matrix ${COREMETRICS}/${DMBETA}_distance_matrix${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --m-metadata-file $METAPATH \
  --p-formula Location*Rp_status \
  --p-permutations 999 \
  --o-visualization ${COREMETRICS}/${DMBETA}-significance_adonis_Loc_Rp${FILTTAX}${FILTCOV}${FILTMETA}.qzv 

