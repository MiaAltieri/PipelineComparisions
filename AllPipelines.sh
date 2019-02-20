# This script assumes the following:
# 	- that you have downloaded the training data
#		WALKTHROUGH=${PWD}/medaka_walkthrough
#		mkdir -p ${WALKTHROUGH} && cd ${WALKTHROUGH}
#		wget https://s3-eu-west-1.amazonaws.com/ont-research/medaka_walkthrough_no_reads.tar.gz
#		tar -xvf medaka_walkthrough_no_reads.tar.gz
#		DATA=${PWD}/data
#	- you have cloned promoxis
#		git clone https://github.com/nanoporetech/pomoxis --recursive
#	- you have cloned medaka
#		git clone https://github.com/nanoporetech/medaka
#	- you have `make install`d both
#		cd pomoxis && make install && cd ..
#		cd medaka && make install && cd ..


OUTPUT=medaka_margin_comp.txt

echo "=====================================================================" > ${OUTPUT}
echo "data from ONT" > ${OUTPUT}
echo "=====================================================================" > ${OUTPUT}

# setting starting arguments for pipeline from ONT.
WALKTHROUGH=${PWD}/Medaka/medaka_walkthrough
DATA=${WALKTHROUGH}/data
POMOXIS=${WALKTHROUGH}/pomoxis/venv/bin/activate
MEDAKA=${WALKTHROUGH}/medaka/venv/bin/activate
NPROC=$(nproc)

BASECALLS=data/basecalls.fa
DRAFT=draft_assm/assm_final.fa
CONSENSUS=consensus
TRUTH=${DATA}/truth.fasta

DRAFT2TRUTH=draft_to_truth
CONSENSUS2TRUTH=${CONSENSUS}_to_truth

# =====================================================================
# basic medaka
# =====================================================================
echo "Basic Medaka" > ${OUTPUT}
cd ${WALKTHROUGH}

source ${POMOXIS}
mini_assemble -i ${BASECALLS} -o draft_assm -p assm -t ${NPROC} -c -e 10

awk '{if(/>/){n=$1}else{print n " " length($0)}}' ${DRAFT}

cd ${WALKTHROUGH}
source ${MEDAKA}
medaka_consensus -i ${BASECALLS} -d ${DRAFT} -o ${CONSENSUS} -t ${NPROC}

cd ${WALKTHROUGH}
source ${POMOXIS}
echo "Draft assembly"
assess_assembly -i ${DRAFT} -r ${TRUTH} -p ${DRAFT2TRUTH} -t ${NPROC}
echo "Medaka consensus"
assess_assembly -i ${CONSENSUS}/consensus.fasta -r ${TRUTH} -p ${CONSENSUS2TRUTH} -t ${NPROC}

cd /../../

# =====================================================================
# flip flop medaka
# =====================================================================
echo "Flip Flop Medaka" > ${OUTPUT}

# =====================================================================
# margin polish
# =====================================================================
echo "Margin Polish" > ${OUTPUT}

cd /home/mgaltier
# create margin phase fasta
MARGINPHASEFASTA=marginPhase
MARGINTRUTH=draft_to_truth_margin_polish



./MarginPhase/marginPhase/build/marginPolish  ./Medaka/medaka_walkthrough/consensus/calls_to_draft.bam \
  ./Medaka/medaka_walkthrough/${DRAFT} \
  ./MarginPhase/marginPhase/params/allParams.np.json \
  -o ${MARGINPHASEFASTA}

# remove files that will mess with creating the results 
mkdir ./Medaka/medaka_walkthrough/consensus2
mv ./Medaka/medaka_walkthrough/consensus ./Medaka/medaka_walkthrough/consensus2

cd ${WALKTHROUGH}
source ${POMOXIS}

# see how it compares
echo "Draft assembly"
assess_assembly -i ${MARGINPHASEFASTA}.fa -r ${TRUTH} -p ${MARGINTRUTH} -t ${NPROC}

# echo "Medaka consensus"
# assess_assembly -i ${CONSENSUS}/consensus.fasta -r ${TRUTH} -p ${CONSENSUS2TRUTH} -t ${NPROC}

# =====================================================================
# margin polish + medaka 
# =====================================================================
echo "Margin Polish + Medaka" > ${OUTPUT}

rm -rf ./Medaka/medaka_walkthrough/consensus

