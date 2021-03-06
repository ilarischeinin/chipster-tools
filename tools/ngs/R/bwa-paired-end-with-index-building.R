# TOOL bwa-paired-end-with-index-building.R: "BWA-backtrack for paired end reads and own genome" (BWA-backtrack aligns paired end reads to genomes with BWA ALN algorithm. Results are sorted and indexed bam files, which are ready for viewing in the Chipster genome browser. 
# Note that this BWA tool requires that you have imported the reference genome to Chipster in fasta format. If you would like to align reads against publicly available genomes, please use the tool \"BWA for paired-end reads\".)
# INPUT reads1.txt: "Paired-end read set 1 to align" TYPE GENERIC 
# INPUT reads2.txt: "Paired-end read set 2 to align" TYPE GENERIC 
# INPUT genome.txt: "Reference genome" TYPE GENERIC
# OUTPUT bwa.bam 
# OUTPUT bwa.bam.bai 
# OUTPUT bwa.log 
# PARAMETER seed.length: "Seed length" TYPE INTEGER DEFAULT 32 (Number of first nucleotides to be used as a seed. If the seed length is longer than query sequences, then seeding will be disabled. Corresponds to the command line parameter -l) 
# PARAMETER seed.edit:"Maximum of differences in the seed" TYPE INTEGER DEFAULT 2 (Maximum differences in the seed. Corresponds to the command line parameter -k )
# PARAMETER total.edit: "Maximum edit distance for the whole read" TYPE DECIMAL DEFAULT 0.04 ( Maximum edit distance if the value is more than one. If the value is between 1 and 0 then it defines the fraction of missing alignments given 2% uniform base error rate. In the latter case, the maximum edit distance is automatically chosen for different read lengths. Corresponds to the command line parameter -n.)
# PARAMETER quality.format: "Quality value format used" TYPE [solexa1_3: "Illumina GA v1.3-1.5", sanger: Sanger] DEFAULT sanger (Note that this parameter is taken into account only if you chose to apply the mismatch limit to the seed region. Are the quality values in the Sanger format (ASCII characters equal to the Phred quality plus 33\) or in the Illumina Genome Analyzer Pipeline v1.3 or later format (ASCII characters equal to the Phred quality plus 64\)? Please see the manual for details. Corresponds to the command line parameter -I.)
# PARAMETER OPTIONAL num.gaps: "Maximum number of gap openings" TYPE INTEGER DEFAULT 1 (Maximum number of gap openings for one read. Corresponds to the command line parameter -o.)
# PARAMETER OPTIONAL num.extensions: "Maximum number of gap extensions" TYPE INTEGER DEFAULT -1 (Maximum number of gap extensions, -1 for disabling long gaps. Corresponds to the command line parameter -e.)
# PARAMETER OPTIONAL gap.opening: "Gap open penalty " TYPE INTEGER DEFAULT 11 (Gap opening penalty. Corresponds to the command line parameter -O.)
# PARAMETER OPTIONAL gap.extension: "Gap extension penalty " TYPE INTEGER DEFAULT 4 (Gap extension penalty. Corresponds to the command line parameter -E.)
# PARAMETER OPTIONAL mismatch.penalty: "Mismatch penalty threshold" TYPE INTEGER DEFAULT 3 (BWA will not search for suboptimal hits with a score lower than defined. Corresponds to the command line parameter -M.)
# PARAMETER OPTIONAL disallow.gaps: "Disallow gaps in region"  TYPE INTEGER DEFAULT 16 (Disallow a long deletion within the given number of bp towards the 3\'-end. Corresponds to the command line parameter -d.)
# PARAMETER OPTIONAL disallow.indel: "Disallow an indel within the given number of pb towards the ends"  TYPE INTEGER DEFAULT 5 (Do not put an indel within the defined value of bp towards the ends. Corresponds to the command line parameter -i.)
# PARAMETER OPTIONAL trim.threshold: "Quality trimming threshold" TYPE INTEGER DEFAULT 0 (Quality threshold for read trimming down to 35bp. Corresponds to the command line parameter -q.)
# PARAMETER OPTIONAL barcode.length: "Barcode length"  TYPE INTEGER DEFAULT 0 (Length of barcode starting from the 5 pime-end. The barcode of each read will be trimmed before mapping. Corresponds to the command line parameter -B.)
# PARAMETER OPTIONAL alignment.no: "Maximum hits to output for paired reads" TYPE INTEGER DEFAULT 3 (Maximum number of alignments to output in the XA tag for reads paired properly. If a read has more than the given amount of hits, the XA tag will not be written. Corresponds to the command line parameter bwa sampe -n.)
# PARAMETER OPTIONAL max.discordant: "Maximum hits to output for discordant pairs" TYPE INTEGER DEFAULT 10 (Maximum number of alignments to output in the XA tag for disconcordant read pairs, excluding singletons. If a read has more than INT hits, the XA tag will not be written. Corresponds to the command line parameter bwa sampe -N.) 
# PARAMETER OPTIONAL max.insert: "Maximum insert size" TYPE INTEGER DEFAULT 500 (Maximum insert size for a read pair to be considered being mapped properly. This option is only used when there are not enough good alignments to infer the distribution of insert sizes. Corresponds to the command line parameter bwa sampe -a.)
# PARAMETER OPTIONAL max.occurrence: "Maximum occurrences for one end" TYPE INTEGER DEFAULT 100000 (Maximum occurrences of a read for pairing. A read with more occurrneces will be treated as a single-end read. Reducing this parameter helps faster pairing. The default value is 100000. For reads shorter than 30bp, applying a smaller value is recommended to get a sensible speed at the cost of pairing accuracy. Corresponds to the command line parameter bwa sampe -o.)

