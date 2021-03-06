%%%-------------------------------------------------------------------
%%% File    : url.erl
%%% Author  : Jesper Louis Andersen <jesper.louis.andersen@gmail.com>
%%% Description : URI handling code, as in RFC3986
%%%
%%% Created : 14 Oct 2010 by Jesper Louis Andersen <jesper.louis.andersen@gmail.com>
%%%-------------------------------------------------------------------
-module(uri).

-include("uri.hrl").

%% API
-export([mk/2, mk/3, mk/4,
	 mk_hier/2,
	 to_iolist/1, to_string/1]).

%%====================================================================
%% API
%%====================================================================
mk(S, H) ->
    mk(S,H,[],none).

mk(S,H,Q) ->
    mk(S,H,Q,none).

mk(S,H,Q,F) ->
    #uri{scheme = S, hier = H, q = Q, fragment = F}.

mk_hier(A, P) ->
    #hier{authority = A, path = P}.

-spec to_iolist(#uri{}) -> iolist().
to_iolist(#uri{scheme = S, hier = H, q = Q, fragment = F}) ->
    [atom_to_list(S),":",
     hier_to_iolist(H),
     query_to_iolist(Q),
     fragment_to_iolist(F)].

-spec to_string(#uri{}) -> string().
to_string(Uri) ->
    lists:flatten(to_iolist(Uri)).

%%====================================================================
%% Internal functions
%%====================================================================
hier_to_iolist(#hier{authority = A, path = P}) ->
    case {A,P} of
	{none, none} -> "";
	{none, P1} -> P1;
	{A1, none} -> ["//", A1];
	{A1, P1} ->   ["//", A1, "/", P1]
    end.

query_to_iolist([]) ->
    "";
query_to_iolist(L) ->
    ["?", [[percent_encode(K), "=", percent_encode(V)] || {K, V} <- L]].

fragment_to_iolist(none) ->
    "";
fragment_to_iolist(Frag) ->
    ["#", percent_encode(Frag)].

should_escape(C) when $A =< C andalso C =< $Z -> false;
should_escape(C) when $a =< C andalso C =< $z -> false;
should_escape(C) when $0 =< C andalso C =< $9 -> false;
should_escape(C) when is_integer(C) ->
    not lists:member(C, "_.-~").

hex(B) ->
    binary:sub(B, <<"0123456789abcdef">>).

hex_write(C) ->
    Upper = C bsr 4,
    Lower = C band 15,
    [hex(Upper), hex(Lower)].

percent_encode(Str) ->
    [begin
	 case should_escape(C) of
	     false -> C;
	     true when 0 =< C andalso C < 256 ->
		 ["%", hex_write(C)]
	 end
     end || C <- Str].
