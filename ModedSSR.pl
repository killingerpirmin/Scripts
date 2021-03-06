#!/usr/bin/perl

##############PROGRAM SETTINGS############
$CandiSSR_HOME='/home/pk2018/Desktop/Tools/CandiSSR_v20170602';
$BLASTALL='/usr/bin';
$MISA='/home/pk2018/Desktop/Tools/MISA';
$CLUSTALW='/usr/local/bin';
$PRIMER3='/home/pk2018/Desktop/Tools/primer3/src';
##############PROGRAM SETTINGS END############

#
# Copyright (c) KIB 2015
# Author:         En-Hua Xia <xiaenhua@mail.kib.ac.cn>
# Program Date:   2015.4.8
# Modifier:       En-Hua Xia <xiaenhua@mail.kib.ac.cn>
# Last Modified:  2015.4.8
# Version:        1.0
#

use Getopt::Long;

my $rest = system("perl -e 'use Bio::SearchIO'");
if($rest){
  print "$rest\n\nERROR!!!\nPlease install SearchIO module in Bioperl package!!\n";
  print "You can download SearchIO from CPAN at: http://search.cpan.org/~cjfields/BioPerl-1.6.924/Bio/SearchIO.pm\n\n";
  exit(0);
  }

my($species,$str,%Data,%Check,@SPECIES,$cmd,%SSR,$refssr,$altssr,$type,@NUM,$num,%opts,$version,$cntsp,$cnt,$rid,$oid,%ID,@arr,$pos,$dseq,$useq,$mr,$sd,$tmp,$strand,$st,$end,%seq);
my($tmpseq);

%opts = (p=>'CandiSSR_Output', o=>'CandiSSR_Run', l=>100, s=>95, c=>95, e=>'1e-10', t=>10);

GetOptions(\%opts,"i=s","o=s","p=s","l=s","s=s","c=s","e=s","t=s","skipPE","clean","h" );
if(!defined($opts{i}) || defined($opts{h})){
	&Usage();
	exit(0);
	}

my($FileCtl,$OutDir,$Prefix,$FlankingLen,$Cpu,$BlxCov,$BlxIden,$Evalue) = ($opts{i},$opts{o},$opts{p},$opts{l},$opts{t},$opts{c},$opts{s},$opts{e});

$version = '1.0';

system("cp $MISA/misa.* ./"); # Copy the MISA into the working directory

print "\n";
system("date");
my $datestart = time;
print qq(
########################################
  Welcome to use CandiSSR packages!

    Author: En-Hua Xia @ KIB
    Date: 2015-4-2
    Contact: xiaenhua\@mail.kib.ac.cn
    Version: $version
########################################
);

print "\nParameters for running:\n";
print "\tData config file:\t[$FileCtl]\n";
print "\tOutput Dir:\t[$OutDir]\n";
print "\tOutput file prefix:\t[$Prefix]\n";
print "\tSSR flanking length:\t[$FlankingLen]\n";
print "\tBlast evalue cutoff:\t[$Evalue]\n";
print "\tBlast identity cutoff:\t[$BlxIden]\n";
print "\tBlast coverage cutoff:\t[$BlxCov]\n";
print "\tNumber of CPU:\t[$Cpu]\n";

open IN,'<',$FileCtl;
while(<IN>){
	chomp;
  next if /^#/;
  ($species,$str) = (split/\s+/,$_)[0,1];
  next if $species eq '';
  push @SPECIES, $species;
  $Data{$species} = $str;
  $Check{$species}++;
  }
  close IN;

###### Data format validation ######

print "\nInput data files:\n\tName\tFiles\n";
foreach (@SPECIES){
	print "\t$_\t".$Data{$_}."\n";
  if($Check{$_} > 1){
  print "\nERROR: Name of ".$_.' has been used for '.$Check{$_}.' time! Please use different names for different data sets!'."\n";
  exit(0);
  }
  $cntsp++;
  }

###### Rename the sequence ID of each fasta files ######

print "\nRename the sequence ID of each fasta files:\n";
if(-e "$OutDir"){
  $cmd = "rm -rf ./$OutDir/*";
  &run($cmd);
  }
  else{
  	$cmd = "mkdir $OutDir";
  	&run($cmd);
  	}

print "\tName\tStored [NewFile]\tStatus\n";
foreach (@SPECIES){
	$cmd = "perl $CandiSSR_HOME/scripts/Rename_Fasta.pl $Data{$_} $_ > ./$OutDir/$_\.fasta";
  &run($cmd);
  $cmd = "mv $_\_SeqID_Conversion ./$OutDir/";
  &run($cmd);
  print "\t$_\t\[./$OutDir/$_\.fasta\]\tDone!\n";
  }

