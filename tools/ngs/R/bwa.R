# TOOL bwa.R: "BWA-backtrack for single end reads" (BWA-backtrack aligns reads to genomes with BWA aln algorithm. Results are sorted and indexed BAM files, which are ready for viewing in the Chipster genome browser. 
# Note that this BWA tool uses publicly available genomes. If you would like to align reads against your own datasets, please use the tool \"BWA for single end reads and own genome\".)
# INPUT reads.txt: "Reads to align" TYPE GENERIC 
# OUTPUT bwa.bam 
# OUTPUT bwa.bam.bai 
# OUTPUT bwa.log 
# PARAMETER organism: "Genome" TYPE [Arabidopsis_thaliana.TAIR10.30, Bos_taurus.UMD3.1, Canis_familiaris.CanFam3.1, Drosophila_melanogaster.BDGP6, Felis_catus.Felis_catus_6.2, Gallus_gallus.Galgal4, Gasterosteus_aculeatus.BROADS1, Halorubrum_lacusprofundi_atcc_49239.GCA_000022205.1.30, Homo_sapiens.GRCh37.75, Homo_sapiens.GRCh38, Homo_sapiens_mirna, Medicago_truncatula.GCA_000219495.2.30, Mus_musculus.GRCm38, Mus_musculus_mirna, Oryza_sativa.IRGSP-1.0.30, Ovis_aries.Oar_v3.1, Populus_trichocarpa.JGI2.0.30, Rattus_norvegicus_mirna, Rattus_norvegicus.Rnor_5.0, Rattus_norvegicus.Rnor_6.0, Schizosaccharomyces_pombe.ASM294v2.30, Solanum_tuberosum.3.0.30, Sus_scrofa.Sscrofa10.2, Vitis_vinifera.IGGP_12x.30, Yersinia_enterocolitica_subsp_palearctica_y11.GCA_000253175.1.30, Yersinia_pseudotuberculosis_ip_32953_gca_000834295.GCA_000834295.1.30] DEFAULT Homo_sapiens.GRCh38 (Genome or transcriptome that you would like to align your reads against.)
# PARAMETER quality.format: "Quality value format used" TYPE [solexa1_3: "Illumina GA v1.3-1.5", sanger: Sanger] DEFAULT sanger (Note that this parameter is taken into account only if you chose to apply the mismatch limit to the seed region. Are the quality values in the Sanger format (ASCII characters equal to the Phred quality plus 33\) or in the Illumina Genome Analyzer Pipeline v1.3 or later format (ASCII characters equal to the Phred quality plus 64\)? Please see the manual for details. Corresponds to the command line parameter -I.)
# PARAMETER OPTIONAL alignment.no: "How many valid alignments are reported per read" TYPE  INTEGER DEFAULT 3 (Maximum number of alignments to report. Corresponds to the command line parameter bwa samse -n )
# PARAMETER OPTIONAL seed.length: "Length of the seed region" TYPE INTEGER DEFAULT 32 (How many bases of the left, good quality part of the read should be used as the seed region. If the seed length is longer than the reads, the seeding will be disabled.) 
# PARAMETER OPTIONAL seed.edit: "Maximum number of differences in the seed region" TYPE INTEGER DEFAULT 2 (Maximum number of differences such as mismatches or indels in the seed region.)
# PARAMETER OPTIONAL total.edit: "Maximum edit distance for the whole read" TYPE DECIMAL DEFAULT 0.04 ( Maximum edit distance if the value is more than one. If the value is between 1 and 0 then it defines the fraction of missing alignments given 2% uniform base error rate. In the latter case, the maximum edit distance is automatically chosen for different read lengths. Corresponds to the command line parameter -n.)
# PARAMETER OPTIONAL num.gaps: "Maximum number of gaps" TYPE INTEGER DEFAULT 1 (Maximum number of gap openings for one read. Corresponds to the command line parameter -o)
# PARAMETER OPTIONAL num.extensions: "Maximum number of gap extensions" TYPE INTEGER DEFAULT -1 (Maximum number of gap extensions, -1 for disabling long gaps. Corresponds to the command line parameter -e)
# PARAMETER OPTIONAL gap.opening: "Gap opening penalty" TYPE INTEGER DEFAULT 11 (Gap opening penalty. Corresponds to the command line parameter -O )
# PARAMETER OPTIONAL gap.extension: "Gap extension penalty" TYPE INTEGER DEFAULT 4 (Gap extension penalty. Corresponds to the command line parameter -E)
# PARAMETER OPTIONAL mismatch.penalty: "Mismatch penalty threshold" TYPE INTEGER DEFAULT 3 (BWA will not search for suboptimal hits with a score lower than the alignment score minus this. Corresponds to the command line parameter -M)
# PARAMETER OPTIONAL disallow.gaps: "Disallow gaps in region"  TYPE INTEGER DEFAULT 16 (Disallow a long deletion within the given number of bp towards the 3\'-end. Corresponds to the command line parameter -d )
# PARAMETER OPTIONAL disallow.indel: "Disallow an indel within the given number of bp towards the ends"  TYPE INTEGER DEFAULT 5 (Do not put an indel within the defined value of bp towards the ends. Corresponds to the command line parameter -i)
# PARAMETER OPTIONAL trim.threshold: "Quality trimming threshold" TYPE INTEGER DEFAULT 0 (Quality threshold for read trimming down to 35bp. Corresponds to the command line parameter -q)
# PARAMETER OPTIONAL barcode.length: "Barcode length"  TYPE INTEGER DEFAULT 0 (Length of barcode starting from the 5 prime-end. The barcode of each read will be trimmed before mapping. Corresponds to the command line parameter -B)

