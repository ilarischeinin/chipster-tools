# TOOL tophat2-single-end.R: "TopHat2 for single end reads" (Aligns Illumina RNA-seq reads to a genome in order to identify exon-exon splice junctions. The alignment process consists of several steps. If annotation is available as a GTF file, TopHat will extract the transcript sequences and use Bowtie to align reads to this virtual transcriptome first. Only the reads that do not fully map to the transcriptome will then be mapped on the genome. The reads that still remain unmapped are split into shorter segments, which are then aligned to the genome. Alignment results are given in a BAM file, which is automatically indexed and hence ready to be viewed in Chipster genome browser.)
# INPUT reads{...}.fq: "Reads to align" TYPE GENERIC
# INPUT OPTIONAL genes.gtf: "Optional GTF file" TYPE GENERIC
# OUTPUT OPTIONAL tophat.bam
# OUTPUT OPTIONAL tophat.bam.bai
# OUTPUT OPTIONAL junctions.bed
# OUTPUT OPTIONAL tophat-summary.txt
# OUTPUT OPTIONAL tophat2.log
# PARAMETER organism: "Genome" TYPE [Arabidopsis_thaliana.TAIR10.30, Bos_taurus.UMD3.1.83, Canis_familiaris.CanFam3.1.83, Drosophila_melanogaster.BDGP6.83, Felis_catus.Felis_catus_6.2.83, Gallus_gallus.Galgal4.83, Gasterosteus_aculeatus.BROADS1.83, Halorubrum_lacusprofundi_atcc_49239.GCA_000022205.1.30, Homo_sapiens.GRCh37.75, Homo_sapiens.GRCh38.83, Medicago_truncatula.GCA_000219495.2.30, Mus_musculus.GRCm38.83, Oryza_sativa.IRGSP-1.0.30, Ovis_aries.Oar_v3.1.83, Populus_trichocarpa.JGI2.0.30, Rattus_norvegicus.Rnor_5.0.79, Rattus_norvegicus.Rnor_6.0.83, Schizosaccharomyces_pombe.ASM294v2.30, Solanum_tuberosum.3.0.30, Sus_scrofa.Sscrofa10.2.83, Vitis_vinifera.IGGP_12x.30, Yersinia_enterocolitica_subsp_palearctica_y11.GCA_000253175.1.30, Yersinia_pseudotuberculosis_ip_32953_gca_000834295.GCA_000834295.1.30] DEFAULT Homo_sapiens.GRCh38.83 (Genome or transcriptome that you would like to align your reads against.)
# PARAMETER library.type: "Library type" TYPE [fr-unstranded: fr-unstranded, fr-firststrand: fr-firststrand, fr-secondstrand: fr-secondstrand] DEFAULT fr-unstranded (Which library type to use. For directional\/strand specific library prepartion methods, choose fr-firststrand or fr-secondstrand depending on the preparation method: if the first read \(read1\) maps to the opposite, non-coding strand, choose fr-firststrand. If the first read maps to the coding strand, choose fr-secondstrand. For example for Illumina TruSeq Stranded sample prep, choose fr-firstsrand.)
# PARAMETER OPTIONAL use.gtf: "Use internal annotation GTF" TYPE [yes, no] DEFAULT yes (If this option is selected, TopHat will extract the transcript sequences and use Bowtie to align reads to this virtual transcriptome first. Only the reads that do not fully map to the transcriptome will then be mapped on the genome. The reads that did map on the transcriptome will be converted to genomic mappings (spliced as needed\) and merged with the novel mappings and junctions in the final TopHat output. If user provides a GTF file it is used instead of the internal annotation.)
# PARAMETER OPTIONAL no.novel.juncs: "When GTF file is used, ignore novel junctions" TYPE [yes, no] DEFAULT no (Only look for reads across junctions indicated in the supplied GTF file.)
# PARAMETER OPTIONAL quality.format: "Base quality encoding used" TYPE [sanger: "Sanger - Phred+33", phred64: "Phred+64"] DEFAULT sanger (Quality encoding used in the fastq file.)
# PARAMETER OPTIONAL max.multihits: "How many hits is a read allowed to have" TYPE INTEGER FROM 1 TO 1000000 DEFAULT 20 (Instructs TopHat to allow up to this many alignments to the reference for a given read.)
# PARAMETER OPTIONAL mismatches: "Number of mismatches allowed in final alignment" TYPE INTEGER FROM 0 TO 5 DEFAULT 2 (Final read alignments having more than this many mismatches are discarded.)
# PARAMETER OPTIONAL min.anchor.length: "Minimum anchor length" TYPE INTEGER FROM 3 TO 1000 DEFAULT 8 (TopHat will report junctions spanned by reads with at least this many bases on each side of the junction. Note that individual spliced alignments may span a junction with fewer than this many bases on one side. However, every junction involved in spliced alignments is supported by at least one read with this many bases on each side.)
# PARAMETER OPTIONAL splice.mismatches: "Maximum number of mismatches allowed in the anchor" TYPE INTEGER FROM 0 TO 2 DEFAULT 0 (The maximum number of mismatches that may appear in the anchor region of a spliced alignment.)
# PARAMETER OPTIONAL min.intron.length: "Minimum intron length" TYPE INTEGER FROM 10 TO 1000 DEFAULT 70 (TopHat will ignore donor-acceptor pairs closer than this many bases apart.)
# PARAMETER OPTIONAL max.intron.length: "Maximum intron length" TYPE INTEGER FROM 1000 TO 1000000 DEFAULT 500000 (TopHat will ignore donor-acceptor pairs farther than this many bases apart, except when such a pair is supported by a split segment alignment of a long read.)

