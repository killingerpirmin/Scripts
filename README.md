# Scripts

Hello and welcome to the repository for the (bash) scriptes of Pirmin Killigner


Content:

Alignment_Pipeline.sh

	Bash script for an alignment pipeline from raw paired-end fastq to bam;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Samtools for the bam conversion, coordinate sorting & indexing and Picard for duplication removal.


Alignment+VariantCalling_Pipeline_Freebayes.sh

	Bash script for a alignment pipeline with variant calling from raw paired-end fastq to vcf;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Samtools for the bam conversion, coordinate sorting & indexing,
	Picard for duplication removal and Freebayes for variant calling.


Alignment+VariantCalling_Pipeline_GATK-HaplotypeCaller.sh

	Bash script for a alignment pipeline with variant calling from raw paired-end fastq to vcf;
	utilysing fastQC & Trimmomatic for quality control, BWA for the alignment,
	Picard for the bam conversion, coordinate sorting, duplication removal & indexing
	and GATK HalpotypeCaller for variant calling.


VariantCalling_Freebayes.sh

	Bash script for variant calling from, BWA aligned and Samtools processed, BAM-files utilysing Freebayes.


VariantCalling_Pipeline_GATK-HaplotypeCaller.sh

	Bash script for a variant calling pipeline from BWA alinged SAM-fiels utilysing Picard for the bam conversion,
	coordinate sorting, duplication removal & indexing and GATK HalpotypeCaller for variant calling.
	
	
STR-analysis_Pipeline.sh

	Bash script for a STR-analysis pipeline from raw-paired end reads to MSI-loci & PCR-primer;
	utliysing fastQC for quality control, PEAR for paired read mergeing and modedSSR (modified CandiSSR see below)
	for STR identification, MSI callign and Primer design.
	
	
modedSSR.pl

	Pearl script based on the CandiSSR.pl [MISA, Blastall, ClustalW, BioPerls SearchIO & Primer3]
	(http://www.plantkingdomgdb.com/CandiSSR/) modified for the use of MSI indetification in human panel-sequencing data.


ABL1-BCR_ref-genome.fasta

	Reference sequence for human (NCBI GRCh38) ABL1 and BCR in fasta format.


Ctg_file_1-10

	Example Ctg_file for the use in modedSSR
