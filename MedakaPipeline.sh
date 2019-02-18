# the purpose of this script is to create a draft assembly
# and polish a consensus as medaka does. It does not give
# the alignment statistics as that is what happy does

# This script assumes the following:
# 	- that you have downloaded the training data
#		WALKTHROUGH=${PWD}/medaka_walkthrough
#		mkdir -p ${WALKTHROUGH} && cd ${WALKTHROUGH}
#		wget https://s3-eu-west-1.amazonaws.com/ont-research/medaka_walkthrough_no_reads.tar.gz
#		tar -xvf medaka_walkthrough_no_reads.tar.gz
#		DATA=${PWD}/data
#	- you have clone promoxis
#		git clone https://github.com/nanoporetech/pomoxis --recursive
#	- you have cloned medaka
#		git clone https://github.com/nanoporetech/medaka
#	- you have `make install`d both
#		cd pomoxis && make install && cd ..
#		cd medaka && make install && cd ..


# setting default arguments
WALKTHROUGH=${PWD}/medaka_walkthrough
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

# handeling arguments
for i in "$@"
do
case $i in
  --help*)
  echo 
  "These are the medk pipeline options:
      --walkthrough=<path_name> specifies the walkthrough path_name 
          - defaults to ${PWD}/medaka_walkthrough
      --data=<path_name> specifies the data directory 
          - defaults to ${WALKTHROUGH}/data
      --promoxis=<path_name> specifies the location of promoxis 
          - defaults to ${WALKTHROUGH}/pomoxis/venv/bin/activate
      --medaka=<path_name> specifies the location of medaka
          - defaults to ${WALKTHROUGH}/medaka/venv/bin/activate
      --threads=<int> specifies number of threads
          - defaults to $(nproc) 
      --basecalls=<path_name> specifies the location of basecalls
          - defaults to data/basecalls.fa
      --draft=<path_name> specifies the location of the draft
          - defaults to draft_assm/assm_final.fa
      --consensus=<path_name> specifies the consensus directory
          - defaults to consensus
      --truth=<path_name> specifies the truth file
          - defaults to ${DATA}/truth.fasta
      --draft2truth=<path_name> specifies draft2truth folder
          - defaults to draft_to_truth
      --consensus2truth=<path_name> specifies consensus2truth folder
          - defaults to ${CONSENSUS}_to_truth
    "
    exit 1
    ;;
    --walkthrough=*)
    WALKTHROUGH="${i#*=}"
    shift
    ;;
    --data=*)
    DATA="${i#*=}"
    shift
    ;;
    --promoxis=*)
    POMOXIS="${i#*=}"
    shift
    ;;
    --medaka=*)
    MEDAKA="${i#*=}"
    shift
    ;;
    --threads=*)
    NPROC="${i#*=}"
    shift
    ;;
    --basecalls=*)
    BASECALLS="${i#*=}"
    shift
    ;;
    --draft=*)
    DRAFT="${i#*=}"
    shift
    ;;
    --consensus=*)
    CONSENSUS="${i#*=}"
    shift
    ;;
    --truth=*)
    TRUTH="${i#*=}"
    shift 
    ;;
    --draft2truth=*)
    DRAFT2TRUTH="${i#*=}"
    shift 
    ;;
    --consensus2truth=*)
    CONSENSUS2TRUTH="${i#*=}"
    shift 
    ;;
    *)
    UNKNOWN="${*}"
    echo "unknown symbol ${UNKNOWN}"
    echo 
    "usage: deep_variant_pipeline.sh [--help] [--walkthrough=<path_name>] [--data=<path_name>]
    [--promoxis=<path_name>] [--medaka=<path_name>] [--threads=<int>] [--basecalls=<path_name>]
    [--draft=<path_name>] [--consensus=<path_name>] [--truth=<path_name>] [--draft2truth=<path_name>]
    [--consensus2truth=<path_name>]
    "
    exit 1
    ;;
esac
done



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
