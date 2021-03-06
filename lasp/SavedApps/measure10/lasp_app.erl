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


%% start non modified version:
start(_StartType, _StartArgs) ->
    case lasp_sup:start_link() of
        {ok, Pid} ->
			lasp_convergence_measure:launchExperimentAdding(10, 'node1@192.168.1.39', <<"set1">>, 5, true, 0, 10, false),
		    {ok, Pid};

        {error, Reason} ->
            {error, Reason}
    end.
    
%% @doc Stop the lasp application.
stop(_State) ->
    ok.




