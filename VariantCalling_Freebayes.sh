#!/bin/bash

echo $(date +"%Y%m%d-%H:%M:%S") "Start Varaint calling with Freebayes (soft filters)!"

for i in *_paired_aligned_sorted.bam;
do
sample_name=`echo ${i} | awk -F "_paired_aligned_sorted.bam" '{print $1}'`

echo "Start $sample_name!"

freebayes -C 10 -F 0.02 --min-base-quality 30 --min-mapping-quality 1 --min-coverage 30 --read-snp-limit 5 --read-indel-limit 5 -f /home/pk2018/Desktop/HG19/Hg19.fa ${i} >${sample_name}_softfilter-FBvar.vcf

echo $(date +"%Y%m%d-%H:%M:%S") "$sample_name done!"
done

echo "Varaint calling with Freebayes (soft filters) is finished!"