# KM 24.8.2011
# AMS 19.6.2012 Added unzipping
# AMS 11.11.2013 Added thread support

# check out if the file is compressed and if so unzip it
source(file.path(chipster.common.path, "zip-utils.R"))
unzipIfGZipFile("reads.txt")

# bwa
bwa.binary <- file.path(chipster.tools.path, "bwa", "bwa")
bwa.genome <- file.path(chipster.tools.path, "genomes", "indexes", "bwa", organism)
command.start <- paste("bash -c '", bwa.binary)

# mode specific parameters
if (total.edit >= 1) {
	total.edit <- round(total.edit)
}

quality.parameter <- ifelse(quality.format == "solexa1_3", "-I", "")
mode.parameters <- paste("aln", "-t", chipster.threads.max, "-o", num.gaps, "-e", num.extensions, "-d", disallow.gaps, "-i" , disallow.indel , "-l" , seed.length , "-k" , seed.edit , "-O" , gap.opening , "-E" , gap.extension , "-q" , trim.threshold, "-B" , barcode.length , "-M" , mismatch.penalty , "-n" , total.edit , quality.parameter)

# command ending
command.end <- paste(bwa.genome, "reads.txt 1> alignment.sai 2>> bwa.log'")

# run bwa alignment
bwa.command <- paste(command.start, mode.parameters, command.end)

echo.command <- paste("echo '", bwa.binary , mode.parameters, bwa.genome, "reads.txt ' > bwa.log" )
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(echo.command)
system(bwa.command)

#system ("pwd")
#system ("ls -l >> bwa.log")
# sai to sam conversion
samse.parameters <- paste("samse -n", alignment.no )
samse.end <- paste(bwa.genome, "alignment.sai reads.txt 1> alignment.sam 2>>bwa.log'" )
samse.command <- paste( command.start, samse.parameters , samse.end )
paste('CHIPSTER-NOTE: ', samse.command)
system(samse.command)

		
# samtools binary
samtools.binary <- c(file.path(chipster.tools.path, "samtools", "samtools"))

# convert sam to bam
system(paste(samtools.binary, "view -bS alignment.sam -o alignment.bam"))

# sort bam
system(paste(samtools.binary, "sort alignment.bam alignment.sorted"))

# index bam
system(paste(samtools.binary, "index alignment.sorted.bam"))

# rename result files
system("mv alignment.sorted.bam bwa.bam")
system("mv alignment.sorted.bam.bai bwa.bam.bai")

# Handle output names
#
source(file.path(chipster.common.path, "tool-utils.R"))

# read input names
inputnames <- read_input_definitions()

# Determine base name
basename <- strip_name(inputnames$reads.txt)

# Make a matrix of output names
outputnames <- matrix(NA, nrow=2, ncol=2)
outputnames[1,] <- c("bwa.bam", paste(basename, ".bam", sep =""))
outputnames[2,] <- c("bwa.bam.bai", paste(basename, ".bam.bai", sep =""))

# Write output definitions file
write_output_definitions(outputnames)