###### SSR detection within reference genome ######

print "\nDetect the SSRs within the reference genome (./$OutDir/Ref.fasta) using MISA:\n";
$cmd = "perl misa.pl ./$OutDir/Ref.fasta";
&run($cmd);
print "\tDone!\n";

###### Retrieve the conserved flanking sequences of SSRs ######

print "\nRetrieve the conserved flanking sequences ($FlankingLen bp) arounding SSRs:\n";
$cmd = "perl $CandiSSR_HOME/scripts/Retrieve_Flanking_Sequences.pl ./$OutDir/Ref.fasta ./$OutDir/Ref.fasta.misa $FlankingLen > $OutDir/Ref_SSR_Flanking_".$FlankingLen."bp\.fasta";
&run($cmd);
print "\tDone!\n";

###### Align the SSRs flanking sequences against other genomic or transcriptomic sequences using blastall######
print "\nAlign the SSRs flanking sequences against the other genomic or transcriptomic sequences using blastall:\n";
foreach (@SPECIES){
	chomp;
	next if $_ eq 'Ref';
	print "\tBuild database for $_:\n";
	$cmd = "$BLASTALL/formatdb -i ./$OutDir/$_.fasta -p F";
	&run($cmd);
	print "\tDone!\n";
	print "\tBlast SSRs flanking sequences to $_:\n";
	$cmd = "$BLASTALL/blastall -p blastn -i ./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp.fasta -d ./$OutDir/$_\.fasta -e $Evalue -F F -b 5 -v 5 -a $Cpu -o ./$OutDir/$_.out";
	&run($cmd);
	print "\tDone!\n";
	print "\tParsing blast result:\n";
	$cmd = "perl $CandiSSR_HOME/scripts/Blast_Parsing.pl ./$OutDir/$_.out 1 ./$OutDir/$_.ps";
	&run($cmd);
	$cmd = "perl $CandiSSR_HOME/scripts/Parse_BlxPs.pl ./$OutDir/$_.ps $BlxCov $BlxIden > ./$OutDir/$_.Blx.txt";
	&run($cmd);
        print "\tDone!\n";
	}
system("rm -rf formatdb.log error.log");

###### Retrieve sequences from blast hits and Search the specific SSRs######
print "\nRetrieve sequences from blast hits and Search the specific SSRs within them:\n";
print "\tName\t[Program]\tStatus\n";
foreach (@SPECIES){
	chomp;
  next if $_ eq 'Ref';
  $cmd = "perl $CandiSSR_HOME/scripts/Retrieve_Blx_Hits_Sequences_And_Searching.pl ./$OutDir/$_.fasta ./$OutDir/$_.Blx.txt $FlankingLen > ./$OutDir/$_.CandiSSR.txt";
  &run($cmd);
  print "\t$_\tRetrieving\tDone!\n";
  print "\t$_\tSearching\tDone!\n";
  }

###### Merge, Evaluate and Output the Candidate variable SSRs ######
print "\nMerge, Evaluate and Output the Candidate variable SSRs:\n";
print "\tName\tStatus\n";
foreach $species (@SPECIES){
	chomp;
  next if $species eq 'Ref';
  open IN,'<',"./$OutDir/".$species.'.CandiSSR.txt' || die;
  while($str = <IN>){
  	chomp($str);
  	($refssr,$altssr) = (split/\t/,$str)[0,1];
  	$SSR{$refssr}{$species} = $altssr;
  	}
  	print "\tMerging $species\tDone!\n";
  	print "\tMerging $species\tDone!\n";
  	close IN;
  	}

###### Output ######
open OUT, '>', "./$OutDir/".$Prefix.'.temp';
print OUT "Type\tRef";
foreach (@SPECIES){
	chomp;
	next if $_ eq 'Ref';
	print OUT "\t$_";
	}
	print OUT "\tStd_dev\tMissingRate\n";

