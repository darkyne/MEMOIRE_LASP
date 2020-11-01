%% -------------------------------------------------------------------
%%
%% Copyright (c) 2015 Helium Systems, Inc.  All Rights Reserved.
%% Copyright (c) 2016 Christopher Meiklejohn.  All Rights Reserved.
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

-module(partisan_peer_service_events).

-behaviour(gen_event).

%% API
-export([start_link/0,
         add_handler/2,
         add_sup_handler/2,
         add_callback/1,
         add_sup_callback/1,
         update/1]).

-include("partisan.hrl").

%% gen_event callbacks
-export([init/1,
         handle_event/2,
         handle_call/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {callback}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    gen_event:start_link({local, ?MODULE}).

add_handler(Handler, Args) ->
    gen_event:add_handler(?MODULE, Handler, Args).

add_sup_handler(Handler, Args) ->
    gen_event:add_sup_handler(?MODULE, Handler, Args).

add_callback(Fn) when is_function(Fn) ->
    gen_event:add_handler(?MODULE, {?MODULE, make_ref()}, [Fn]).

add_sup_callback(Fn) when is_function(Fn) ->
    gen_event:add_sup_handler(?MODULE, {?MODULE, make_ref()}, [Fn]).

%% @todo Change back to non.
update(LocalState) ->
    gen_event:sync_notify(?MODULE, {update, LocalState}).

%% ===================================================================
%% gen_event callbacks
%% ===================================================================

init([Fn]) ->
    {ok, #state{callback=Fn}}.

handle_event({update, LocalState}, State) ->
    (State#state.callback)(LocalState),
    {ok, State};
handle_event(Event, State) ->
    lager:info("Unhandled event at module ~p: ~p", [?MODULE, Event]),
    {ok, State}.

handle_call(Request, State) ->
    lager:warning("Unhandled call messages at module ~p: ~p", [?MODULE, Request]),
    {ok, ok, State}.

handle_info(_Info, State) ->
    %% lager:warning("Unhandled info messages at module ~p: ~p", [?MODULE, Info]),
    {ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.