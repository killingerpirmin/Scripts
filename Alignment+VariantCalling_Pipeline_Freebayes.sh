#!/bin/bash

echo $(date +"%Y%m%d-%H:%M:%S") "Start Varaint calling pipeline with Freebayes (soft filters),BWA & Samtools; from fastq to vcf!"

for i in *_F.fastq.gz;
do
sample_name=`echo ${i} | awk -F "_F. fastq.gz" '{print $1}'`

echo "Start $sample_name!"

fastqc -o /FastQC -f fastq ${i} ${sample_name}_R.fastq.gz

java -jar /home/pk2018/Desktop/Tools/Trimmomatic-0.38/trimmomatic-0.38.jar PE -phred33 -threads 6 -summary ${sample_name}_summary.txt ${i} ${sample_name}_R.fastq.gz ${sample_name}_F_paired.fq.gz ${sample_name}_F_unpaired.fq.gz ${sample_name}_R_paired.fq.gz ${sample_name}_R_unpaired.fq.gz ILLUMINACLIP:/home/pk2018/Desktop/Tools/Trimmomatic-0.38/adapters/TruSeq3-PE-2.fa:2:30:10 LEADING:5 TRAILING:5 SLIDINGWINDOW:5:25

bwa mem -t 6 -M /home/pk2018/Desktop/HG19/Hg19.fa ${i} ${sample_name}_R_paired.fq.gz > ${sample_name}_paired_aligned.sam

samtools view -hb -o ${sample_name}_paired_aligned.bam -O BAM -@ 6 ${sample_name}_paired_aligned.sam

samtools sort -o ${sample_name}_paired_aligned_sorted.bam -O BAM -@ 6 ${sample_name}_paired_aligned.bam

samtoosl index ${sample_name}_paired_aligned_sorted.bam

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar MarkDuplicates I=${sample_name}_paired_aligned_sorted.bam O=${sample_name}_paired_aligned_sorted_duprm.bam M=${sample_name}_duplication_metrics.txt REMOVE_DUPLICATES=true

freebayes -C 10 -F 0.02 --min-base-quality 30 --min-mapping-quality 1 --min-coverage 30 --read-snp-limit 5 --read-indel-limit 5 -f /home/pk2018/Desktop/HG19/Hg19.fa ${sample_name}_paired_aligned_sorted_duprm.bam >${sample_name}_softfilter-FBvar.vcf

echo $(date +"%Y%m%d-%H:%M:%S") "$sample_name done!"
done

echo "Varaint calling pipeline with Freebayes (soft filters),BWA & Samotools; from fastq to vcf is finished!"
