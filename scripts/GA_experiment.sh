
INPUT="$1"
PARAM="$2"
OUTPUT="$3"
for i in `seq 1 100`; do
    ruby ../boast/optimizer_benchmarks/bench_optimizer.rb $PARAM $INPUT -r $OUTPUT --generations_limit 5 --population_size 20 --mutation_rate 0.1 --elitism 1 --twin_removal true > /dev/null
done
