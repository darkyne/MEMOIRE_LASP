#!/bin/bash

decalage=7
localNodes=5
iterations=1
duration=30

echo "launching the script"


#Remove potential artefact and Load experiment2
#rm ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src/lasp_app.erl
sleep 2
cp ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/SavedApps/measure1/lasp_app.erl ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src

sleep $decallage #Wait for slow raspberry pi to launch node
for j in $(seq 1 1 "$iterations") #number of iterations
do

	for i in $(seq 1 1 "$localNodes") #number of local nodes
	do
		xterm -hold -e "echo one new shell opened && rebar3 shell --name node$i@192.168.1.39" &
	done
	sleep $duration
	killall xterm
	sleep 1
done

echo "experiment1 finished"
rm ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src/lasp_app.erl
sleep 2

#########################################################################################################################################################
#########################################################################################################################################################

#Load experiment2
cp ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/SavedApps/measure2/lasp_app.erl ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src
echo "launching experiment2"

sleep $decallage #Wait for slow raspberry pi to launch node
for j in $(seq 1 1 "$iterations") #number of iterations
do

	for i in $(seq 1 1 "$localNodes") #number of local nodes
	do
		xterm -hold -e "echo one new shell opened && rebar3 shell --name node$i@192.168.1.39" &
	done
	sleep $duration
	killall xterm
	sleep 1
done

echo "experiment2 finished"
rm ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src/lasp_app.erl
sleep 2

#########################################################################################################################################################
#########################################################################################################################################################

#Load experiment3
cp ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/SavedApps/measure3/lasp_app.erl ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src
echo "launching experiment3"

sleep $decallage #Wait for slow raspberry pi to launch node
for j in $(seq 1 1 "$iterations") #number of iterations
do

	for i in $(seq 1 1 "$localNodes") #number of local nodes
	do
		xterm -hold -e "echo one new shell opened && rebar3 shell --name node$i@192.168.1.39" &
	done
	sleep $duration
	killall xterm
	sleep 1
done

echo "experiment3 finished"
rm ~/Documents/MEMOIRE/LaspDivergenceVisualization/lasp/src/lasp_app.erl
sleep 2

#########################################################################################################################################################
#########################################################################################################################################################


