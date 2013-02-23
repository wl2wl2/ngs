#!/bin/bash

# Copyright (c) 2012,2013, Stephen Fisher and Junhyong Kim, University of
# Pennsylvania.  All Rights Reserved.
#
# You may not use this file except in compliance with the Kim Lab License
# located at
#
#     http://kim.bio.upenn.edu/software/LICENSE
#
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License
# for the specific language governing permissions and limitations
# under the License.

##########################################################################################
# SINGLE-END READS:
# INPUT: raw/unaligned_1.fq
# OUTPUT: trimAT/unaligned_1.fq, trimAdapters.stats.txt, trimPolyAT.stats.txt
#         intermediate file trimAD/unaligned_1.fq
# REQUIRES: trimAdaptersSingle.py, trimPolyATSingle.py, FastQC (if fastqc command previously run)
#
# PAIRED-END READS:
# INPUT: raw/unaligned_1.fq and raw/unaligned_2.fq
# OUTPUT: trimAT/unaligned_1.fq and trimAT/unaligned_2.fq, trimAdapters.stats.txt, trimPolyAT.stats.txt
#         intermediate files trimAD/unaligned_1.fq and trimAD/unaligned_2.fq
# REQUIRES: trimAdapters.py, trimPolyAT.py, FastQC (if fastqc command previously run)
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_TRIM="Usage: `basename $0` trim OPTIONS sampleID    --  trim reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_TRIM="Usage: `basename $0` trim [-se] sampleID\n"
ngsHelp_TRIM+="\tRuns trimAdapters.py followed by trimPolyAT.py to trim data. Adapter trimmed data is placed in trimAD while PolyAT trimmed data is placed in trimAT. Trimming must be done in order for RUM to work as it uses the files in trimAT. For single-end reads, use 'trim1' instead of 'trim'. Single-end reads are processed with trimAdaptersSingle.py and trimPolyATSingle.py.\n"
ngsHelp_TRIM+="\tOPTIONS:\n"
ngsHelp_TRIM+="\t\t-se - single-end reads (default: paired-end)"

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# TRIM args: -se (optional), sampleID
##########################################################################################

ngsArgs_TRIM() {
	if [ $# -lt 1 ]; then
		printHelp $COMMAND
		exit 0
	fi
		
	SAMPLE=$1
	
	if [ "$SAMPLE" = "-se" ]; then
	    # got -se flag instead of sample ID
		SE=true
			
		# make sure we still have another argument, which will be the sampleID
		if [ $# -lt 2 ]; then
			printHelp $COMMAND
			exit 0
		else
			SAMPLE=$2
		fi
	fi
}

##########################################################################################
# RUNNING COMMAND ACTION
# TRIM command
##########################################################################################

ngsCmd_TRIM() {
	if $SE; then prnCmd "# BEGIN: TRIMMING SINGLE-END"
	else prnCmd "# BEGIN: TRIMMING PAIRED-END"; fi
		
	# make relevant directory
	if ! $DEBUG; then 
		prnCmd "mkdir $SAMPLE/trimAD $SAMPLE/trimAT"
		if [ ! -d $SAMPLE/trimAD ]; then mkdir $SAMPLE/trimAD; fi
		if [ ! -d $SAMPLE/trimAT ]; then mkdir $SAMPLE/trimAT; fi
	fi
	
	if $SE; then
		# single-end
		prnCmd "trimAdaptersSingle.py $SAMPLE/raw/unaligned_1.fq $SAMPLE/trimAD > $SAMPLE/trimAdapter.stats.txt"
		if ! $DEBUG; then 
			trimAdaptersSingle.py $SAMPLE/raw/unaligned_1.fq $SAMPLE/trimAD > $SAMPLE/trimAdapter.stats.txt
		fi
		
		prnCmd "trimPolyATSingle.py $SAMPLE/trimAD/unaligned_1.fq $SAMPLE/trimAT > $SAMPLE/trimPolyAT.stats.txt"
		if ! $DEBUG; then 
			trimPolyATSingle.py $SAMPLE/trimAD/unaligned_1.fq $SAMPLE/trimAT > $SAMPLE/trimPolyAT.stats.txt
		fi
	else
		# paired-end
		prnCmd "trimAdapters.py $SAMPLE/raw/unaligned_1.fq $SAMPLE/raw/unaligned_2.fq $SAMPLE/trimAD > $SAMPLE/trimAdapter.stats.txt"
		if ! $DEBUG; then 
			trimAdapters.py $SAMPLE/raw/unaligned_1.fq $SAMPLE/raw/unaligned_2.fq $SAMPLE/trimAD > $SAMPLE/trimAdapter.stats.txt
		fi
		
		prnCmd "trimPolyAT.py $SAMPLE/trimAD/unaligned_1.fq $SAMPLE/trimAD/unaligned_2.fq $SAMPLE/trimAT > $SAMPLE/trimPolyAT.stats.txt"
		if ! $DEBUG; then 
			trimPolyAT.py $SAMPLE/trimAD/unaligned_1.fq $SAMPLE/trimAD/unaligned_2.fq $SAMPLE/trimAT > $SAMPLE/trimPolyAT.stats.txt
		fi
	fi
	
	# if we ran fastqc on raw data (ie $SAMPLE/fastqc exists), then
	# also run on trimmed data. Put this fastqc output in separate
	# directory so it doesn't squash the output from raw
	if [ -d $SAMPLE/fastqc ]; then 
		if [ ! -d $SAMPLE/fastqc.trim ]; then 
			prnCmd "mkdir $SAMPLE/fastqc.trim"
			if ! $DEBUG; then mkdir $SAMPLE/fastqc.trim; fi
		fi
		prnCmd "fastqc --OUTDIR=$SAMPLE/fastqc.trim $SAMPLE/trimAT/unaligned_1.fq"
		if ! $DEBUG; then 
			fastqc --noextract --OUTDIR=$SAMPLE/fastqc.trim $SAMPLE/trimAT/unaligned_1.fq
			
			# do some cleanup of the output files
			prnCmd "mv $SAMPLE/fastqc.trim/unaligned_1.fq_fastqc.zip $SAMPLE/fastqc.trim/$SAMPLE.fastqc.zip"
			mv $SAMPLE/fastqc.trim/unaligned_1.fq_fastqc.zip $SAMPLE/fastqc.trim/$SAMPLE.fastqc.zip
		fi
	fi
	
	if $SE; then prnCmd "# FINISHED: TRIMMING SINGLE-END"
	else prnCmd "# FINISHED: TRIMMING PAIRED-END"; fi
}
