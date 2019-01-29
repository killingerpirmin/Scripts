#!/bin/bash

echo $(date +"%Y%m%d-%H:%M:%S") "Start Varaint calling pipeline with GATK HaplotypeCaller, BWA & Picard; from fastq to vcf!"

for i in *_F.fastq.gz;
do
sample_name=`echo ${i} | awk -F "_F. fastq.gz" '{print $1}'`

echo "Start $sample_name!"

fastqc -o /FastQC -f fastq ${i} ${sample_name}_R.fastq.gz

java -jar /home/pk2018/Desktop/Tools/Trimmomatic-0.38/trimmomatic-0.38.jar PE -phred33 -threads 6 -summary ${sample_name}_summary.txt ${i} ${sample_name}_R.fastq.gz ${sample_name}_F_paired.fq.gz ${sample_name}_F_unpaired.fq.gz ${sample_name}_R_paired.fq.gz ${sample_name}_R_unpaired.fq.gz ILLUMINACLIP:/home/pk2018/Desktop/Tools/Trimmomatic-0.38/adapters/TruSeq3-PE-2.fa:2:30:10 LEADING:5 TRAILING:5 SLIDINGWINDOW:5:25

bwa mem -t 6 -M /home/pk2018/Desktop/HG19/Hg19.fa ${i} ${sample_name}_R_paired.fq.gz > ${sample_name}_paired_aligned.sam

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar SamFormatConverter I=${sample_name}_paired_aligned.sam O=${sample_name}_paired_aligned.P.bam

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar SortSam I=${sample_name}_paired_aligned.P.bam O=${sample_name}_paired_aligned_sorted.P.bam SORT_ORDER=coordinate

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar MarkDuplicates I=${sample_name}_paired_aligned_sorted.P.bam O=${sample_name}_paired_aligned_sorted_duprm.P.bam M=${sample_name}_duplication_metrics.P.txt REMOVE_DUPLICATES=true

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar AddOrReplaceReadGroups I=${sample_name}_paired_aligned_sorted_duprm.P.bam O=${sample_name}_final.bam RGLB=lib1 RGPL=illumina RGPU=unit1 RGSM=20

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar BuildBamIndex I=${sample_name}_final.bam

gatk --java-options "-Xmx14g" HaplotypeCaller -R /home/pk2018/Desktop/HG19/Hg19.fa -I ${sample_name}_final.bam -O ${sample_name}_HCvar.vcf -bamout ${sample_name}_realigned_final.bam -OBI TRUE -D /home/pk2018/Desktop/HG19/dbsnp_138.hg19.vcf --genotyping-mode DISCOVERY -mbq 30 --pcr-indel-model AGGRESSIVE

echo $(date +"%Y%m%d-%H:%M:%S") "$sample_name done!"
done

echo "Varaint calling pipeline with GATK HaplotypeCaller,BWA & Picard; from fastq to vcf is finished!"