foreach $refssr (sort keys %SSR){
	chomp($refssr);
	($type,$str) = (split/\//,$refssr)[0,1];
	print OUT $type."\t".$str;
  @NUM = ();
  $cnt = 0;
  ($num) = (split/\|/,$str)[0];
  push @NUM, $num;
  foreach $species (@SPECIES){
  	next if $species eq 'Ref';
  	($num) = (split/\|/,$SSR{$refssr}{$species})[0];
  	if($SSR{$refssr}{$species} eq ''){
  		$SSR{$refssr}{$species} = 'N/A';
  		$num = 0;
  		$cnt++;
  		}
  		else{
  			push @NUM, $num;
  			}
  			print OUT "\t".$SSR{$refssr}{$species};
  			}
  			print "\t$str\tEvaluating\tDone!\n";
  			print OUT "\t".sprintf("%.2f",&std_dev(&average(@NUM),@NUM))."\t".sprintf("%.2f",$cnt/($cntsp));
  			print OUT "\n";
  			}
  			close OUT;

###### Filter and Retrieve the flanking $FlankingLen bp conserved sequences surronding the Reference SSRs ######
print "\nFilter and Retrieve the flanking $FlankingLen bp conserved sequences surronding the Reference SSRs:\n";
$cmd = "perl $CandiSSR_HOME/scripts/Filter_And_Retrieve_FlankingSeq.pl ./$OutDir/$Prefix\.temp ./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp.fasta $FlankingLen > $OutDir/$Prefix\.results";
&run($cmd);
print "\tDone!\n";

###### Generate the final CandiSSR output ######
print "\nGenerate the final CandiSSR output:\n";
$cmd = "cat $OutDir/*_SeqID_Conversion > $OutDir/SeqID_Conversion";
&run($cmd);
$cmd = "cat $OutDir/*.fasta > $OutDir/AllSpecies.fasta";
&run($cmd);

open IN,'<',"./$OutDir/SeqID_Conversion";
while(<IN>){
  chomp;
  ($rid,$oid) = (split/\t/,$_)[0,1];
  $ID{$rid} = $oid;
}
close IN;

open IN,'<',"./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp\.fasta";
open OUT,'>',"./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp\.fasta.bak";
while(<IN>){
  chomp;
  if(/^>/){
  s/^>//;
  my @flankingseqid = split/\|/,$_;
  $flankingseqid[0] = $ID{$flankingseqid[0]};
  print OUT ">".join("|",@flankingseqid)."\n";
  }
  else{
  print OUT $_."\n";
  }
}
close IN;
close OUT;
system("mv ./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp\.fasta.bak ./$OutDir/Ref_SSR_Flanking_".$FlankingLen."bp\.fasta");

open IN,'<',"./$OutDir/AllSpecies.fasta";
while(<IN>){
  chomp;
  if(/^>/){
    s/^>//;
    $rid = $_;
    $seq{$rid} = ''; 
    }
    else{
      $seq{$rid}.=$_;
      }
  }
close IN;

my($flst,$flend,$flen);

$cnt = 0;
print "\tCalculate the Transferability (Similarity) of the ".2*$FlankingLen." bp surrounding SSRs among species/individual or species;\n";
open IN,'<',"./$OutDir/$Prefix\.results";
open OUT,'>',"./$OutDir/$Prefix\_PolySSRs.txt";
open PRIMER,'>',"./$OutDir/$Prefix\_SeqForPrimerDesign.fas";
open PRIMERSIM,'>',"./$OutDir/$Prefix\_SeqForPrimerEvaluation.fas";
while(<IN>){
  chomp;
  @arr = split/\t/,$_;
  $tmp = 0;
  ($type,$sd,$mr,$useq,$dseq) = ($arr[0],$arr[-4],$arr[-3],$arr[-2],$arr[-1]);

  if(/^Type/){
   print OUT "SSRID\t".$type;
   foreach $str (@arr){
     $tmp++;
     next if $tmp < 2 || $tmp > ($#arr-3);
     print OUT "\t$str";
     }
     print OUT "\t".$sd."\t".$mr."\t".'Transferability (Similarity)'."\t".$useq."\t".$dseq."\n";
     next;
   }  

  $cnt++;
  print OUT "CPSSR_".$cnt."\t".$type;

  open TMP,'>',"./$OutDir/TMP.fas";

  print TMP ">Ref\n$useq$dseq\n";

  foreach $str (@arr){
    $tmp++;
    next if $tmp < 2 || $tmp > ($#arr-3);
    if($str eq 'N/A'){
     print OUT "\t$str";
     next;
    }
    ($num,$str,$strand) = (split/\|/,$str)[0,1,2];
    ($str,$pos) = (split/\:/,$str)[0,1];
    ($st,$end) = (split/\-/,$pos)[0,1];

## Get seq ##
    if($st-1-$FlankingLen < 0){
    $flst = 0;
    }
    else{
      $flst = $st -1 - $FlankingLen;
        }

    #$flen = $end-$st+1+2*$FlankingLen;

    if(($end+$FlankingLen) > length($seq{$str})){
      $flend = length($seq{$str}) -1;
      }
      else{
        $flend = $end -1 + $FlankingLen;
        }

    $flen = $flend - $flst + 1;

    $tmpseq = substr($seq{$str},($flst),$flen);
    $tmpseq = &Comp($tmpseq) if $strand eq '-';

    ### For primer evaluation ###
    my($steval,$endeval,$leneval,$tmpseqeval);
    if($str !~ /^Ref/){
      if($st-1-2*$FlankingLen < 0){
         $steval = 0;
         }
         else{
             $steval = $st -1 - 2*$FlankingLen;
             }

     if(($end+2*$FlankingLen) > length($seq{$str})){
        $endeval = length($seq{$str}) -1;
        }
        else{
            $endeval = $end -1 + 2*$FlankingLen;
            }

    $leneval = $endeval - $steval + 1;

    $tmpseqeval = substr($seq{$str},($steval),$leneval);
    $tmpseqeval = &Comp($tmpseqeval) if $strand eq '-';
    print PRIMERSIM '>'."CPSSR_".$cnt.'|'.$type.'|'.$num.'|'.$str.':'.($steval+1).'-'.($endeval+1)."\n".$tmpseqeval."\n" if length($tmpseqeval) != 0; # Print Sequences used for primer blast evaulation
    }
    ######

    $altssr = ($type)x($num);
    ($st,$end) = (split/$altssr/,$tmpseq)[0,1];
    #next if length($st) != $FlankingLen || length($end) != $FlankingLen;

    print TMP '>'.$str.'|'.$type.'|'.$num.'|'.($flst+1).'-'.($flend+1)."\n".$st.$end."\n" if $str !~ /^Ref\_/;

    print PRIMER '>'."CPSSR_".$cnt.'|'.$type.'|'.$num.'|'.$str.':'.($flst+1).'-'.($flend+1)."\n".$tmpseq."\n" if $str =~ /^Ref/; # Print Sequences used for primer3

    #print PRIMERSIM '>'."CPSSR_".$cnt.'|'.$type.'|'.$num.'|'.$str.':'.($flst+1).'-'.($flend+1)."\n".$tmpseq."\n" if $str !~ /^Ref/; # Print Sequences used for primer blast evaulation

    $strand = '+' if $strand eq '';

    print OUT "\t".$num.'|'.$ID{$str}.':'.$pos.'|'.$strand;
    }
    close TMP;    

### Calculate Similarity among the up/downstream 100 bp ###
    $cmd = "$CLUSTALW/clustalw2 -INFILE=./$OutDir/TMP.fas > $OutDir/TMP.log 2>> $OutDir/TMP.log";
    &run($cmd);
    $cmd = "perl $CandiSSR_HOME/scripts/Cal_Similarity_From_Clustalw.pl $OutDir/TMP.aln > $OutDir/SIMTMP";
    &run($cmd);
    
    print OUT "\t".$sd."\t".$mr."\t";
    open SIMTMP,'<',"$OutDir/SIMTMP";
    while(my $simtmp = <SIMTMP>){
     chomp($simtmp);
     print OUT $simtmp;
    }
    print OUT "\t".$useq."\t".$dseq."\n";
}
print "\tDone!\n";
close IN;
close OUT;
close PRIMER;
close PRIMERSIM;

### Check wether the sequences file for primer designing empty or not ###
if(!(stat "./$OutDir/$Prefix\_SeqForPrimerDesign.fas")[7]){
  print "\n####### ERROR MESSAGE #######\n";
  print "\tCouldn't find any polymorphic SSRs for your species!\n";
  print "\tThere aren't any sequences that could be used to design primers!\n";
  print "\tPlease loose your parameters or check your input files!\n";
  print "\tExit!!\n\n";
  exit(0);
}

### Rename the sequence id for primers ###
open IN,'<',"./$OutDir/$Prefix\_SeqForPrimerDesign.fas";
open OUT,'>',"./$OutDir/$Prefix\_SeqForPrimerDesign.fas.bak";
while(<IN>){
  chomp;
  if(/^>/){
  s/^>//;
  my @flankingseqid = split/\|/,$_;
  my($flankingseqpos);
  ($flankingseqid[-1],$flankingseqpos) = (split/\:/,$flankingseqid[-1])[0,1];
  $flankingseqid[-1] = $ID{$flankingseqid[-1]}.':'.$flankingseqpos;
  print OUT ">".join("|",@flankingseqid)."\n";
  }
  else{
  print OUT $_."\n";
  }
}
close IN;
close OUT;
system("mv ./$OutDir/$Prefix\_SeqForPrimerDesign.fas.bak ./$OutDir/$Prefix\_SeqForPrimerDesign.fas");

###### Design primers ###
print "\nPrimers designing...\n";
print "\tPreparing input file for primer3;\n";
$cmd = "perl $CandiSSR_HOME/scripts/Fasta_to_primer3_input.pl $OutDir/$Prefix\_SeqForPrimerDesign.fas $PRIMER3/primer3_config/";
&run($cmd);
print "\tDone!\n";
print "\tRuning primer3;\n";
$cmd = "$PRIMER3/primer3_core < $OutDir/$Prefix\_SeqForPrimerDesign.fas.primer3input > $OutDir/$Prefix\_SeqForPrimerDesign.fas.primer3output";
&run($cmd);
print "\tDone!\n";
print "\tParsing primer3 output;\n";
$cmd = "perl $CandiSSR_HOME/scripts/Parse_primer3_output.pl $OutDir/$Prefix\_SeqForPrimerDesign.fas.primer3output";
&run($cmd);
print "\tDone!\n";

###### Primer evaluation ######
if(!defined $opts{skipPE}){
  print "\nPrimers evaluating...\n";
  print "\tRobot assessment of the primer transferability\;\n\tThis step is time-consuming, please be patient;\n";
  $cmd = "perl $CandiSSR_HOME/scripts/Primers_Evaluation.pl $OutDir/$Prefix\_SeqForPrimerEvaluation.fas $OutDir/$Prefix\_SeqForPrimerDesign.fas.primers $BLASTALL $CandiSSR_HOME > $OutDir/$Prefix\_Designed_Primers.txt";
  &run($cmd);
  print "\tDone!\n";
  system("rm formatdb.log error.log TMP.* TARGET.fas* QUERY.fas misa.*");
  }
  else{
   system("mv $OutDir/$Prefix\_SeqForPrimerDesign.fas.primers $OutDir/$Prefix\_Designed_Primers_WithoutPE.txt");
   print "\nSkiping primer evaluation step ... (with -skipPE option)\n";
   }

system("rm $OutDir/*_SeqForPrimer*.fas.* $OutDir/*_SeqForPrimerEvaluation.fas $OutDir/*.temp $OutDir/*SeqID_Conversion");

print "\n\tGood Luck!\n\n";
system("date");

my $datend = time;
print "\nTotal time used: ".sprintf("%.2f",($datend-$datestart)/60).' mins.'."\n\n";

sub average {
        my (@values) = @_;
        my $count = scalar @values;
        my $total = 0; 
        $total += $_ for @values; 
        return $count ? $total / $count : 0;
}

sub std_dev {
        my ($average, @values) = @_;
        my $count = scalar @values;
        my $std_dev_sum = 0;
        $std_dev_sum += ($_ - $average) ** 2 for @values;
        return $count ? sqrt($std_dev_sum / $count) : 0;
}

sub run{
        my $command = shift @_;
        #print "\t[CMD]: ".$command."\n";
        system($command);
        #print "\tDone!";
        }

sub Comp{
  my $sequence = shift @_;
  $sequence = reverse($sequence);
  $sequence =~ tr/ATCGN/TAGCN/;
  return $sequence;
}

sub Usage{

        $version = '1.0';

        print <<"	Usage End.";

        Description:

                Identify candidate polymorphic SSRs from multiple assembled sequences of a given species or genus.
                Version: $version

        Usage:
                perl $0 [options] ...

        Options:
                -i    <str>       *Must be given. The data config file.
                
                -o    <str>       Name of directory for output (will be created if it doesn't already exist). [default: CandiSSR_Run]

                -p    <str>       The prefix of output file. [default: CandiSSR_Output]

                -l    <int>       The flanking sequence length sorrounding SSRs. [default: 100]

                -e    <int>       Blast evalue cutoff. [default: 1e-10]

                -s    <int>       Blast identity cutoff. [default: 95]

                -c    <int>       Blast coverage cutoff. [default: 95]

                -t    <int>       Number of CPU used in blast searches. [default: 10]

              -skipPE < - >       Skip Primer Evaluation (PE) step, which is extremely time-consuming.

               -clean < - >       Clean the output directory and only retain the CandiSSR file.

                -h    < - >       Show this help and exit.

        More information please refer to: http://www.plantkingdomgdb.com/CandiSSR/

	Usage End.

        exit;
}
