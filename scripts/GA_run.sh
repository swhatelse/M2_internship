
DAY=`date +%Y_%m_%d`
DIR="../data/$DAY"
mkdir -p $DIR
DIR="$DIR/pilipili2"
mkdir -p $DIR
DIR="$DIR/algos"
mkdir -p $DIR
DIR="$DIR/GA"
mkdir -p $DIR
INPUT="../data/2016_04_08/pilipili2/18_08_24/test_space_2016_04_02_end_cleaned.yaml"
PARAM="../data/2016_04_08/pilipili2/18_08_24/test_space_2016_04_02_parameters_v2.yaml"

for i in `seq 1 100`; do 
  START=$(date +%s)
  ../scripts/GA_experiment.sh $INPUT $PARAM ${DIR}/"$i.yaml"
  END=$(date +%s)
done
echo $(($END-$START))
