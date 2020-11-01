
-module(lasp_convergence_measure).
-author("Gregory Creupelandt <gregory.creupelandt@student.uclouvain.be>").

-export([launchExperimentAdding/8,
         launchExperimentRemoving/8,
		 simpleAddition/0
         ]).


%% ===================================================================
%% launchExperimentAdding:
%% ===================================================================


%Launch an "adding" experiment for the current node
% IN:
%Specify a number for the experiment (used to write the result file)
%Specify the node to join to create the cluster
%Specify a CRDT_ID (format as <<"setX">>)
%Specify the Total Number of Nodes taking part of the experiment
%Specify the Sending Speed (as the number of ms between each send, considering one node), 0 means the fastest possible
%Specify the Number of Values each node will have to generate and send on the CRDT
%Specify (with a boolean) if you want the node to join the cluster then generate and send values. Or rather generate and send values on the isolated CRDT (as if it was under partition) then join.
%Specify (with a boolean) if you want all the values to be added at once or gradually via All_At_Once. If set to false, it will use SendingSpeed to send gradually the values.
% OUT:
%The node will generate the number of values and send them, trying to achieve the specified Sending Speed.
%It will join the cluster before or after sending the values based on GeneratingUnderPartition
%The time required to generate and send the values, the time required after the generation to reach convergence and all the paramters are written to a file
%The file name will be in the folder /lasp/Memoire/Mesures with the name Exp+ExperimentNumber+_Node+NodeId
launchExperimentAdding(ExperimentNumber, NodeToJoin, CRDT_Id, TotalNumberOfNodes, All_At_Once, SendingSpeed, NumberOfValues, GeneratingUnderPartition) -> 
	%---------------------------------------	
	%Little setup
	%---------------------------------------
	ExperimentStartTime = erlang:system_time(1000),
	Id = list_to_integer( lists:nth(2,string:split(lists:nth(1,string:split(atom_to_list(erlang:node()),"@")), "e")) ),
	CRDT_Type = state_awset,
	CRDT_Type_String = "state_awset",
	io:format("EXPERIMENT ~p ", [ExperimentNumber]),
	io:format("Node ~p (Adding elements) ~n", [Id]),
	Threshold = (TotalNumberOfNodes*NumberOfValues),
	
	%---------------------------------------	
	%Join cluster before adding values
	%---------------------------------------
	case {GeneratingUnderPartition, erlang:node()==NodeToJoin} of
	{false, false} -> 
		lasp_peer_service:join(NodeToJoin),
		io:format("Clustering is done ~n");
	{true, false} ->
		ok;
	{_,true} -> 
		lasp:declare({CRDT_Id, CRDT_Type}, CRDT_Type)
	end,

	%---------------------------------------	
	%Generate Values
	%---------------------------------------	
	StartSending = erlang:system_time(1000),
	lasp:declare({CRDT_Id, CRDT_Type}, CRDT_Type),
	generateValues(Id, CRDT_Id, CRDT_Type, NumberOfValues, SendingSpeed, All_At_Once),
	Initial_CRDT_Size = erts_debug:flat_size(  lasp:query({CRDT_Id, CRDT_Type})  ),
	io:format("Initial CRDT size: ~p (words) ~n", [Initial_CRDT_Size]),
	EndSending = erlang:system_time(1000),
	SendingTime = EndSending - StartSending,
	%---------------------------------------	
	%Or Join cluster after adding values
	%---------------------------------------
	case {GeneratingUnderPartition, erlang:node()==NodeToJoin} of
	{true, false} -> 
		lasp_peer_service:join(NodeToJoin),
		io:format("Clustering is done ~n");
	{false, false} ->
		ok;
	{_,true} -> ok
	end,

	%---------------------------------------	
	%Start Timer for convergence
	%---------------------------------------
	io:format("Waiting for convergence... ~n"),
	InitialTimer = erlang:system_time(1000),	
	lasp:read({CRDT_Id, CRDT_Type}, {cardinality, Threshold}),	
	ConvergedTimer = erlang:system_time(1000),
	Final_CRDT_Size = erts_debug:flat_size(  lasp:query({CRDT_Id, CRDT_Type})  ),
	io:format("Final CRDT size: ~p (words) ~n", [Final_CRDT_Size]),
	%---------------------------------------	
	%End Timer for convergence
	%---------------------------------------

	%---------------------------------------	
	%Write to file
	%---------------------------------------
	EllapsedTime = ConvergedTimer - InitialTimer,
	io:format("Correct number of elements in the set reached! (~p elements) ~n", [Threshold]),
	io:format("Convergence took ~p milliseconds ~n", [EllapsedTime]),
	io:format("Waiting experiment to finish on every node..."),
	lasp:update({<<"done">>, state_awset}, {add, Id}, self()), %Mark that I finished
	lasp:read({<<"done">>, state_awset}, {cardinality, TotalNumberOfNodes}), %Wait everyone finished
	io:format("OK! Writting output file ~n"),
	ExperimentEndTime = erlang:system_time(1000),
	TotalExperimentTime = ExperimentEndTime - ExperimentStartTime,
	io:format("Total experiment duration : ~p ~n", [TotalExperimentTime]),
	generateFileAdd(ExperimentNumber, Id, NodeToJoin, CRDT_Type_String, TotalNumberOfNodes, SendingSpeed, NumberOfValues, Threshold, EllapsedTime, GeneratingUnderPartition, SendingTime, All_At_Once, Initial_CRDT_Size, Final_CRDT_Size),
	io:format("Done. ~n"),
	io:format("~n"),
	timer:sleep(15000), %wait before stopping.
	partisan_peer_service:stop().