# EK 17.4.2012 added -G and -g options
# MG 24.4.2012 added ability to use gtf files from Chipster server
# AMS 19.6.2012 added unzipping
# AMS 4.10.2012 added BED sorting
# AMS 4.2.2013 added option to use no GTF
# AMS 11.11.2013 added thread support
# AMS 3.1.2014 added transcriptome index for human
# EK 3.1.2014 added alignment summary to output, added quality and mismatch parameter
# EK 3.6.2014 rn4 commented out
# AMS 04.07.2014 New genome/gtf/index locations & names
# ML 15.01.2015 Added the library-type parameter
# AMS 29.01.2015 Removed optional outputs deletions.bed and insertions.bed

# check out if the file is compressed and if so unzip it
source(file.path(chipster.common.path, "zip-utils.R"))

input.names <- read.table("chipster-inputs.tsv", header=F, sep="\t")
for (i in 1:nrow(input.names)) {
	unzipIfGZipFile(input.names[i,1])	
}

options(scipen = 10)
# max.intron.length <- formatC(max.intron.length, "f", digits = 0)

# setting up TopHat
tophat.binary <- c(file.path(chipster.tools.path, "tophat2", "tophat2"))
path.bowtie <- c(file.path(chipster.tools.path, "bowtie2"))
path.samtools <- c(file.path(chipster.tools.path, "samtools"))
set.path <-paste(sep="", "PATH=", path.bowtie, ":", path.samtools, ":$PATH")
path.bowtie.index <- c(file.path(chipster.tools.path, "genomes", "indexes", "bowtie2", organism))
path.tophat.index <- c(file.path(chipster.tools.path, "genomes", "indexes", "tophat2", organism))


# command start
command.start <- paste("bash -c '", set.path, tophat.binary)

# parameters
#command.parameters <- paste("-p", chipster.threads.max, "--read-mismatches", mismatches, "-a", min.anchor.length, "-m", splice.mismatches, "-i", min.intron.length, "-I", max.intron.length, "-g", max.multihits, "--library-type fr-unstranded")
command.parameters <- paste("-p", chipster.threads.max, "--read-mismatches", mismatches, "-a", min.anchor.length, "-m", splice.mismatches, "-i", min.intron.length, "-I", max.intron.length, "-g", max.multihits, "--library-type", library.type)
# command.parameters <- paste("-p", chipster.threads.max, "--read-mismatches", mismatches, "-a", min.anchor.length, "-m", splice.mismatches, "-i", min.intron.length, "-I", max.intron.length, "-g", max.multihits)


if (mismatches > 2){
	command.parameters <- paste(command.parameters, "--read-edit-dist", mismatches)
}

