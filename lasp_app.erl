%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(lasp_app).

-behaviour(application).

-include("lasp.hrl").

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

%% @doc Start the lasp application.
start(_StartType, _StartArgs) ->
    case lasp_sup:start_link() of
        {ok, Pid} ->
		Name = erlang:node(),
	    io:format("This node name is ~p ~n", [Name]),
		lasp_peer_service:join('node1@127.0.0.1'),
		%They all join on node1 creating a cluster regrouping all the nodes
		%Members = lasp_peer_service:members(),
		%io:format("The clustered members are ~p ~n", [Members]),
		lasp:declare({<<"set">>, state_orset}, state_orset),
		TestValue = 5,

		if (Name=='node1@127.0.0.1') -> 
			lasp:update({<<"set">>, state_orset}, {add, TestValue}, self());
		true -> return end,

		{ok, Value} = lasp:query({<<"set">>, state_orset}),
		FormattedValue = sets:to_list(Value),
		io:format("First value I read ~p ~n", [FormattedValue]),
		InitialTimer = erlang:system_time(1000),
		loop_for_data(Value, TestValue),
		ConvergedTimer = erlang:system_time(1000),
		EllapsedTime = ConvergedTimer - InitialTimer,
		io:format("It took me ~p milliseconds ~n", [EllapsedTime]),
        {ok, Pid};

        {error, Reason} ->
            {error, Reason}
    end.

loop_for_data(Data, TestData) ->
	if (Data /= TestData) -> 
		{ok, NewValue} = lasp:query({<<"set">>, state_orset}),
		FormattedNewValue = sets:to_list(NewValue),
		%io:format("Fetched new value ~p ~n", [FormattedNewValue]),
		Size = length(FormattedNewValue),
		if (Size >= 1) ->
			NewReadableValue = lists:nth(1,FormattedNewValue),
			loop_for_data(NewReadableValue, TestData);
		true ->
			loop_for_data(Data, TestData)
		end;
	true -> 
		if (erlang:node()=='node1@127.0.0.1') ->
			io:format("I found value ~p and convergeted instantly since I pushed the value ! ~n", [Data]);
		true ->
			io:format("I found value ~p ~n", [Data]),
			io:format("I have converged! ~n"),
			return
		end
	end.

%% start non modified version:
%start(_StartType, _StartArgs) ->
%    case lasp_sup:start_link() of
%        {ok, Pid} ->
%            {ok, Pid};
%
%        {error, Reason} ->
%            {error, Reason}
%    end.
    

%% @doc Stop the lasp application.
stop(_State) ->
    ok.