%% ===================================================================
%% Helpers
%% ===================================================================


%Generate the file to save measurements
generateFileAdd (ExperimentNumber, Id, NodeToJoin, CRDT_Type_String, TotalNumberOfNodes, SendingSpeed, NumberOfValues, Threshold, EllapsedTime, GeneratingUnderPartition, SendingTime, All_At_Once,Initial_CRDT_Size, Final_CRDT_Size) ->
	UniqueValue = integer_to_list(erlang:system_time(1000)),
	Path = "Memoire/Mesures/Exp"++integer_to_list(ExperimentNumber)++"/Node"++integer_to_list(Id)++"_"++UniqueValue++".txt",
	{ok, File} = file:open(Path, [write]),
	case (GeneratingUnderPartition) of
	true ->
		Partition = "true";
	false ->
		Partition = "false"
	end,
	ExperimentName = "Launching " ++integer_to_list(TotalNumberOfNodes) ++ " nodes at the same time, each generating a total of "
							   ++integer_to_list(NumberOfValues)++  " elements (while under partition = " ++ Partition ++ ") " ++" then start timer and wait until all the elements converged",
	io:format(File, "~s~n", [ExperimentName]),
	io:format(File, "~s~n", [""]), 
	io:format(File, "~s~n", ["============"]), 
	io:format(File, "~s~n", ["Parameters :"]),
	io:format(File, "~s~n", ["============"]), 
	io:format(File, "~s~n", ["Node Id:"]),
	io:format(File, "~s~n", [integer_to_list(Id)]),
	io:format(File, "~s~n", ["Node to join cluster: "]),
	io:format(File, "~s~n", [NodeToJoin]),
	io:format(File, "~s~n", ["Generating elements under partition: "]),
	io:format(File, "~s~n", [GeneratingUnderPartition]),
	io:format(File, "~s~n", ["Type of CRDT: "]),
	io:format(File, "~s~n", [CRDT_Type_String]),
	io:format(File, "~s~n", ["Number of nodes: "]),
	io:format(File, "~s~n", [integer_to_list(TotalNumberOfNodes)]),
	io:format(File, "~s~n", ["Number of elements generated by each node: "]),
	io:format(File, "~s~n", [integer_to_list(NumberOfValues)]),
	io:format(File, "~s~n", ["Sending all at once: "]),
	io:format(File, "~s~n", [All_At_Once]),
	io:format(File, "~s~n", ["Theoretical time (ms) between each element sending, for each node, valuable only if not sending all at once: "]),
	io:format(File, "~s~n", [integer_to_list(SendingSpeed)]),
	io:format(File, "~s~n", ["Time (ms) required (for this node) to generate and send all the elements: "]),
	io:format(File, "~s~n", [integer_to_list(SendingTime)]),
	io:format(File, "~s~n", ["Initial size of the CRDT (in term of words) : "]),
	io:format(File, "~s~n", [integer_to_list(Initial_CRDT_Size)]),
	io:format(File, "~s~n", ["Total final number of elements in the CRDT: "]),
	io:format(File, "~s~n", [integer_to_list(Threshold)]),
	io:format(File, "~s~n", ["Final size of the CRDT (in term of words) : "]),
	io:format(File, "~s~n", [integer_to_list(Final_CRDT_Size)]),
	io:format(File, "~s~n", ["Ellapsed time (ms) after elements generation to get the total " ++ integer_to_list(Threshold) ++ " elements:"]),
	io:format(File, "~s~n", [integer_to_list(EllapsedTime)]),
	io:format(File, "~s~n", [""]),
	io:format(File, "~s~n", ["======================================================================================="]),
	io:format(File, "~s~n", ["======================================================================================="]),
	io:format(File, "~s~n", [""]),
	file:close(File).
	

	


