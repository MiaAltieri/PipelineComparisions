# this script will compare results from Medaka and Margin Polish in
# various combinations.
# To run this create a folder which has folders:
#   -  MarginPolish
#   -  Medaka 
# inside, also be certain that Medaka has two folders:
#	-  medaka_walkthroguh
#   -  medaka_walkthrough_trevor
# medaka_walkthrough should have a folder called data containing trevor.fastq

# compares Margin Polish and Medaka with Medaka’s e_coli file as the read file

RESULTS=${PWD}/PipelineComp.txt

echo "Comparing with Medaka Draft---------------------------------------" >> ${RESULTS}
bash ./PipelineComparisions.sh

# compares Margin Polish and Medaka with Trevors’s e_coli file as the read file
echo "Comparing with Trevor's Draft-------------------------------------" >>  ${RESULTS}
bash ./PipelineComparisions.sh --walkthrough=${PWD}/Medaka/medaka_walkthrough_trevor --basecalls=data/trevor.fastq
