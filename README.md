# Scripts

Hello and welcome to the repository for the (bash) scriptes of Pirmin Killigner


Content:

Alignment_Pipeline.sh

	Script for an alignment pipeline from raw paired-end fastq to bam;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Samtools for the bam conversion, coordinate sorting & indexing and Picard for duplication removal.


Alignment+VariantCalling_Pipeline_Freebayes.sh

	Script for an alignment pipeline with variant calling from raw paired-end fastq to vcf;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Samtools for the bam conversion, coordinate sorting & indexing,
	Picard for duplication removal and Freebayes for variant calling.


Alignment+VariantCalling_Pipeline_GATK-HaplotypeCaller.sh

	Script for an alignment pipeline with variant calling from raw paired-end fastq to vcf;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Picard for the bam conversion, coordinate sorting, duplication removal & indexing
	and GATK HalpotypeCaller for variant calling.


VariantCalling_Freebayes.sh

	Script for variant calling from, BWA aligned and Samtools processed, BAM-files utilysing Freebayes.


VariantCalling_Pipeline_GATK-HaplotypeCaller.sh

	Script for an variant calling pipeline from BWA alinged SAM-fiels utilysing Picard for the bam conversion, coordinate 		sorting, duplication removal & indexing and GATK HalpotypeCaller for variant calling.