%%Generate values for crdt
%%Limit is the number of values to generate
%% Maxvalue is the maximum value acceptable
%% Period is the time in ms between each value generation
%% Example: generateValues (10, 100, 1000) will generate a total of 10 values (numbers between 0 and 100) at speed of 1/sec

generateValues(Id, CRDT_Id, CRDT_Type, NumberOfValues, Period, All_At_Once) ->
	io:format("Generating ~p values ~n", [NumberOfValues]),

	Values = lists:seq( (Id-1)*NumberOfValues , (Id*NumberOfValues)-1 ),	
	case (All_At_Once) of
	false ->
		io:format("Adding the ~p generated elements, ", [NumberOfValues]),
		io:format("at speed of one every ~p milliseconds ~n", [Period]);
	true ->
		io:format("Adding the ~p generated elements, ", [NumberOfValues]),
		io:format("all at once ~n")
	end,
	generateValues_helper2(CRDT_Id, Values, Period, 1, NumberOfValues, CRDT_Type, All_At_Once). %start counter at 2 to avoid sending the initial 0
	


%Helper2 to generate values (used to send them)
generateValues_helper2(CRDT_Id, ValuesArray, PeriodMs, Counter, NumberOfValues, CRDT_Type, All_At_Once) ->
	case (All_At_Once) of
	true -> 
		lasp:update({CRDT_Id, CRDT_Type}, {add_all, ValuesArray}, self());
	false ->
		if (Counter =< NumberOfValues) ->
			CurrentValue = lists:nth(Counter, ValuesArray),
			lasp:update({CRDT_Id, CRDT_Type}, {add, CurrentValue}, self()),
			timer:sleep(PeriodMs),
			generateValues_helper2(CRDT_Id, ValuesArray, PeriodMs, Counter+1, NumberOfValues, CRDT_Type, All_At_Once);
		true -> 
			io:format("Finished adding values to CRDT ~n")
		end
	end.



%% ===================================================================
%% launchExperimentRemoving:
%% ===================================================================