cd /home/mgaltier
cd ${WALKTHROUGH}
source ${MEDAKA}
medaka_consensus -i ${BASECALLS} -d ${MARGINPHASEFASTA}.fa -o ${CONSENSUS} -t ${NPROC}

cd ${WALKTHROUGH}
source ${POMOXIS}
echo "Draft assembly"
assess_assembly -i ${MARGINPHASEFASTA}.fa -r ${TRUTH}  -p ${DRAFT2TRUTH} -t ${NPROC}
# echo "Medaka consensus"
# assess_assembly -i ${CONSENSUS}/consensus.fasta -r ${TRUTH} -p ${CONSENSUS2TRUTH} -t ${NPROC}



# # working with other data
# echo "=====================================================================" > ${OUTPUT}
# echo "data from Trevor" > ${OUTPUT}
# echo "=====================================================================" > ${OUTPUT}

# # setting starting arguments for pipeline from Trevor.
# WALKTHROUGH=${PWD}/medaka_walkthrough
# DATA=${WALKTHROUGH}/data
# POMOXIS=${WALKTHROUGH}/pomoxis/venv/bin/activate
# MEDAKA=${WALKTHROUGH}/medaka/venv/bin/activate
# NPROC=$(nproc)

# BASECALLS=data/basecalls.fa
# DRAFT=draft_assm/assm_final.fa
# CONSENSUS=consensus
# TRUTH=${DATA}/truth.fasta

# DRAFT2TRUTH=draft_to_truth
# CONSENSUS2TRUTH=${CONSENSUS}_to_truth

# # =====================================================================
# # basic medaka
# # =====================================================================
# echo "Basic Medaka" > ${OUTPUT}
# cd ${WALKTHROUGH}

# source ${POMOXIS}
# mini_assemble -i ${BASECALLS} -o draft_assm -p assm -t ${NPROC} -c -e 10

# awk '{if(/>/){n=$1}else{print n " " length($0)}}' ${DRAFT}

# cd ${WALKTHROUGH}
# source ${MEDAKA}
# medaka_consensus -i ${BASECALLS} -d ${DRAFT} -o ${CONSENSUS} -t ${NPROC}

# cd ${WALKTHROUGH}
# source ${POMOXIS}
# echo "Draft assembly"
# assess_assembly -i ${DRAFT} -r ${TRUTH} -p ${DRAFT2TRUTH} -t ${NPROC}
# echo "Medaka consensus"
# assess_assembly -i ${CONSENSUS}/consensus.fasta -r ${TRUTH} -p ${CONSENSUS2TRUTH} -t ${NPROC}



# # =====================================================================
# # flip flop medaka
# # =====================================================================
# echo "Flip Flop Medaka" > ${OUTPUT}

# # =====================================================================
# # margin polish
# # =====================================================================
# echo "Margin Polish" > ${OUTPUT}

# MARGINPHASEFASTA = marginPhase.fa
# ./MarginPhase/marginPhase/build/marginPolish ./Medaka/medaka_walkthrough/consensus/calls_to_draft.bam \
#   ${DRAFT} \
#   ./MarginPhase/marginPhase/params/allParams.np.json \
#   -o ${MARGINPHASEFASTA}

# rm ./medaka_walkthrough/consensus/consensus_probs.hdf
# rm ./medaka_walkthrough/consensus/consensus.fasta
# rm ./medaka_walkthrough/consensus/calls_to_draft.bam
# rm -rf ./medaka_walkthrough/consensus

# # =====================================================================
# # margin polish + medaka 
# # =====================================================================
# echo "Margin Polish + Medaka" > ${OUTPUT}

# cd ${WALKTHROUGH}
# source ${MEDAKA}
# medaka_consensus -i ${BASECALLS} -d ${MARGINPHASEFASTA} -o ${CONSENSUS} -t ${NPROC}

# cd ${WALKTHROUGH}
# source ${POMOXIS}
# echo "Draft assembly"
# assess_assembly -i ${MARGINPHASEFASTA} -r ${TRUTH}  -p ${DRAFT2TRUTH} -t ${NPROC}
# echo "Medaka consensus"
# assess_assembly -i ${CONSENSUS}/consensus.fasta -r ${TRUTH} -p ${CONSENSUS2TRUTH} -t ${NPROC}


# cat OUTPUT