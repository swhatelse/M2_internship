
DAY=`date +%Y_%m_%d`
DIR="$PWD/../data/$DAY"
mkdir -p $DIR
DIR="$DIR/pilipili2"
mkdir -p $DIR
DIR="$DIR/algos"
mkdir -p $DIR
DIR="$DIR/GA"
mkdir -p $DIR
INPUT="$PWD/../data/2016_04_08/pilipili2/18_08_24/test_space_2016_04_02_end_cleaned.yaml"
PARAM="$PWD/../data/2016_04_08/pilipili2/18_08_24/test_space_2016_04_02_parameters_v2.yaml"

for i in `seq 1 100`; do 
    ruby ../boast/optimizer_benchmarks/bench_gen.rb $PARAM $INPUT -r ${DIR}/"$i.yaml" --generations_limit 5 --population_size 20 --mutation_rate 0.1 --elitism 1 --twin_removal true > /dev/null &
done
