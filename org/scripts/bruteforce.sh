#!/bin/bash

help_script()
{
    cat << EOF
    Usage: $0 options

    Script for running StarPU with benchmarking

    OPTIONS:
       -h      Show this message
       -c      Specify the size of the checkpoint
       -d      Detailed data file
       -i      Specify the OpenCL implementation to use
       -s      Specify a seed
    EOF
}

DATA_FILE_DETAILED=""
SEED=""
CHECKPOINT_SIZE=""

while getopts "c:d:hs:" opt; do
    case $opt in
        c)
            CHECKPOINT_SIZE="$OPTARG"
            ;;
        d)
            DATA_FILE_DETAILED="$OPTARG"
            ;;
        h)
            # help_script
            exit 4
            ;;
        i)
            IMPLEM="$OPTARG"
            ;;
        s)
            SEED="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            # help_script
            exit 3
            ;;
    esac
done


BASE="$PWD/.."

DATADIR="$BASE/data"
DATA_FOLD_DAY=`date +%Y_%m_%d`
DATA_FOLD_DAY="$DATADIR/$DATA_FOLD_DAY"
BKUP=`date +%H_%M_%S`
DATA_FOLD_HOST=`hostname`
DATA_FOLD_HOST="$DATA_FOLD_DAY/$DATA_FOLD_HOST"
DATA_FOLD_TIME="$DATA_FOLD_HOST/$BKUP"
mkdir -p $DATADIR
mkdir -p $DATA_FOLD_DAY
mkdir -p $DATA_FOLD_HOST
mkdir -p $DATA_FOLD_TIME
INFO_NAME="Info"
DATA_FILE="Data"
INFO_FILE="$DATA_FOLD_TIME/$INFO_NAME${BKUP}.org"
DATA_FILE="$DATA_FILE${BKUP}"

if [[ $IMPLEM == "NVIDIA" ] || [ $IMPLEM == "CUDA" ]];
then
    CMD="CLPLATFORM=NVIDIA"
elif[[$IMPLEM == "INTEL"]];
then 
    CMD="CLPLATFORM=Intel"
fi

CMD="$CMD VERBOSE=true ruby Laplacian.rb -c"
if [[ $DATA_FILE_DETAILED != "" ]];
then
    if [[ -f $DATA_FILE_DETAILED ]] ; 
    then
        CMD="$CMD -l $DATA_FILE_DETAILED -r >> $INFO_FILE"
    else
        CMD="$CMD -l $DATA_FILE_DETAILED >> $INFO_FILE"
    fi
fi

if [[ $SEED != "" ]] ;
then
    CMD="$CMD -s $SEED"
fi

if [[ $CHECKPOINT_SIZE != "" ]] ;
then
    CMD="$CMD --chksize $CHECKPOINT_SIZE"
fi

CMD="$CMD >> $INFO_FILE"

######### Collecting informations about the platform #########
echo "#+TITLE: Experiment information" >> $INFO_FILE
echo "#+DATE: $(eval date)" >> $INFO_FILE
echo "#+MACHINE: $(eval hostname)" >> $INFO_FILE
echo "#+FILE: $INFO_FILE" >> $INFO_FILE

echo "* ENVIRONMENT INFOS" >> $INFO_FILE

echo "** HARDWARE" >> $INFO_FILE

echo "*** CPU" >> $INFO_FILE
echo "#+BEGIN_EXAMPLE" >> $INFO_FILE
less /proc/cpuinfo >> $INFO_FILE
echo "#+END_EXAMPLE" >> $INFO_FILE

if [[ -n $(command -v nvidia-smi) ]];
then
    echo "*** GPU INFO FROM NVIDIA-SMI" >> $INFO_FILE
    echo "#+BEGIN_EXAMPLE" >> $INFO_FILE    
    nvidia-smi -q >> $INFO_FILE
    echo "#+END_EXAMPLE" >> $INFO_FILE
else
    echo "*** GPU" >> $INFO_FILE
    echo "#+BEGIN_EXAMPLE" >> $INFO_FILE
    lshw -numeric -C display >> $INFO_FILE
    echo "#+END_EXAMPLE" >> $INFO_FILE
fi 

echo "** SOFTWARE" >> $INFO_FILE

if [ -f /proc/version ];
then
    echo "*** LINUX AND GCC VERSIONS" >> $INFO_FILE
    echo "#+BEGIN_EXAMPLE" >> $INFO_FILE    
    cat /proc/version >> $INFO_FILE
    echo "#+END_EXAMPLE" >> $INFO_FILE
fi

echo "*** ENVIRONMENT VARIABLES"  >> $INFO_FILE
echo "#+BEGIN_EXAMPLE" >> $INFO_FILE
env >> $INFO_FILE
echo "#+END_EXAMPLE" >> $INFO_FILE

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ];
then
    echo "*** CPU GOVERNOR" >> $INFO_FILE
    echo "#+BEGIN_EXAMPLE" >> $INFO_FILE    
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor >> $INFO_FILE
    echo "#+END_EXAMPLE" >> $INFO_FILE
fi

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ];
then
    echo "*** CPU FREQUENCY" >> $INFO_FILE
    echo "#+BEGIN_EXAMPLE" >> $INFO_FILE    
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq >> $INFO_FILE
    echo "#+END_EXAMPLE" >> $INFO_FILE
fi

echo "*** SOFTWARES RUNNING"  >> $INFO_FILE
echo "#+BEGIN_EXAMPLE" >> $INFO_FILE
ps -le >> $INFO_FILE
echo "#+END_EXAMPLE" >> $INFO_FILE

echo "*** USERS USING THE SYSTEM"  >> $INFO_FILE
echo "#+BEGIN_EXAMPLE" >> $INFO_FILE
who >> $INFO_FILE
echo "#+END_EXAMPLE" >> $INFO_FILE

####### BOAST installation #######
cd $BASE/boast
gem build *.gemspec
gem install --user-install --no-rdoc --no-ri *.gem

######## Run experiment ########
cd $BASE/boast-lig/ARMclbench
echo "* PROGRAM OUTPUT" >> $INFO_FILE
echo "#+begin_src sh :results output :exports both" >> $INFO_FILE
echo $CMD >> $INFO_FILE    
echo "#+end_src" >> $INFO_FILE
echo "#+BEGIN_EXAMPLE" >> $INFO_FILE    
eval $CMD
echo "#+END_EXAMPLE" >> $INFO_FILE
mv $DATA_FILE'.yaml' $DATA_FOLD_TIME
mv $DATA_FILE'_parameters.yaml' $DATA_FOLD_TIME
