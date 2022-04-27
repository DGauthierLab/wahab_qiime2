#!/bin/bash -l

#This script is designed to create a subset of a larger dataset and run typical qiime2 pipeline operations
#An additional module is included for taxonomic-based filtering
#Sections are intended to be run sequentially, and should be commented out as needed

#SBATCH --job-name=qiime2_filt_coremetric
#SBATCH -o qiime2_filtcore-%j.out
#SBATCH --time=00:00:00
#SBATCH --cpus-per-task=32

enable_lmod
module load container_env qiime2

##SET metadata path
METAPATH=metadata/metadata_19_21b.txt


##SET taxonomy filter (also provide appropriate --p-include or --p-exclude statement below)
FILTTAX=allassigned

##SET coverage (provide full number; populates below)
FILTCOV=10000

##SET metadata filter descriptive string (also provide appropriate --p-where statement below)
FILTMETA=nocontrol_wild_noSI

###NOTE: leave variables blank if not using

##Don't change
if [ -z $FILTTAX ]
        then
                echo "taxonomic filter not specified"
        else
                FILTTAX=_$FILTTAX
                crun qiime taxa filter-table \
                  --i-table table.qza \
                  --i-taxonomy taxonomy.qza \
                  --p-exclude "unassigned" \
                  --o-filtered-table table${FILTTAX}.qza 

                crun qiime taxa filter-table \
                  --i-table table${FILTTAX}.qza \
                  --i-taxonomy taxonomy.qza \
                  --p-mode exact \
                  --p-exclude "d__Bacteria" \
                  --o-filtered-table table${FILTTAX}.qza 

		crun qiime taxa filter-table \
                  --i-table table${FILTTAX}.qza \
                  --i-taxonomy taxonomy.qza \
                  --p-mode contains \
                  --p-exclude "chloroplast" \
                  --o-filtered-table table${FILTTAX}.qza 

fi

if [ -z $FILTCOV ]
	then
		echo "coverage filter not specified"
	else
		COV=$FILTCOV
		FILTCOV=_$FILTCOV
			crun qiime feature-table filter-samples \
			  --i-table table${FILTTAX}.qza \
			  --p-min-frequency $COV \
			  --o-filtered-table table${FILTTAX}${FILTCOV}.qza
fi

if [ -z $FILTMETA ]
	then
		echo "metadata filter not specified"
	else
		FILTMETA=_$FILTMETA
		crun qiime feature-table filter-samples \
		  --i-table table${FILTTAX}${FILTCOV}.qza \
		  --m-metadata-file $METAPATH \
		  --p-where "[Biome] LIKE 'wild caught%' AND NOT [Location] = 'SI'" \
		  --o-filtered-table table${FILTTAX}${FILTCOV}${FILTMETA}.qza
fi

##Summarize the new filtered table
crun qiime feature-table summarize \
  --i-table table${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --o-visualization table${FILTTAX}${FILTCOV}${FILTMETA}.qzv \
  --m-sample-metadata-file $METAPATH

##Alpha and Beta diversity metrics
crun qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table${FILTTAX}${FILTCOV}${FILTMETA}.qza \
  --p-sampling-depth $COV \
  --m-metadata-file $METAPATH \
  --output-dir core-metrics-results${FILTTAX}${FILTCOV}${FILTMETA}

##change filenames to reflect filtering parameters
cd core-metrics-results${FILTTAX}${FILTCOV}${FILTMETA} &&
for f in * ;
do mv "$f" $(echo "$f" | sed "s/\(.*\).qz\([av]\)/\1${FILTTAX}${FILTCOV}${FILTMETA}.qz\2/g") ; 
done
cd ..

##Following assumes taxonomic classification has already been run
crun qiime taxa barplot \
--i-table table${FILTTAX}${FILTCOV}${FILTMETA}.qza \
--i-taxonomy taxonomy.qza \
--m-metadata-file $METAPATH \
--o-visualization barplot${FILTTAX}${FILTCOV}${FILTMETA}.qzv