# KM 26.8.2011
# AMS 19.6.2012 Added unzipping
# KM 5.11.2012 Fixed a bug in reading mate pairs
# AMS 11.11.2013 Added thread support


# check out if the file is compressed and if so unzip it
source(file.path(chipster.common.path, "zip-utils.R"))
unzipIfGZipFile("reads1.txt")
unzipIfGZipFile("reads2.txt")
unzipIfGZipFile("genome.txt")

##
# bwa settings
##
bwa.binary <- file.path(chipster.tools.path, "bwa", "bwa")

# bwa settings
bwa.binary <- file.path(chipster.tools.path, "bwa", "bwa")
bwa.index.binary <- file.path(chipster.module.path, "shell", "check_bwa_index.sh")
command.start <- paste("bash -c '", bwa.binary)

# Do indexing
print("Indexing the genome...")
system("echo Indexing the genome... > bwa.log")
check.command <- paste ( bwa.index.binary, "genome.txt| tail -1 ")
#genome.dir <- system(check.command, intern = TRUE)
#bwa.genome <- file.path( genome.dir , "genome.txt")
bwa.genome <- system(check.command, intern = TRUE)


###
# common parameters for bwa runs
###
# mode specific parameters
if (total.edit >= 1) {
	total.edit <- round(total.edit)
}
command.start <- paste("bash -c '", bwa.binary)
quality.parameter <- ifelse(quality.format == "solexa1_3", "-I", "")
mode.parameters <- paste("aln", "-t", chipster.threads.max, "-o", num.gaps, "-e", num.extensions, "-d", disallow.gaps, "-i" , disallow.indel , "-l" , seed.length , "-k" , seed.edit , "-O" , gap.opening , "-E" , gap.extension , "-q" , trim.threshold, "-B" , barcode.length , "-M" , mismatch.penalty , "-n" , total.edit , quality.parameter)

###
# run the first set
###
echo.command <- paste("echo '", bwa.binary , mode.parameters, bwa.genome, "reads1.txt ' > bwa.log" )
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(echo.command)
command.end <- paste(bwa.genome, "reads1.txt 1> alignment1.sai 2>> bwa.log'")
bwa.command <- paste(command.start, mode.parameters, command.end)
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(bwa.command)


###
# run the second set
###
echo.command <- paste("echo '", bwa.binary , mode.parameters, bwa.genome, "reads2.txt ' >> bwa.log" )
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(echo.command)
command.end <- paste(bwa.genome, "reads2.txt 1> alignment2.sai 2>> bwa.log'")
bwa.command <- paste(command.start, mode.parameters, command.end)
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(bwa.command)

###
# sai to sam conversion
###
sampe.parameters <- paste("sampe -n", alignment.no, "-a", max.insert, "-o" , max.occurrence , "-N" , max.discordant )
sampe.end <- paste(bwa.genome, "alignment1.sai alignment2.sai reads1.txt reads2.txt 1> alignment.sam 2>>bwa.log'" )
sampe.command <- paste( command.start, sampe.parameters , sampe.end )
system(sampe.command)

		
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
base1 <- strip_name(inputnames$reads1.txt)
base2 <- strip_name(inputnames$reads2.txt)
basename <- paired_name(base1, base2)

# Make a matrix of output names
outputnames <- matrix(NA, nrow=2, ncol=2)
outputnames[1,] <- c("bwa.bam", paste(basename, ".bam", sep =""))
outputnames[2,] <- c("bwa.bam.bai", paste(basename, ".bam.bai", sep =""))

# Write output definitions file
write_output_definitions(outputnames)