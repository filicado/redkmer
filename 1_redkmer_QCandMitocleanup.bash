#!/bin/bash
#PBS -N redkmer1
#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=24:mem=16gb:tmpspace=500gb
#PBS -e /home/nikiwind/reports
#PBS -o /home/nikiwind/reports


if [ -z ${PBS_ENVIRONMENT+x} ]
then
echo "---> running on the Perugia numbercruncher..."
source redkmer.cfg
else
echo "---> running on HPC cluster..."
source $PBS_O_WORKDIR/redkmer.cfg
module load fastqc
module load bowtie/1.1.1

fi


echo "========== setting up =========="

mkdir -p $CWD/qsubscripts
mkdir -p $CWD/QualityReports
mkdir -p $CWD/pacBio_illmapping
mkdir -p $CWD/pacBio_illmapping/logs
mkdir -p $CWD/pacBio_illmapping/mapping_rawdata
mkdir -p $CWD/pacBio_illmapping/index
mkdir -p $CWD/pacBio_bins
mkdir -p $CWD/pacBio_bins/fasta
mkdir -p $CWD/temp
mkdir -p $CWD/kmers
mkdir -p $CWD/kmers/rawdata
mkdir -p $CWD/kmers/fasta/
mkdir -p $CWD/plots
mkdir -p $CWD/kmers/Refgenome_blast
mkdir -p $CWD/kmers/bowtie
mkdir -p $CWD/kmers/bowtie/index
mkdir -p $CWD/kmers/bowtie/mapping
mkdir -p $CWD/kmers/bowtie/mapping/logs
mkdir -p $CWD/kmers/Refgenome_blast
mkdir -p $CWD/kmers/bowtie/offtargets
mkdir -p $CWD/kmers/bowtie/offtargets/logs
mkdir -p $CWD/MitoIndex

echo "========== producing quality report for illumina libraries =========="

$FASTQC ${illDIR}/raw_f.fastq -o ${CWD}/QualityReports
$FASTQC ${illDIR}/raw_m.fastq -o ${CWD}/QualityReports

echo "========== removing illumina reads mapping to mitochondrial DNA =========="


if [ -z ${PBS_ENVIRONMENT+x} ]
then

# Build the index and map the Illumina data
$BOWTIEB $MtREF ${CWD}/MitoIndex/MtRef

# Map the Illumina data on the mito, the option  --un gives the unmapped read (not mitochondrial)
$BOWTIE -p $CORES $CWD/MitoIndex/MtRef ${illDIR}/raw_f.fastq --un ${illDIR}/f.fastq 2> ${illDIR}/f_bowtie.log
$BOWTIE -p $CORES $CWD/MitoIndex/MtRef ${illDIR}/raw_m.fastq --un ${illDIR}/m.fastq 2> ${illDIR}/m_bowtie.log

else

cp ${illDIR}/raw_f.fastq $TMPDIR/raw_f.fastq
cp ${illDIR}/raw_m.fastq $TMPDIR/raw_m.fastq

#$BOWTIEB $MtREF ${CWD}/MitoIndex/MtRef

$BOWTIE -p $CORES $CWD/MitoIndex/MtRef $TMPDIR/raw_f.fastq --un $TMPDIR/f.fastq 2> ${illDIR}/f_bowtie.log
cp $TMPDIR/f.fastq ${illDIR}
rm $TMPDIR/f.fastq

$BOWTIE -p $CORES $CWD/MitoIndex/MtRef $TMPDIR/raw_m.fastq --un $TMPDIR/m.fastq 2> ${illDIR}/m_bowtie.log
cp $TMPDIR/m.fastq ${illDIR}

fi


printf "======= Done step 1 =======\n"