launchExperimentRemoving(ExperimentNumber, NodeToJoin, CRDT_Id, TotalNumberOfNodes, All_At_Once, RemovingSpeed, NumberOfValues, RemovingUnderPartition) -> 
	%---------------------------------------	
	%Little setup (putting initial elements)
	%---------------------------------------
	ExperimentStartTime = erlang:system_time(1000),
	Id = list_to_integer( lists:nth(2,string:split(lists:nth(1,string:split(atom_to_list(erlang:node()),"@")), "e")) ),
	CRDT_Type = state_awset,
	CRDT_Type_String = "state_awset",
	case (Id) of
	1 -> lasp:declare({CRDT_Id, CRDT_Type}, CRDT_Type);
	_ -> ok
	end,
	timer:sleep(1000),
	io:format("EXPERIMENT ~p ", [ExperimentNumber]),
	io:format("Node ~p (Removing elements) ~n", [Id]),
	Threshold = 0,	
	ValuesArray = lists:seq(0, ((TotalNumberOfNodes*NumberOfValues)-1) ),  % Valeurs de 0 à XX9 dont les indices vont de 1 à 1XX
	lasp:update({CRDT_Id, CRDT_Type}, {add_all, ValuesArray}, <<04760>>), %They consider all the initial values are from the same actor, that way they start with exactly the same CRDT
	io:format("Initial ~p values are set ~n", [TotalNumberOfNodes*NumberOfValues]),
	Initial_CRDT_Size = erts_debug:flat_size(  lasp:query({CRDT_Id, CRDT_Type})  ),
	io:format("Initial CRDT size: ~p (words) ~n", [Initial_CRDT_Size]),

	case {RemovingUnderPartition, erlang:node()==NodeToJoin} of
	{false, false} -> 
		lasp_peer_service:join(NodeToJoin),
		io:format("Clustering is done ~n");
	{true, false} ->
		ok;
	{_,true} -> ok
	end,

	%---------------------------------------	
	%Removing values
	%---------------------------------------
	RemovingTime = removeValues(Id, CRDT_Id, CRDT_Type, NumberOfValues, All_At_Once, RemovingSpeed),
	io:format("Removing values took ~p ms ~n", [RemovingTime]),
	%---------------------------------------	
	%Or Join cluster after removing values
	%---------------------------------------
	case {RemovingUnderPartition, erlang:node()==NodeToJoin} of
	{true, false} -> 
		lasp_peer_service:join(NodeToJoin),
		io:format("Clustering is done ~n");
	{false, false} ->
		ok;
	{_,true} -> ok
	end,
	
	%---------------------------------------	
	%Start Timer for convergence
	%---------------------------------------
	io:format("Waiting for convergence... ~n"),
	InitialTimer = erlang:system_time(1000),	
	lasp:read({CRDT_Id, CRDT_Type}, {cardinality, -1}),	%Ajouter une fonction dans state_awset pour cardinalityG et cardinalityS (bigger et smaller)
	EndTimer = erlang:system_time(1000),
	ConvergedTime = EndTimer - InitialTimer,
	io:format("Correct number of elements in the set reached! (~p elements) ~n", [Threshold]),
	Final_CRDT_Size = erts_debug:flat_size(  lasp:query({CRDT_Id, CRDT_Type})  ),
	io:format("Final CRDT size: ~p (words) ~n", [Final_CRDT_Size]),
	io:format("Convergence took ~p ms ~n", [ConvergedTime]),
	%---------------------------------------	
	%End Timer for convergence
	%---------------------------------------

	%---------------------------------------	
	%Write to file
	%---------------------------------------
	io:format("Waiting experiment to finish on every node..."),
	lasp:update({<<"done">>, state_awset}, {add, Id}, self()), %Mark that I finished
	lasp:read({<<"done">>, state_awset}, {cardinality, TotalNumberOfNodes}), %Wait everyone finished
	io:format("OK! Writting output file ~n"),
	ExperimentEndTime = erlang:system_time(1000),
	TotalExperimentTime = ExperimentEndTime - ExperimentStartTime,
	io:format("Total experiment duration : ~p ~n", [TotalExperimentTime]),
	generateFileRmv (ExperimentNumber, Id, NodeToJoin, CRDT_Type_String, TotalNumberOfNodes, RemovingSpeed, NumberOfValues, Threshold, ConvergedTime, RemovingUnderPartition, RemovingTime, All_At_Once, Initial_CRDT_Size, Final_CRDT_Size),
	io:format("Done. ~n"),
	io:format("~n"),
	timer:sleep(15000), %wait before stopping.
	partisan_peer_service:stop().


%% ===================================================================
%% Helpers
%% ===================================================================

removeValues(Id, CRDT_Id, CRDT_Type, NumberOfValues, All_At_Once, RemovingSpeed) ->
	ValuesToRemove = lists:seq( (Id-1)*NumberOfValues , (Id*NumberOfValues)-1 ),
	io:format("Removing unique ~p elements, ",[NumberOfValues]),
	StartRemovingTime = erlang:system_time(1000),
	case (All_At_Once) of
	true -> 
		io:format("all at once ~n"),
		lasp:update({CRDT_Id, CRDT_Type}, {rmv_all, ValuesToRemove}, self());
	false ->
		io:format("at speed of one every ~p ms ~n", [RemovingSpeed]),
		removeValues_helper(CRDT_Id, CRDT_Type, NumberOfValues, ValuesToRemove, RemovingSpeed, 1)
	end,
	EndRemovingTime = erlang:system_time(1000),
	RemovingTime = EndRemovingTime - StartRemovingTime,
	io:format("Removing elements is done ~n"),
	RemovingTime.


removeValues_helper(CRDT_Id, CRDT_Type, NumberOfValues ,ValuesToRemove, RemovingSpeed, Counter) ->
	if (Counter =< NumberOfValues) ->
		CurrentValue = lists:nth(Counter, ValuesToRemove),
		lasp:update({CRDT_Id, CRDT_Type}, {rmv, CurrentValue}, self()),
		timer:sleep(RemovingSpeed),
		removeValues_helper(CRDT_Id, CRDT_Type, NumberOfValues ,ValuesToRemove, RemovingSpeed, Counter+1);
	true ->
		io:format("Finished removing values to CRDT ~n")
	end.