if ( quality.format == "phred64") {
	command.parameters <- paste(command.parameters, "--phred64-quals")
}

# Determine whether GTF file or internal transcriptome index should be used.
# Option --no-novel-juncs is only valid when -G or --transcriptome-index option is used.
nnj.usable <- FALSE
if (file.exists("genes.gtf")){
	# If user has provided a gtf we use it
	command.parameters <- paste(command.parameters, "-G genes.gtf")
	nnj.usable <- TRUE
}else if (use.gtf == "yes") {
	# if no GTF file is provided, but use.gtf is selected, use an internal transcriptome index
	command.parameters <- paste(command.parameters, "--transcriptome-index", path.tophat.index)
	nnj.usable <- TRUE
}
if (nnj.usable) {
	if (no.novel.juncs == "yes") {
		command.parameters <- paste(command.parameters, "--no-novel-juncs")
	}	
}


# Input fastq names
reads1 <- paste(grep("reads", input.names[,1], value = TRUE), sep="", collapse=",")

# command ending
command.end <- paste(path.bowtie.index, reads1, "2>> tophat.log'")

# run tophat
command <- paste(command.start, command.parameters, command.end)

echo.command <- paste("echo '",command ,"' 2>> tophat.log " )
system(echo.command)
system("echo >> tophat.log")
#stop(paste('CHIPSTER-NOTE: ', command))

system(command)

# samtools binary
samtools.binary <- c(file.path(chipster.tools.path, "samtools", "samtools"))

# sort bam (removed because TopHat itself does the sorting)
# system(paste(samtools.binary, "sort tophat_out/accepted_hits.bam tophat"))

system("mv tophat_out/accepted_hits.bam tophat.bam") 


# index bam
system(paste(samtools.binary, "index tophat.bam"))

system("mv tophat_out/junctions.bed junctions.u.bed")
system("mv tophat_out/insertions.bed insertions.u.bed")
system("mv tophat_out/deletions.bed deletions.u.bed")
system("mv tophat_out/align_summary.txt tophat-summary.txt")

# sorting BEDs
source(file.path(chipster.common.path, "bed-utils.R"))

if (file.exists("junctions.u.bed")){
	size <- file.info("junctions.u.bed")$size
	if (size > 100){	
		bed <- read.table(file="junctions.u.bed", skip=1, sep="\t")
		colnames(bed)[1:2] <- c("chr", "start")
		sorted.bed <- sort.bed(bed)
		write.table(sorted.bed, file="junctions.bed", sep="\t", row.names=F, col.names=F, quote=F)
	}	
}

if (file.exists("insertions.u.bed")){
	size <- file.info("insertions.u.bed")$size
	if (size > 100){
		bed <- read.table(file="insertions.u.bed", skip=1, sep="\t")
		colnames(bed)[1:2] <- c("chr", "start")
		sorted.bed <- sort.bed(bed)
		write.table(sorted.bed, file="insertions.bed", sep="\t", row.names=F, col.names=F, quote=F)
	}
}

if (file.exists("deletions.u.bed")){
	size <- file.info("deletions.u.bed")$size
	if (size > 100){
		bed <- read.table(file="deletions.u.bed", skip=1, sep="\t")
		colnames(bed)[1:2] <- c("chr", "start")
		sorted.bed <- sort.bed(bed)
		write.table(sorted.bed, file="deletions.bed", sep="\t", row.names=F, col.names=F, quote=F)
	}
}

if (!(file.exists("tophat-summary.txt"))){
	#system("mv tophat_out/logs/tophat.log tophat2.log")
	system("mv tophat.log tophat2.log")
}

# Handle output names
source(file.path(chipster.common.path, "tool-utils.R"))

# read input names
inputnames <- read_input_definitions()

# Determine base name
basename <- strip_name(inputnames$reads001.fq)

# Make a matrix of output names
outputnames <- matrix(NA, nrow=2, ncol=2)
outputnames[1,] <- c("tophat.bam", paste(basename, ".bam", sep =""))
outputnames[2,] <- c("tophat.bam.bai", paste(basename, ".bam.bai", sep =""))

# Write output definitions file
write_output_definitions(outputnames)

#EOF