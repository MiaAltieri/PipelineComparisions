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


BASECALLS=data/trevor.fastq
DRAFT=draft_assm_trevor/assm_final.fa
CONSENSUS=consensus_trevor
TRUTH=${DATA}/truth.fasta

DRAFT2TRUTH=draft_to_truth_trevor
CONSENSUS2TRUTH=${CONSENSUS}_to_truth_trevor

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
MARGINPHASEFASTA=marginPhase_trevor
MARGINTRUTH=draft_to_truth_margin_polish_trevor

./MarginPhase/marginPhase/build/marginPolish  ./Medaka/medaka_walkthrough/consensus_trevor/calls_to_draft.bam \
  ./Medaka/medaka_walkthrough/${DRAFT} \
  ./MarginPhase/marginPhase/params/allParams.np.json \
  -o ${MARGINPHASEFASTA}

# move files that will mess with creating the results 
mkdir ./Medaka/medaka_walkthrough/consensusMedakaBasic
mv ./Medaka/medaka_walkthrough/consensus_trevor ./Medaka/medaka_walkthrough/consensus_trevorMedakaBasic

cd ${WALKTHROUGH}
source ${POMOXIS}

# see how it compares
echo "Draft assembly"
assess_assembly -i ../../marginPhase.fa -r data/truth.fasta -p draft_to_truth_trevor_margin_polish -t $(nproc)



# =====================================================================
# margin polish + medaka 
# =====================================================================
echo "Margin Polish + Medaka" > ${OUTPUT}

cd /home/mgaltier
cd ${WALKTHROUGH}

cp ../../marginPhase.fa draft_assm_trevor_margin_medaka/.

source ${POMOXIS}
mini_assemble -i ${BASECALLS} -o draft_assm_trevor_margin_medaka -p assm -t ${NPROC} -c -e 10

awk '{if(/>/){n=$1}else{print n " " length($0)}}' ${DRAFT}

# move files that will mess with creating the results 
cd ${WALKTHROUGH}
mkdir consensus_trevorMarginPhase
mv ./consensus_trevor .consensus_trevorMarginPhase

source ${MEDAKA}
medaka_consensus -i ${BASECALLS} -d ../../marginPhase.fa -o ${CONSENSUS} -t ${NPROC}

source ${POMOXIS}
echo "Draft assembly"
assess_assembly -i ../../marginPhase.fa -r data/truth.fasta  -p  draft_to_truth_trevor_margin_polish_medaaka -t ${NPROC}