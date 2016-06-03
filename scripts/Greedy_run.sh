
DAY=`date +%Y_%m_%d`
DIR="../data/$DAY"
mkdir -p $DIR
DIR="$DIR/pilipili2"
mkdir -p $DIR
DIR="$DIR/algos"
mkdir -p $DIR
DIR="$DIR/GR"
mkdir -p $DIR
INPUT="../data/2016_04_08/pilipili2/18_08_24/test_space_2016_04_02_end_cleaned.yaml"

ruby ../scripts/format_data.rb $INPUT
for i in `seq 1 100`; do 
    Rscript ../scripts/Greedy_experiment.R ${DIR}/"$i.csv" &
done
