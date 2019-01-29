#!/bin/bash

echo $(date +"%Y%m%d-%H:%M:%S") "Start Varaint calling with GATK HaplotypeCaller!"

for i in *_F.fastq.gz;
do
sample_name=`echo ${i} | awk -F "_F. fastq.gz" '{print $1}'`

echo "Start $sample_name!"

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar SamFormatConverter I=${sample_name}_paired_aligned.sam O=${sample_name}_paired_aligned.bam

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar SortSam I=${sample_name}_paired_aligned.P.bam O=${sample_name}_paired_aligned_sorted.P.bam SORT_ORDER=coordinate

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar MarkDuplicates I=${sample_name}_paired_aligned_sorted.P.bam O=${sample_name}_paired_aligned_sorted_duprm.P.bam M=${sample_name}_duplication_metrics.P.txt REMOVE_DUPLICATES=true

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar AddOrReplaceReadGroups I=${sample_name}_paired_aligned_sorted_duprm.P.bam O=${sample_name}_final.bam RGLB=lib1 RGPL=illumina RGPU=unit1 RGSM=20

java -jar /home/pk2018/Desktop/Tools/Picard/picard.jar BuildBamIndex I=${sample_name}_final.bam

gatk --java-options "-Xmx14g" HaplotypeCaller -R /home/pk2018/Desktop/HG19/Hg19.fa -I ${sample_name}_final.bam -O ${sample_name}_HCvar.vcf -bamout ${sample_name}_realigned_final.bam -OBI TRUE -D /home/pk2018/Desktop/HG19/dbsnp_138.hg19.vcf --genotyping-mode DISCOVERY -mbq 30 --pcr-indel-model AGGRESSIVE

echo $(date +"%Y%m%d-%H:%M:%S") "$sample_name done!"
done

echo "Varaint calling with GATK HaplotypeCaller!"
