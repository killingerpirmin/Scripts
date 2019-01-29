#!/bin/bash

echo $(date +"%Y%m%d-%H:%M:%S") "Start STR-analysis Pipeline with modifiied CandiSSR; including quality control, paired read mergeing and fastq to fasta conversion!"

for i in *_R1.fastq;
do
sample_name=`echo ${i} | awk -F "_R1.fastq" '{print $1}'`

echo "Start $sample_name!"

fastqc -o /FastQC -f fastq ${i} ${sample_name}_R2.fastq

pear -j 6 -f ${i} -r ${sample_name}_R2.fastq -o ${sample_name}

seqret -sequence ${sample_name}.assembled.fastq -outseq ${sample_name}.fasta

perl /home/pk2018/Desktop/Tools/CandiSSR_v20170602/ModedSSR.pl -i Ctg_file_1-10 -o Results_1-10 -p Samples1-10 -t 6

echo $(date +"%Y%m%d-%H:%M:%S") "$sample_name done!"
done

echo "STR-analysis Pipeline with modifiied CandiSSR; including quality control, paired read mergeing and fastq to fasta conversion is finished!"