generateFileRmv (ExperimentNumber, Id, NodeToJoin, CRDT_Type_String, TotalNumberOfNodes, RemovingSpeed, NumberOfValues, Threshold, EllapsedTime, RemovingUnderPartition, RemovingTime, All_At_Once, Initial_CRDT_Size, Final_CRDT_Size) ->

	UniqueValue = integer_to_list(erlang:system_time(1000)),
	Path = "Memoire/Mesures/Exp"++integer_to_list(ExperimentNumber)++"/Node"++integer_to_list(Id)++"_"++UniqueValue++".txt",
	{ok, File} = file:open(Path, [write]),
	
	case (RemovingUnderPartition) of
	true ->
		Partition = "true";
	false ->
		Partition = "false"
	end,
	ExperimentName = "Launching " ++integer_to_list(TotalNumberOfNodes) ++ " nodes at the same time with a common filled CRDT, each removing a total of "
							   ++integer_to_list(NumberOfValues)++  " elements (while under partition = " ++ Partition ++ ") " ++" then start timer and wait until it converged",
	io:format(File, "~s~n", [ExperimentName]),
	io:format(File, "~s~n", [""]), 
	io:format(File, "~s~n", ["============"]), 
	io:format(File, "~s~n", ["Parameters :"]),
	io:format(File, "~s~n", ["============"]), 
	io:format(File, "~s~n", ["Node Id:"]),
	io:format(File, "~s~n", [integer_to_list(Id)]),
	io:format(File, "~s~n", ["Node to join cluster: "]),
	io:format(File, "~s~n", [NodeToJoin]),
	io:format(File, "~s~n", ["Removing elements under partition: "]),
	io:format(File, "~s~n", [RemovingUnderPartition]),
	io:format(File, "~s~n", ["Type of CRDT: "]),
	io:format(File, "~s~n", [CRDT_Type_String]),
	io:format(File, "~s~n", ["Number of nodes: "]),
	io:format(File, "~s~n", [integer_to_list(TotalNumberOfNodes)]),
	io:format(File, "~s~n", ["Initial number of elements before removal: "]),
	io:format(File, "~s~n", [integer_to_list(TotalNumberOfNodes*NumberOfValues)]),
	io:format(File, "~s~n", ["Number of elements removed by each node: "]),
	io:format(File, "~s~n", [integer_to_list(NumberOfValues)]),
	io:format(File, "~s~n", ["Removing all at once: "]),
	io:format(File, "~s~n", [All_At_Once]),
	io:format(File, "~s~n", ["Theoretical time (ms) between each element removing, for each node, valuable only if not removing all at once: "]),
	io:format(File, "~s~n", [integer_to_list(RemovingSpeed)]),
	io:format(File, "~s~n", ["Time (ms) required (for this node) to remove all its assigned elements: "]),
	io:format(File, "~s~n", [integer_to_list(RemovingTime)]),
	io:format(File, "~s~n", ["Initial size of the CRDT (in term of words) : "]),
	io:format(File, "~s~n", [integer_to_list(Initial_CRDT_Size)]),
	io:format(File, "~s~n", ["Total final number of elements in the CRDT: "]),
	io:format(File, "~s~n", [integer_to_list(Threshold)]),
	io:format(File, "~s~n", ["Final size of the CRDT (in term of words) : "]),
	io:format(File, "~s~n", [integer_to_list(Final_CRDT_Size)]),
	io:format(File, "~s~n", ["Ellapsed time (ms) after elements removal to get the total " ++ integer_to_list(Threshold) ++ " elements:"]),
	io:format(File, "~s~n", [integer_to_list(EllapsedTime)]),
	io:format(File, "~s~n", [""]),
	io:format(File, "~s~n", ["======================================================================================="]),
	io:format(File, "~s~n", ["======================================================================================="]),
	io:format(File, "~s~n", [""]),
	file:close(File).


%% ===================================================================
%% Other small tests:
%% ===================================================================

simpleAddition() ->
 
	case (erlang:node()=='node1@127.0.0.1') of
	false ->
		lasp_peer_service:join('node1@127.0.0.1'),
		io:format("Clustering is done ~n");
	true ->
		lasp:declare({<<"set99">>, state_awset}, state_awset)
	end,
	Id = list_to_integer( lists:nth(2,string:split(lists:nth(1,string:split(atom_to_list(erlang:node()),"@")), "e")) ),
	Values = lists:seq(1000*Id, (1000*Id)+1000),
	lasp:update({<<"set99">>, state_awset}, {add_all, Values}, self()),
	io:format("I added 1000 elements ~n"),
	lasp:read({<<"set99">>, state_awset}, {cardinality, 5000}).
	

	

