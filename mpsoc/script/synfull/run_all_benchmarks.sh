#!/bin/dash

logdest=/home/neiel/2022_phd/pronoc_synfull/dev_pronoc_synfull/pronoc/mpsoc/script/synfull/log_files
modelsroute=/home/neiel/2022_phd/pronoc_synfull/dev_pronoc_synfull/pronoc/mpsoc/src_c/synfull/generated-models
smartmax=0

model_list=\
'barnes 
blackscholes
bodytrack       
cholesky        
facesim         
fft             
fluidanimate    
lu_cb           
lu_ncb          
radiosity       
radix           
raytrace        
swaptions       
volrend         
water_nsquared  
water_spatial
'

for model in $model_list
do
    echo "*** $model ***\n" 
    ./run_modelsim -batch > $logdest/$model.$smartmax.sim.log &
    echo "$model was issue.. "
    sleep 3m
    ./tgen $modelsroute/$model.model 10000000 0 100000 > $logdest/$model.$smartmax.tgen.log & 
    echo "tgen for $model was issue.. "
    wait
done


