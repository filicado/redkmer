#!/bin/bash

runfile="$1"
if source ${runfile}; then
printf "======= redkmer 0.2 =======\n"
printf "Obtained run data from ${runfile}\n"
printf "Working Directory: ${CWD}\n"
printf "Pacbio Read Directory: ${pacDIR}\n"
printf "Illumina Read Directory: ${illDIR}\n"
printf "Running script.\n"

else
printf 'Failed to obtain run data. Exiting!\n'
exit 0
fi

source redkmer.cfg

mkdir -p $CWD/kmers/blast/
mkdir -p $CWD/kmers/fasta/
mkdir -p $CWD/kmers/bowtie
mkdir -p $CWD/kmers/bowtie/index
mkdir -p $CWD/kmers/bowtie/mapping
mkdir -p $CWD/kmers/bowtie/mapping/logs


kmers=$CWD/kmers/fasta/allkmers.fasta

#XSI=kmer X chromosome specificity index (0= no specificity; 1= full X specificity; 0.5= half of the kmer hits are on other chromosomes
XSI=$0.9


printf "======= Creating bowtie index for PacBio bins =======\n"

#$BOWTIEB $CWD/pacBio_bins/fasta/Xbin.fasta $CWD/kmers/bowtie/index/Xbin &
#$BOWTIEB $CWD/pacBio_bins/fasta/Abin.fasta $CWD/kmers/bowtie/index/Abin &
#$BOWTIEB $CWD/pacBio_bins/fasta/Ybin.fasta $CWD/kmers/bowtie/index/Ybin &
#$BOWTIEB $CWD/pacBio_bins/fasta/GAbin.fasta $CWD/kmers/bowtie/index/GAbin &

#wait $(jobs -p)

printf "======= Running bowtie against X chromosome bin =======\n"
$BOWTIE -a -t -p$CORES -v 0 $CWD/kmers/bowtie/index/Xbin --suppress 2,3,4,5,6,7,8,9 -f $CWD/kmers/fasta/Xkmers.fasta 1> $CWD/kmers/bowtie/mapping/Xbin.txt 2> $CWD/kmers/bowtie/mapping/logs/Xbin_log.txt

printf "======= Running bowtie against autosome bin =======\n"
$BOWTIE -a -t -p$CORES -v 0 $CWD/kmers/bowtie/index/Abin --suppress 2,3,4,5,6,7,8,9 -f $CWD/kmers/fasta/Xkmers.fasta 1> $CWD/kmers/bowtie/mapping/Abin.txt 2> $CWD/kmers/bowtie/mapping/logs/Abin_log.txt

printf "======= Running bowtie against Y chromosome bin =======\n"
$BOWTIE -a -t -p$CORES -v 0 $CWD/kmers/bowtie/index/Ybin --suppress 2,3,4,5,6,7,8,9 -f $CWD/kmers/fasta/Xkmers.fasta 1> $CWD/kmers/bowtie/mapping/Ybin.txt 2> $CWD/kmers/bowtie/mapping/logs/Ybin_log.txt

printf "======= Running bowtie against GA chromosome bin =======\n"
$BOWTIE -a -t -p$CORES -v 0 $CWD/kmers/bowtie/index/GAbin --suppress 2,3,4,5,6,7,8,9 -f $CWD/kmers/fasta/Xkmers.fasta 1> $CWD/kmers/bowtie/mapping/GAbin.txt 2> $CWD/kmers/bowtie/mapping/logs/GAbin_log.txt

printf "======= extracting blast results =======\n"

sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/bowtie/mapping/Xbin.txt | uniq -c  | awk '{print $2, $1}' >  $CWD/kmers/bowtie/mapping/kmer_hits_Xbin &
sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/bowtie/mapping/Abin.txt | uniq -c  | awk '{print $2, $1}' >  $CWD/kmers/bowtie/mapping/kmer_hits_Abin &
sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/bowtie/mapping/Ybin.txt | uniq -c  | awk '{print $2, $1}' >  $CWD/kmers/bowtie/mapping/kmer_hits_Ybin &
sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/bowtie/mapping/GAbin.txt | uniq -c  | awk '{print $2, $1}' >  $CWD/kmers/bowtie/mapping/kmer_hits_GAbin &

wait $(jobs -p)


join -a1 -a2 -1 1 -2 1 -o '0,1.2,2.2' -e "0" $CWD/kmers/bowtie/mapping/kmer_hits_Xbin $CWD/kmers/bowtie/mapping/kmer_hits_Abin > $CWD/kmers/bowtie/mapping/kmer_hits_XAbin
join -a1 -a2 -1 1 -2 1 -o '0,1.2,1.3,2.2' -e "0" $CWD/kmers/bowtie/mapping/kmer_hits_XAbin $CWD/kmers/bowtie/mapping/kmer_hits_Ybin > $CWD/kmers/bowtie/mapping/kmer_hits_XAYbin
join -a1 -a2 -1 1 -2 1 -o '0,1.2,1.3,1.4,2.2' -e "0" $CWD/kmers/bowtie/mapping/kmer_hits_XAYbin $CWD/kmers/bowtie/mapping/kmer_hits_GAbin > $CWD/kmers/bowtie/mapping/kmer_hits_bins

rm $CWD/kmers/bowtie/mapping/kmer_hits_XAbin
rm $CWD/kmers/bowtie/mapping/kmer_hits_XAYbin

awk '{print $0, ($2+$3+$4+$5)}' $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins
awk '{print $0, ($2/$6)}' $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins
awk '{if ($6==0)print $0, "nohits"}' $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins
awk -v xsi="$XSI" '{if ($7>xsi) {$8=="pass"}; print}' $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins
awk -v xsi="$XSI" '{if ($7<xsi) {$8=="fail"}; print}' $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins

printf "======= merging bowtie bin results to kmer_counts data =======\n"

sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/bowtie/mapping/kmer_hits_bins > tmpfile; mv tmpfile $CWD/kmers/bowtie/mapping/kmer_hits_bins &
sort -k1b,1 --parallel=8 -T $CWD/temp --buffer-size=5G $CWD/kmers/rawdata/kmers_to_merge > tmpfile; mv tmpfile $CWD/kmers/rawdata/kmers_to_merge &

wait $(jobs -p)


join -a1 -a2 -1 1 -2 1 -o '0,2.2,2.3,2.4,2.5,2.6,1.2,1.3,1.4,1.5,1.6,1.7,1.8' -e "nohits" $CWD/kmers/bowtie/mapping/kmer_hits_bins $CWD/kmers/rawdata/kmers_to_merge > $CWD/kmers/rawdata/kmers_hits_results


printf "======= generating Xkmers.fasta file for off-target analysis =======\n"

awk '{if ($13=="pass") print $1, $2}' $CWD/kmers/rawdata/kmers_hits_results |awk '{print ">"$1"\n"$2}' > $CWD/kmers/fasta/Xkmers.fasta

printf "======= generating kmers_all_results file =======\n"

awk -v OFS="\t" '$1=$1' $CWD/kmers/rawdata/kmers_hits_results > tmpfile; mv tmpfile $CWD/kmers/rawdata/kmers_hits_results

#Add column header
awk 'BEGIN {print "kmer_id\tseq\tfemale\tmale\tCQ\tsum\thits_X\thits_A\thits_Y\thits_GA\thits_sum\tperchitsX\thits_threshold"} {print}' $CWD/kmers/rawdata/kmers_hits_results > tmpfile; mv tmpfile $CWD/kmers/rawdata/kmers_hits_results

printf "======= done step 4 =======\n"


