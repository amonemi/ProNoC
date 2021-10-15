#!/bin/bash
SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

models_dir="$HOME/pronoc_verify/mpsoc_work/verify/work"



#get the list of models and traces
models=()
traces=() 
for model in $models_dir/*/; do
    name="$(basename "$model")"
    models+=("$name")   
done

for trace in $SCRPT_DIR_PATH/trace/*; do
    traces+=("$trace") 
echo $trace  
done





echo "step 1 copy bin files from $models_dir"
for model in ${models[@]}
do
	cp "$models_dir/$model/obj_dir/testbench" "$SCRPT_DIR_PATH/models/$model"
done



cd "$SCRPT_DIR_PATH/models"

echo "step 2 run each trace for all models in parallel $models_dir"
for trace in ${traces[@]}
do
	name="$(basename "$trace")"
	mkdir -p $SCRPT_DIR_PATH/results/$name


	echo "run simulation on  $trace"
	for model in ${models[@]}
	do
		cmd="./$model -v 0 -F $trace -T 4 -n 2000000 -r 2"  
		result=$SCRPT_DIR_PATH/results/$name/$model
                echo $cmd
		stdbuf -o0 $cmd 2>&1 | tee $result &
		
	done

	wait;
	exit
done
