WALKTHROUGH=${PWD}/Medaka/medaka_walkthrough_trevor
BASECALLS=data/trevor.fastq


# allowing user to change walkthrough and basecalls 
for i in "$@"
do
case $i in
	--walkthrough=*)
		WALKTHROUGH="${i#*=}"
		shift
	;;
	--basecalls=*)
		BASECALLS="${i#*=}"
		shift
	;;
	*)
	UNKNOWN="${*}"
		echo "unknown symbol ${UNKNOWN}"
		exit 1
	;;
esac
done


# setting starting arguments for pipeline from ONT.
DATA=${WALKTHROUGH}/data
POMOXIS=${WALKTHROUGH}/pomoxis/venv/bin/activate
MEDAKA=${WALKTHROUGH}/medaka/venv/bin/activate
NPROC=$(nproc)

DRAFT=draft_assm/assm_final.fa
CONSENSUS=consensus
TRUTH=${DATA}/truth.fasta

DRAFT2TRUTH=draft_to_truth
CONSENSUS2TRUTH=${CONSENSUS}_to_truth

# =====================================================================
# basic medaka
# =====================================================================
cd ${WALKTHROUGH}
rm -rf draft*
rm -rf consensus*

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


# =====================================================================
# margin polish
# =====================================================================
cd /home/mgaltier

# create margin phase fasta
./MarginPhase/marginPhase/build/marginPolish ${WALKTHROUGH}/consensus/calls_to_draft.bam \
  ${WALKTHROUGH}/${DRAFT} \
  ./MarginPhase/marginPhase/params/allParams.np.json \
  -o marginPhase

# move files that will mess with creating the results 
mkdir ${WALKTHROUGH}/consensusMedakaBasic
mv ${WALKTHROUGH}/consensus ${WALKTHROUGH}/consensusMedakaBasic

cd ${WALKTHROUGH}
source ${POMOXIS}

# see how it compares
assess_assembly -i ../../marginPhase.fa -r data/truth.fasta -p draft_to_truth_margin_polish -t $(nproc)

# =====================================================================
# margin polish + medaka 
# =====================================================================
cd ${WALKTHROUGH}

# move the fasta to the correct directoy
cp ../../marginPhase.fa draft_assm_margin_medaka/.

source ${POMOXIS}
mini_assemble -i ${BASECALLS} -o draft_assm_margin_medaka -p assm -t ${NPROC} -c -e 10

awk '{if(/>/){n=$1}else{print n " " length($0)}}' ${DRAFT}

# move files that will mess with creating the results 
cd ${WALKTHROUGH}
mkdir consensusMarginPhase
mv ./consensus .consensusMarginPhase

cd ${WALKTHROUGH}
source ${MEDAKA}
medaka_consensus -i ${BASECALLS} -d ../../marginPhase.fa -o ${CONSENSUS} -t ${NPROC}

cd ${WALKTHROUGH}
source ${POMOXIS}
echo "Draft assembly"
assess_assembly -i ../../marginPhase.fa -r data/truth.fasta  -p  draft_to_truth_margin_polish_medaaka -t ${NPROC}