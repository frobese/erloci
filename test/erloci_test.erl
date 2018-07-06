%% -*- coding: utf-8 -*-
-module(erloci_test).

-include_lib("eunit/include/eunit.hrl").
-include("test_common.hrl").

-define(PORT_MODULE, oci_port).

-define(TESTTABLE, "erloci_test_1").
-define(TESTFUNCTION, "ERLOCI_TEST_FUNCTION").
-define(TESTPROCEDURE, "ERLOCI_TEST_PROCEDURE").
-define(DROP,   <<"drop table "?TESTTABLE>>).
-define(CREATE, <<"create table "?TESTTABLE" (pkey integer,"
                  "publisher varchar2(30),"
                  "rank float,"
                  "hero binary_double,"
                  "reality raw(10),"
                  "votes number(1,-10),"
                  "createdate date default sysdate,"
                  "chapters binary_float,"
                  "votes_first_rank number)">>).
-define(INSERT, <<"insert into "?TESTTABLE
                  " (pkey,publisher,rank,hero,reality,votes,createdate,"
                  "  chapters,votes_first_rank) values ("
                  ":pkey"
                  ", :publisher"
                  ", :rank"
                  ", :hero"
                  ", :reality"
                  ", :votes"
                  ", :createdate"
                  ", :chapters"
                  ", :votes_first_rank)">>).
-define(SELECT_WITH_ROWID, <<"select "?TESTTABLE".rowid, "?TESTTABLE
                             ".* from "?TESTTABLE>>).
-define(SELECT_ROWID_ASC, <<"select rowid from "?TESTTABLE" order by pkey">>).
-define(SELECT_ROWID_DESC, <<"select rowid from "?TESTTABLE
                             " order by pkey desc">>).
-define(BIND_LIST, [ {<<":pkey">>, 'SQLT_INT'}
                   , {<<":publisher">>, 'SQLT_CHR'}
                   , {<<":rank">>, 'SQLT_FLT'}
                   , {<<":hero">>, 'SQLT_IBDOUBLE'}
                   , {<<":reality">>, 'SQLT_BIN'}
                   , {<<":votes">>, 'SQLT_INT'}
                   , {<<":createdate">>, 'SQLT_DAT'}
                   , {<<":chapters">>, 'SQLT_IBFLOAT'}
                   , {<<":votes_first_rank">>, 'SQLT_INT'}
                   ]).
-define(UPDATE, <<"update "?TESTTABLE" set "
                  "pkey = :pkey"
                  ", publisher = :publisher"
                  ", rank = :rank"
                  ", hero = :hero"
                  ", reality = :reality"
                  ", votes = :votes"
                  ", createdate = :createdate"
                  ", chapters = :chapters"
                  ", votes_first_rank = :votes_first_rank"
                  " where "?TESTTABLE".rowid = :pri_rowid1">>).
-define(UPDATE_BIND_LIST, [ {<<":pkey">>, 'SQLT_INT'}
                          , {<<":publisher">>, 'SQLT_CHR'}
                          , {<<":rank">>, 'SQLT_FLT'}
                          , {<<":hero">>, 'SQLT_IBDOUBLE'}
                          , {<<":reality">>, 'SQLT_BIN'}
                          , {<<":votes">>, 'SQLT_STR'}
                          , {<<":createdate">>, 'SQLT_DAT'}
                          , {<<":chapters">>, 'SQLT_IBFLOAT'}
                          , {<<":votes_first_rank">>, 'SQLT_INT'}
                          , {<<":pri_rowid1">>, 'SQLT_STR'}
                          ]).
-define(SESSSQL, <<"select '' || s.sid || ',' || s.serial# "
                   "from gv$session s join "
                   "gv$process p on p.addr = s.paddr and "
                   "p.inst_id = s.inst_id "
                   "where s.type != 'BACKGROUND' and s.program like 'ocierl%'">>).

% ------------------------------------------------------------------------------
% db_negative_test_
% ------------------------------------------------------------------------------
db_negative_test_() ->
    {timeout, 60, {
        setup,
        fun() ->
                Conf = ?CONN_CONF,
                application:start(erloci),
                OciPort = erloci:new(
                            [{logging, true},
                             {env, [{"NLS_LANG",
                                     "GERMAN_SWITZERLAND.AL32UTF8"}]}]),
                #{ociport => OciPort, conf => Conf}
        end,
        fun(#{ociport := OciPort}) ->
                oci_port:close(OciPort),
                application:stop(erloci)
        end,
        {with, [
            fun echo/1,
            fun bad_password/1,
            fun session_ping/1
        ]}
    }}.

echo(#{ociport := OciPort}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                     echo                    |"),
    ?ELog("+---------------------------------------------+"),
    ?ELog("echo back erlang terms", []),
    ?assertEqual(1, oci_port:echo(1, OciPort)),
    ?assertEqual(1.2, oci_port:echo(1.2, OciPort)),
    ?assertEqual(atom, oci_port:echo(atom, OciPort)),
    ?assertEqual(self(), oci_port:echo(self(), OciPort)),
    ?assertEqual(node(), oci_port:echo(node(), OciPort)),
    Ref = make_ref(),
    ?assertEqual(Ref, oci_port:echo(Ref, OciPort)),
    % Load the ref cache to generate long ref
    Refs = [make_ref() || _I <- lists:seq(1,1000000)],
    ?debugFmt("~p refs created to load ref cache", [length(Refs)]),
    Ref1 = make_ref(),
    ?assertEqual(Ref1, oci_port:echo(Ref1, OciPort)),
    %Fun = fun() -> ok end, % Not Supported
    %?assertEqual(Fun, oci_port:echo(Fun, OciPort)),
    ?assertEqual("", oci_port:echo("", OciPort)),
    ?assertEqual(<<>>, oci_port:echo(<<>>, OciPort)),
    ?assertEqual([], oci_port:echo([], OciPort)),
    ?assertEqual({}, oci_port:echo({}, OciPort)),
    ?assertEqual("string", oci_port:echo("string", OciPort)),
    ?assertEqual(<<"binary">>, oci_port:echo(<<"binary">>, OciPort)),
    ?assertEqual({1,'Atom',1.2,"string"}, oci_port:echo({1,'Atom',1.2,"string"}, OciPort)),
    ?assertEqual([1, atom, 1.2,"string"], oci_port:echo([1,atom,1.2,"string"], OciPort)).

bad_password(#{ociport := OciPort, conf := #{tns := Tns, user := User, password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                 bad_password                |"),
    ?ELog("+---------------------------------------------+"),
    ?ELog("get_session with wrong password", []),
    ?assertMatch(
       {error, {1017,_}},
       oci_port:get_session(Tns, User, list_to_binary([Pswd,"_bad"]), OciPort)).

session_ping(#{ociport := OciPort, conf := #{tns := Tns, user := User, password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                 session_ping                |"),
    ?ELog("+---------------------------------------------+"),
    ?ELog("ping oci session", []),
    OciSession = oci_port:get_session(Tns, User, Pswd, OciPort),
    ?assertEqual(pong, oci_port:ping(OciSession)),
    SelStmt = oci_port:prep_sql("select * from dual", OciSession),
    ?assertEqual(pong, oci_port:ping(OciSession)),
    ?assertMatch({cols,[{<<"DUMMY">>,'SQLT_CHR',_,0,0}]}, oci_port:exec_stmt(SelStmt)),
    ?assertEqual(pong, oci_port:ping(OciSession)),
    ?assertEqual({{rows,[[<<"X">>]]},true}, oci_port:fetch_rows(100, SelStmt)),
    ?assertEqual(pong, oci_port:ping(OciSession)).

%%------------------------------------------------------------------------------
%% db_test_
%%------------------------------------------------------------------------------
db_test_() ->
    {timeout, 60, {
       setup,
       fun() ->
               Conf = ?CONN_CONF,
               application:start(erloci),
               #{tns := Tns, user := User, password := Pswd,
                 logging := Logging, lang := Lang} = Conf,
               OciPort = erloci:new([{logging, Logging}, {env, [{"NLS_LANG", Lang}]}]),
               OciSession = oci_port:get_session(Tns, User, Pswd, OciPort),
               ssh(#{ociport => OciPort, ocisession => OciSession, conf => Conf})
       end,
       fun(#{ociport := OciPort, ocisession := OciSession} = State) ->
               DropStmt = oci_port:prep_sql(?DROP, OciSession),
               oci_port:exec_stmt(DropStmt),
               oci_port:close(DropStmt),
               oci_port:close(OciSession),
               oci_port:close(OciPort),
               application:stop(erloci),
               case State of
                   #{ssh_conn_ref := ConRef} ->
                       ok = ssh:close(ConRef);
                   _ -> ok
               end,
               ssh:stop()
       end,
       {with,
        [fun named_session/1,
         fun drop_create/1,
         fun bad_sql_connection_reuse/1,
         fun insert_select_update/1,
         fun auto_rollback/1,
         fun commit_rollback/1,
         fun asc_desc/1,
         fun lob/1,
         fun describe/1,
         fun function/1,
         fun procedure_scalar/1,
         fun procedure_cur/1,
         fun timestamp_interval_datatypes/1,
         fun stmt_reuse_onerror/1,
         fun multiple_bind_reuse/1,
         fun check_ping/1,
         fun check_session_without_ping/1,
         fun check_session_with_ping/1,
         fun urowid/1
        ]}
      }}.

ssh(#{conf := #{ssh_ip := Ip, ssh_port := Port,
                ssh_user := User, ssh_password := Password}} = State) ->
    ok = ssh:start(),
    case ssh:connect(Ip,Port,[{user,User},{password,Password}]) of
        {ok, ConRef} ->
            State#{ssh_conn_ref => ConRef};
        {error, Reason} ->
            ?ELog("SSH setup error ~p", [Reason]),
            State
    end;
ssh(State) ->
    ?ELog("SSH not configured, some tests will be skipped"),
    State.

flush_table(OciSession) ->
    ?ELog("creating (drop if exists) table ~s", [?TESTTABLE]),
    DropStmt = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmt),
    % If table doesn't exists the handle isn't valid
    % Any error is ignored anyway
    case oci_port:exec_stmt(DropStmt) of
        {error, _} -> ok;
        _ -> ?assertEqual(ok, oci_port:close(DropStmt))
    end,
    ?ELog("creating table ~s", [?TESTTABLE]),
    StmtCreate = oci_port:prep_sql(?CREATE, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtCreate),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(StmtCreate)),
    ?assertEqual(ok, oci_port:close(StmtCreate)).

ssh_cmd(ConRef, Cmd) ->
    {ok, Chn} = ssh_connection:session_channel(ConRef, infinity),
    success = ssh_connection:exec(ConRef, Chn, Cmd, infinity),
    ssh_cmd_result(ConRef, Chn).

ssh_cmd_result(ConRef, Chn) -> ssh_cmd_result(ConRef, Chn, []).
ssh_cmd_result(ConRef, Chn, Buffer) ->
    case receive
             {ssh_cm, ConRef, {closed, Chn}} -> closed;
             {ssh_cm, ConRef, {eof, Chn}} -> eof;
             {ssh_cm, ConRef, {exit_status, Chn, 0}} -> exit_status_ok;
             {ssh_cm, ConRef, {data, Chn, DTC, Data}} ->
                 if DTC /= 0 -> ?ELog("[~p] ~s", [DTC, Data]);
                    true -> ok end,
                 {data, Data};
             {ssh_cm, ConRef, {exit_status, Chn, Exit}} -> {error, {exit_status, Exit}};
             {ssh_cm, ConRef, Other} -> {error, {unexpected, Other}}
         end of
        {data, Dat} -> ssh_cmd_result(ConRef, Chn, [Dat | Buffer]);
        eof -> ssh_cmd_result(ConRef, Chn, Buffer);
        exit_status_ok -> ssh_cmd_result(ConRef, Chn, Buffer);
        closed -> Buffer;
        {error, Error} -> error(Error)
    end.

named_session(#{ociport := OciPort,
                conf := #{tns := Tns, user := User,
                          password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                named_session                |"),
    ?ELog("+---------------------------------------------+"),
    OciSession = oci_port:get_session(Tns, User, Pswd, "eunit_test_tagged", OciPort),
    StmtSelect = oci_port:prep_sql(
                   <<"select * from V$SESSION"
                     " where CLIENT_IDENTIFIER = 'eunit_test_tagged'">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtSelect),
    ?assertMatch({cols, _}, oci_port:exec_stmt(StmtSelect)),
    ?assertMatch({{rows, _}, true}, oci_port:fetch_rows(1, StmtSelect)),
    ?assertEqual(ok, oci_port:close(StmtSelect)),
    oci_port:close(OciSession).

lob(#{ocisession := OciSession, ssh_conn_ref := ConRef}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                     lob                     |"),
    ?ELog("+---------------------------------------------+"),

    RowCount = 3,

    Files =
    [begin
         ContentSize = rand:uniform(1024),
         Filename = "/tmp/test"++integer_to_list(I)++".bin",
         RCmd = lists:flatten(
                  io_lib:format(
                    "dd if=/dev/zero of=~s bs=~p count=1",
                    [Filename, ContentSize])),
         ssh_cmd(ConRef,RCmd),
         Filename
     end || I <- lists:seq(1,RowCount)],

    CreateDirSql = <<"create or replace directory \"TestDir\" as '/tmp'">>,
    StmtDirCreate = oci_port:prep_sql(CreateDirSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtDirCreate),
    case oci_port:exec_stmt(StmtDirCreate) of
        {executed, 0} ->
            ?ELog("created Directory alias for /tmp"),
            ?assertEqual(ok, oci_port:close(StmtDirCreate));
        {error, {955, _}} ->
            ?ELog("Dir alias for /tmp exists");
        {error, {N,Error}} ->
            ?ELog("Dir alias for /tmp creation failed ~p:~s", [N,Error]),
            ?ELog("SQL ~s", [CreateDirSql]),
            ?assertEqual("Directory Created", "Directory creation failed")
    end,
    StmtCreate = oci_port:prep_sql(
                   <<"create table lobs(clobd clob, blobd blob, nclobd nclob, bfiled bfile)">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtCreate),
    case oci_port:exec_stmt(StmtCreate) of
        {executed, 0} ->
            ?ELog("creating table lobs", []),
            ?assertEqual(ok, oci_port:close(StmtCreate));
        _ ->
            StmtTruncate = oci_port:prep_sql(<<"truncate table lobs">>, OciSession),
            ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtTruncate),
            ?assertEqual({executed, 0}, oci_port:exec_stmt(StmtTruncate)),
            ?ELog("truncated table lobs", []),
            ?assertEqual(ok, oci_port:close(StmtTruncate))
    end,

    [begin
        StmtInsert = oci_port:prep_sql(list_to_binary(["insert into lobs values, OciSession("
            "to_clob('clobd0'),"
            "hextoraw('453d7a30'),"
            "to_nclob('nclobd0'),"
            "bfilename('TestDir', 'test",integer_to_list(I),".bin')"
            ")"])),
        ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtInsert),
        ?assertMatch({rowids, [_]}, oci_port:exec_stmt(StmtInsert)),
        ?assertEqual(ok, oci_port:close(StmtInsert))
     end
     || I <- lists:seq(1,RowCount)],
    ?ELog("inserted ~p rows into lobs", [RowCount]),

    StmtSelect = oci_port:prep_sql(<<"select * from lobs">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtSelect),
    ?assertMatch({cols, _}, oci_port:exec_stmt(StmtSelect)),
    {{rows, Rows}, true} = oci_port:fetch_rows(RowCount+1, StmtSelect),
    ?assertEqual(RowCount, length(Rows)),

    lists:foreach(
      fun(Row) ->
              [{LidClobd, ClobdLen}, {LidBlobd, BlobdLen}, {LidNclobd, NclobdLen},
               {LidBfiled, BfiledLen, DirBin, File} | _] = Row,
              ?assertEqual(DirBin, <<"TestDir">>),
              ?ELog("processing... : ~s", [File]),
              {lob, ClobDVal} = oci_port:lob(LidClobd, 1, ClobdLen, StmtSelect),
              ?assertEqual(<<"clobd0">>, ClobDVal),
              {lob, BlobDVal} = oci_port:lob(LidBlobd, 1, BlobdLen, StmtSelect),
              ?assertEqual(<<16#45, 16#3d, 16#7a, 16#30>>, BlobDVal),
              {lob, NClobDVal} = oci_port:lob(LidNclobd, 1, NclobdLen, StmtSelect),
              ?assertEqual(<<"nclobd0">>, NClobDVal),
              [FileContent] = ssh_cmd(ConRef,"cat "++File),
              {lob, FileContentDB} = oci_port:lob(LidBfiled, 1, BfiledLen, StmtSelect),
              ?assertEqual(FileContent, FileContentDB),
              ?ELog("processed : ~s", [File])
      end, Rows),

    ?assertEqual(ok, oci_port:close(StmtSelect)),

    ?ELog("RM ~p", [[ssh_cmd(ConRef, "rm -f "++File) || File <- Files]]),
    StmtDrop = oci_port:prep_sql(<<"drop table lobs">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtDrop),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(StmtDrop)),
    ?assertEqual(ok, oci_port:close(StmtDrop)),
    StmtDirDrop = oci_port:prep_sql(list_to_binary(["drop directory \"TestDir\""]), OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtDirDrop),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(StmtDirDrop)),
    ?assertEqual(ok, oci_port:close(StmtDirDrop));
lob(_) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|            lob (SKIPPED)                    |"),
    ?ELog("+---------------------------------------------+").

drop_create(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                   drop_create               |"),
    ?ELog("+---------------------------------------------+"),

    ?ELog("creating (drop if exists) table ~s", [?TESTTABLE]),
    TmpDropStmt = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, TmpDropStmt),
    case oci_port:exec_stmt(TmpDropStmt) of
        {error, _} -> ok; % If table doesn't exists the handle isn't valid
        _ -> ?assertEqual(ok, oci_port:close(TmpDropStmt))
    end,
    StmtCreate = oci_port:prep_sql(?CREATE, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtCreate),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(StmtCreate)),
    ?assertEqual(ok, oci_port:close(StmtCreate)),

    ?ELog("dropping table ~s", [?TESTTABLE]),
    DropStmt = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmt),
    ?assertEqual({executed,0}, oci_port:exec_stmt(DropStmt)),
    ?assertEqual(ok, oci_port:close(DropStmt)).

bad_sql_connection_reuse(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|           bad_sql_connection_reuse          |"),
    ?ELog("+---------------------------------------------+"),
    BadSelect = <<"select 'abc from dual">>,
    ?assertMatch({error, {1756, _}}, oci_port:prep_sql(BadSelect, OciSession)),
    GoodSelect = <<"select 'abc' from dual">>,
    SelStmt = oci_port:prep_sql(GoodSelect, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt),
    ?assertMatch({cols, [{<<"'ABC'">>,'SQLT_AFC',_,0,0}]}, oci_port:exec_stmt(SelStmt)),
    ?assertEqual({{rows, [[<<"abc">>]]}, true}, oci_port:fetch_rows(2, SelStmt)),
    ?assertEqual(ok, oci_port:close(SelStmt)).


insert_select_update(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|            insert_select_update             |"),
    ?ELog("+---------------------------------------------+"),
    RowCount = 6,

    flush_table(OciSession),

    ?ELog("~s", [binary_to_list(?INSERT)]),
    BoundInsStmt = oci_port:prep_sql(?INSERT, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    BoundInsStmtRes = oci_port:bind_vars(?BIND_LIST, BoundInsStmt),
    ?assertMatch(ok, BoundInsStmtRes),
    %pkey,publisher,rank,hero,reality,votes,createdate,chapters,votes_first_rank
    {rowids, RowIds1} = oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , unicode:characters_to_binary(["_püèr_",integer_to_list(I),"_"])                % publisher
         , I+I/2                                                                            % rank
         , 1.0e-307                                                                         % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , I                                                                                % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , 9.999999350456404e-39                                                            % chapters
         , I                                                                                % votes_first_rank
         } || I <- lists:seq(1, RowCount div 2)],
         BoundInsStmt
    ),
    ?ELog("Bound insert statement reuse"),
    {rowids, RowIds2} = oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , unicode:characters_to_binary(["_püèr_",integer_to_list(I),"_"])                % publisher
         , I+I/2                                                                            % rank
         , 1.0e-307                                                                         % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , I                                                                                % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , 9.999999350456404e-39                                                            % chapters
         , I                                                                                % votes_first_rank
         } || I <- lists:seq((RowCount div 2) + 1, RowCount)],
         BoundInsStmt
    ),
    RowIds = RowIds1 ++ RowIds2,
    ?assertMatch(RowCount, length(RowIds)),
    ?assertEqual(ok, oci_port:close(BoundInsStmt)),

    ?ELog("~s", [binary_to_list(?SELECT_WITH_ROWID)]),
    SelStmt = oci_port:prep_sql(?SELECT_WITH_ROWID, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt),
    {cols, Cols} = oci_port:exec_stmt(SelStmt),
    ?ELog("selected columns ~p from table ~s", [Cols, ?TESTTABLE]),
    ?assertEqual(10, length(Cols)),
    {{rows, Rows0}, false} = oci_port:fetch_rows(2, SelStmt),
    {{rows, Rows1}, false} = oci_port:fetch_rows(2, SelStmt),
    {{rows, Rows2}, true} = oci_port:fetch_rows(3, SelStmt),
    ?assertEqual(ok, oci_port:close(SelStmt)),

    Rows = lists:merge([Rows0, Rows1, Rows2]),
    %?ELog("Got rows~n~p", [
    %    [
    %        begin
    %        [Rowid
    %        , Pkey
    %        , Publisher
    %        , Rank
    %        , Hero
    %        , Reality
    %        , Votes
    %        , Createdate
    %        , Chapters
    %        , Votes_first_rank] = R,
    %        [Rowid
    %        , oci_util:oranumber_decode(Pkey)
    %        , Publisher
    %        , oci_util:oranumber_decode(Rank)
    %        , Hero
    %        , Reality
    %        , oci_util:oranumber_decode(Votes)
    %        , oci_util:oradate_to_str(Createdate)
    %        , oci_util:oranumber_decode(Chapters)
    %        , oci_util:oranumber_decode(Votes_first_rank)]
    %        end
    %    || R <- Rows]
    %]),
    %RowIDs = [R || [R|_] <- Rows],
    [begin
        ?assertEqual(1.0e-307, Hero),
        ?assertEqual(9.999999350456404e-39, Chapters),
        ?assertEqual(<< "_püèr_"/utf8 >>, binary:part(Publisher, 0, byte_size(<< "_püèr_"/utf8 >>)))
    end
    || [_, _, Publisher, _, Hero, _, _, _, Chapters, _] <- Rows],
    RowIDs = [R || [R|_] <- Rows],

    ?ELog("RowIds ~p", [RowIDs]),
    ?ELog("~s", [binary_to_list(?UPDATE)]),
    BoundUpdStmt = oci_port:prep_sql(?UPDATE, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundUpdStmt),
    BoundUpdStmtRes = oci_port:bind_vars(
                        lists:keyreplace(<<":votes">>, 1, ?UPDATE_BIND_LIST, {<<":votes">>, 'SQLT_INT'}), BoundUpdStmt),
    ?assertMatch(ok, BoundUpdStmtRes),
    ?assertMatch({rowids, _}, oci_port:exec_stmt(
        [{ I                                                                 % pkey
         , unicode:characters_to_binary(["_Püèr_",integer_to_list(I),"_"]) % publisher
         , I+I/3                                                             % rank
         , I+I/50                                                            % hero
         , <<>> % deleting                                                   % reality
         , I+1                                                               % votes
         , oci_util:edatetime_to_ora(os:timestamp())                         % createdate
         , I*2+I/1000                                                        % chapters
         , I+1                                                               % votes_first_rank
         , Key
         } || {Key, I} <- lists:zip(RowIds1, lists:seq(1, RowCount div 2))],
         BoundUpdStmt
    )),
    ?ELog("Bound update statement reuse"),
    ?assertMatch({rowids, _}, oci_port:exec_stmt(
        [{ I                                                                 % pkey
         , unicode:characters_to_binary(["_Püèr_",integer_to_list(I),"_"]) % publisher
         , I+I/3                                                             % rank
         , I+I/50                                                            % hero
         , <<>> % deleting                                                   % reality
         , I+1                                                               % votes
         , oci_util:edatetime_to_ora(os:timestamp())                         % createdate
         , I*2+I/1000                                                        % chapters
         , I+1                                                               % votes_first_rank
         , Key
         } || {Key, I} <- lists:zip(RowIds2, lists:seq((RowCount div 2) + 1, RowCount))],
         BoundUpdStmt
    )),
    ?assertEqual(ok, oci_port:close(BoundUpdStmt)).

auto_rollback(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                auto_rollback                |"),
    ?ELog("+---------------------------------------------+"),
    RowCount = 3,

    flush_table(OciSession),

    ?ELog("inserting into table ~s", [?TESTTABLE]),
    BoundInsStmt = oci_port:prep_sql(?INSERT, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    BoundInsStmtRes = oci_port:bind_vars(?BIND_LIST, BoundInsStmt),
    ?assertMatch(ok, BoundInsStmtRes),
    ?assertMatch({rowids, _},
    oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , list_to_binary(["_publisher_",integer_to_list(I),"_"])                           % publisher
         , I+I/2                                                                            % rank
         , I+I/3                                                                            % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , I                                                                                % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , I                                                                                % chapters
         , I                                                                                % votes_first_rank
         } || I <- lists:seq(1, RowCount)]
        , 1, BoundInsStmt
    )),
    ?assertEqual(ok, oci_port:close(BoundInsStmt)),

    ?ELog("selecting from table ~s", [?TESTTABLE]),
    SelStmt = oci_port:prep_sql(?SELECT_WITH_ROWID, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt),
    {cols, Cols} = oci_port:exec_stmt(SelStmt),
    ?assertEqual(10, length(Cols)),
    {{rows, Rows}, false} = oci_port:fetch_rows(RowCount, SelStmt),

    ?ELog("update in table ~s", [?TESTTABLE]),
    RowIDs = [R || [R|_] <- Rows],
    BoundUpdStmt = oci_port:prep_sql(?UPDATE, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundUpdStmt),
    BoundUpdStmtRes = oci_port:bind_vars(?UPDATE_BIND_LIST, BoundUpdStmt),
    ?assertMatch(ok, BoundUpdStmtRes),

    % Expected Invalid number Error (1722)
    ?assertMatch({error,{1722,_}}, oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , list_to_binary(["_Publisher_",integer_to_list(I),"_"])                           % publisher
         , I+I/3                                                                            % rank
         , I+I/2                                                                            % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , if I > (RowCount-2) -> <<"error">>; true -> integer_to_binary(I+1) end           % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , I+2                                                                              % chapters
         , I+1                                                                              % votes_first_rank
         , Key
         } || {Key, I} <- lists:zip(RowIDs, lists:seq(1, length(RowIDs)))]
        , 1, BoundUpdStmt
    )),

    ?ELog("testing rollback table ~s", [?TESTTABLE]),
    ?assertEqual({cols, Cols}, oci_port:exec_stmt(SelStmt)),
    ?assertEqual({{rows, Rows}, false}, oci_port:fetch_rows(RowCount, SelStmt)),
    ?assertEqual(ok, oci_port:close(SelStmt)).

commit_rollback(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|               commit_rollback               |"),
    ?ELog("+---------------------------------------------+"),
    RowCount = 3,

    flush_table(OciSession),

    ?ELog("inserting into table ~s", [?TESTTABLE]),
    BoundInsStmt = oci_port:prep_sql(?INSERT, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    BoundInsStmtRes = oci_port:bind_vars(?BIND_LIST, BoundInsStmt),
    ?assertMatch(ok, BoundInsStmtRes),
    ?assertMatch({rowids, _},
        oci_port:exec_stmt(
          [{ I                                                              % pkey
           , list_to_binary(["_publisher_",integer_to_list(I),"_"])         % publisher
           , I+I/2                                                          % rank
           , I+I/3                                                          % hero
           , list_to_binary([rand:uniform(255)
                             || _I <- lists:seq(1,rand:uniform(5)+5)])    % reality
           , I                                                              % votes
           , oci_util:edatetime_to_ora(os:timestamp())                      % createdate
           , I*2+I/1000                                                     % chapters
           , I                                                              % votes_first_rank
           } || I <- lists:seq(1, RowCount)]
          , 1, BoundInsStmt
    )),
    ?assertEqual(ok, oci_port:close(BoundInsStmt)),

    ?ELog("selecting from table ~s", [?TESTTABLE]),
    SelStmt = oci_port:prep_sql(?SELECT_WITH_ROWID, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt),
    {cols, Cols} = oci_port:exec_stmt(SelStmt),
    ?assertEqual(10, length(Cols)),
    {{rows, Rows}, false} = oci_port:fetch_rows(RowCount, SelStmt),
    ?assertEqual(RowCount, length(Rows)),

    ?ELog("update in table ~s", [?TESTTABLE]),
    RowIDs = [R || [R|_] <- Rows],
    ?ELog("rowids ~p", [RowIDs]),
    BoundUpdStmt = oci_port:prep_sql(?UPDATE, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundUpdStmt),
    BoundUpdStmtRes = oci_port:bind_vars(?UPDATE_BIND_LIST, BoundUpdStmt),
    ?assertMatch(ok, BoundUpdStmtRes),
    ?assertMatch({rowids, _},
        oci_port:exec_stmt(
          [{ I                                                              % pkey
           , list_to_binary(["_Publisher_",integer_to_list(I),"_"])         % publisher
           , I+I/3                                                          % rank
           , I+I/2                                                          % hero
           , list_to_binary([rand:uniform(255)
                             || _I <- lists:seq(1,rand:uniform(5)+5)])    % reality
           , integer_to_binary(I+1)                                         % votes
           , oci_util:edatetime_to_ora(os:timestamp())                      % createdate
           , I+2                                                            % chapters
           , I+1                                                            % votes_first_rank
           , Key
           } || {Key, I} <- lists:zip(RowIDs, lists:seq(1, length(RowIDs)))]
          , -1, BoundUpdStmt
    )),

    ?assertMatch(ok, oci_port:close(BoundUpdStmt)),

    ?ELog("testing rollback table ~s", [?TESTTABLE]),
    ?assertEqual(ok, oci_port:rollback(OciSession)),
    ?assertEqual({cols, Cols}, oci_port:exec_stmt(SelStmt)),
    {{rows, NewRows}, false} = oci_port:fetch_rows(RowCount, SelStmt),
    ?assertEqual(lists:sort(Rows), lists:sort(NewRows)),
    ?assertEqual(ok, oci_port:close(SelStmt)).

asc_desc(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                  asc_desc                   |"),
    ?ELog("+---------------------------------------------+"),
    RowCount = 10,

    flush_table(OciSession),

    ?ELog("inserting into table ~s", [?TESTTABLE]),
    BoundInsStmt = oci_port:prep_sql(?INSERT, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    ?assertMatch(ok, oci_port:bind_vars(?BIND_LIST, BoundInsStmt)),
    ?assertMatch({rowids, _}, oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , list_to_binary(["_publisher_",integer_to_list(I),"_"])                           % publisher
         , I+I/2                                                                            % rank
         , I+I/3                                                                            % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , I                                                                                % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , I*2+I/1000                                                                       % chapters
         , I                                                                                % votes_first_rank
         } || I <- lists:seq(1, RowCount)]
        , 1, BoundInsStmt
    )),
    ?assertEqual(ok, oci_port:close(BoundInsStmt)),

    ?ELog("selecting from table ~s", [?TESTTABLE]),
    SelStmt1 = oci_port:prep_sql(?SELECT_ROWID_ASC, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt1),
    SelStmt2 = oci_port:prep_sql(?SELECT_ROWID_DESC, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelStmt2),
    ?assertEqual(oci_port:exec_stmt(SelStmt1), oci_port:exec_stmt(SelStmt2)),

    {{rows, Rows11}, false} = oci_port:fetch_rows(5, SelStmt1),
    {{rows, Rows12}, false} = oci_port:fetch_rows(5, SelStmt1),
    {{rows, []}, true} = oci_port:fetch_rows(1, SelStmt1),
    Rows1 = Rows11++Rows12,
    ?assertEqual(RowCount, length(Rows1)),

    {{rows, Rows21}, false} = oci_port:fetch_rows(5, SelStmt2),
    {{rows, Rows22}, false} = oci_port:fetch_rows(5, SelStmt2),
    {{rows, []}, true} = oci_port:fetch_rows(1, SelStmt2),
    Rows2 = Rows21++Rows22,
    ?assertEqual(RowCount, length(Rows2)),

    ?ELog("Got rows asc ~p~n desc ~p", [Rows1, Rows2]),

    ?assertEqual(Rows1, lists:reverse(Rows2)),

    ?assertEqual(ok, oci_port:close(SelStmt1)),
    ?assertEqual(ok, oci_port:close(SelStmt2)).

describe(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                 describe                    |"),
    ?ELog("+---------------------------------------------+"),

    flush_table(OciSession),

    ?ELog("describing table ~s", [?TESTTABLE]),
    {ok, Descs} = oci_port:describe(list_to_binary(?TESTTABLE), 'OCI_PTYPE_TABLE', OciSession),
    ?assertEqual(9, length(Descs)),
    ?ELog("table ~s has ~p", [?TESTTABLE, Descs]).

function(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                function                     |"),
    ?ELog("+---------------------------------------------+"),

    CreateFunction = oci_port:prep_sql(<<"
        create or replace function "
        ?TESTFUNCTION
        "(sal in number, com in number)
            return number is
        begin
            return ((sal*12)+(sal*12*nvl(com,0)));
        end;
    ">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateFunction),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateFunction)),
    ?assertEqual(ok, oci_port:close(CreateFunction)),

    SelectStmt = oci_port:prep_sql(<<"select "?TESTFUNCTION"(10,30) from dual">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelectStmt),
    {cols, [Col|_]} = oci_port:exec_stmt(SelectStmt),
    ?assertEqual(<<?TESTFUNCTION"(10,30)">>, element(1, Col)),
    {{rows, [[F|_]|_]}, true} = oci_port:fetch_rows(2, SelectStmt),
    ?assertEqual(<<3,194,38,21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>, F),
    ?assertEqual(ok, oci_port:close(SelectStmt)),

    SelectBoundStmt = oci_port:prep_sql(<<"select "?TESTFUNCTION"(:SAL,:COM) from dual">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelectBoundStmt),
    ?assertMatch(ok, oci_port:bind_vars([{<<":SAL">>, 'SQLT_INT'}, {<<":COM">>, 'SQLT_INT'}], SelectBoundStmt)),
    {cols, [Col2|_]} = oci_port:exec_stmt([{10, 30}], 1, SelectBoundStmt),
    ?assertEqual(<<?TESTFUNCTION"(:SAL,:COM)">>, element(1, Col2)),
    ?assertMatch({{rows, [[F|_]|_]}, true}, oci_port:fetch_rows(2, SelectBoundStmt)),
    ?ELog("Col ~p", [Col]),
    ?assertEqual(ok, oci_port:close(SelectBoundStmt)),

    % Drop function
    DropFunStmt = oci_port:prep_sql(<<"drop function "?TESTFUNCTION>>, OciSession),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropFunStmt)),
    ?assertEqual(ok, oci_port:close(DropFunStmt)).

procedure_scalar(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|             procedure_scalar                |"),
    ?ELog("+---------------------------------------------+"),

    CreateProcedure = oci_port:prep_sql(<<"
        create or replace procedure "
        ?TESTPROCEDURE
        "(p_first in number, p_second in out varchar2, p_result out number)
        is
        begin
            p_result := p_first + to_number(p_second);
            p_second := 'The sum is ' || to_char(p_result);
        end "?TESTPROCEDURE";
        ">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateProcedure),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateProcedure)),
    ?assertEqual(ok, oci_port:close(CreateProcedure)),

    ExecStmt = oci_port:prep_sql(<<"begin "?TESTPROCEDURE"(:p_first,:p_second,:p_result); end;">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, ExecStmt),
    ?assertMatch(ok, oci_port:bind_vars([ {<<":p_first">>, in, 'SQLT_INT'}
                                        , {<<":p_second">>, inout, 'SQLT_CHR'}
                                        , {<<":p_result">>, out, 'SQLT_INT'}], ExecStmt)),
    ?assertEqual({executed, 1,
                  [{<<":p_second">>,<<"The sum is 51">>},
                   {<<":p_result">>,51}]},
                 oci_port:exec_stmt([{50, <<"1             ">>, 3}], 1, ExecStmt)),
    ?assertEqual({executed, 1,
                  [{<<":p_second">>,<<"The sum is 6">>},
                   {<<":p_result">>,6}]}, oci_port:exec_stmt([{5, <<"1             ">>, 3}], 1, ExecStmt)),
    ?assertEqual(ok, oci_port:close(ExecStmt)),

    ExecStmt1 = oci_port:prep_sql(<<"call "?TESTPROCEDURE"(:p_first,:p_second,:p_result)">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, ExecStmt1),
    ?assertMatch(ok, oci_port:bind_vars(
                       [ {<<":p_first">>, in, 'SQLT_INT'}, {<<":p_second">>, inout, 'SQLT_CHR'},
                         {<<":p_result">>, out, 'SQLT_INT'}], ExecStmt1)),
    ?assertEqual({executed, 0,
                  [{<<":p_second">>,<<"The sum is 52">>}, {<<":p_result">>,52}]},
                 oci_port:exec_stmt([{50, <<"2             ">>, 3}], 1, ExecStmt1)),
    ?assertEqual({executed, 0,
                  [{<<":p_second">>,<<"The sum is 7">>},
                   {<<":p_result">>,7}]}, oci_port:exec_stmt([{5, <<"2             ">>, 3}], 1, ExecStmt1)),
    ?assertEqual(ok, oci_port:close(ExecStmt1)),

    ExecStmt2 = oci_port:prep_sql(<<"declare begin "?TESTPROCEDURE"(:p_first,:p_second,:p_result); end;">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, ExecStmt2),
    ?assertMatch(ok, oci_port:bind_vars([ {<<":p_first">>, in, 'SQLT_INT'}
                                        , {<<":p_second">>, inout, 'SQLT_CHR'}
                                        , {<<":p_result">>, out, 'SQLT_INT'}], ExecStmt2)),
    ?assertEqual({executed, 1,
                  [{<<":p_second">>,<<"The sum is 53">>},
                   {<<":p_result">>,53}]}, oci_port:exec_stmt([{50, <<"3             ">>, 3}], 1, ExecStmt2)),
    ?assertEqual({executed, 1,
                  [{<<":p_second">>,<<"The sum is 8">>},
                   {<<":p_result">>,8}]}, oci_port:exec_stmt([{5, <<"3             ">>, 3}], 1, ExecStmt2)),
    ?assertEqual(ok, oci_port:close(ExecStmt2)),

    % Drop procedure
    DropProcStmt = oci_port:prep_sql(<<"drop procedure "?TESTPROCEDURE>>, OciSession),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropProcStmt)),
    ?assertEqual(ok, oci_port:close(DropProcStmt)).

procedure_cur(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|               procedure_cur                 |"),
    ?ELog("+---------------------------------------------+"),

    RowCount = 10,

    flush_table(OciSession),

    ?ELog("inserting into table ~s", [?TESTTABLE]),
    BoundInsStmt = oci_port:prep_sql(?INSERT, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    ?assertMatch(ok, oci_port:bind_vars(?BIND_LIST, BoundInsStmt)),
    ?assertMatch({rowids, _}, oci_port:exec_stmt(
        [{ I                                                                                % pkey
         , list_to_binary(["_publisher_",integer_to_list(I),"_"])                           % publisher
         , I+I/2                                                                            % rank
         , I+I/3                                                                            % hero
         , list_to_binary([rand:uniform(255) || _I <- lists:seq(1,rand:uniform(5)+5)])  % reality
         , I                                                                                % votes
         , oci_util:edatetime_to_ora(os:timestamp())                                        % createdate
         , I*2+I/1000                                                                       % chapters
         , I                                                                                % votes_first_rank
         } || I <- lists:seq(1, RowCount)]
        , 1, BoundInsStmt
    )),
    ?assertEqual(ok, oci_port:close(BoundInsStmt)),

    CreateProcedure = oci_port:prep_sql(<<"
        create or replace procedure "
        ?TESTPROCEDURE
        "(p_cur out sys_refcursor)
        is
        begin
            open p_cur for select * from "?TESTTABLE";
        end "?TESTPROCEDURE";
        ">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateProcedure),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateProcedure)),
    ?assertEqual(ok, oci_port:close(CreateProcedure)),

    ExecStmt = oci_port:prep_sql(<<"begin "?TESTPROCEDURE"(:cursor); end;">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, ExecStmt),
    ?assertMatch(ok, oci_port:bind_vars([{<<":cursor">>, out, 'SQLT_RSET'}], ExecStmt)),
    {executed, 1, [{<<":cursor">>, CurStmt}]} = oci_port:exec_stmt(ExecStmt),
    {cols, _Cols} = oci_port:exec_stmt(CurStmt),
    {{rows, Rows}, true} = oci_port:fetch_rows(RowCount+1, CurStmt),
    ?assertEqual(RowCount, length(Rows)),
    ?assertEqual(ok, oci_port:close(CurStmt)),
    ?assertEqual(ok, oci_port:close(ExecStmt)),

    % Drop procedure
    DropProcStmt = oci_port:prep_sql(<<"drop procedure "?TESTPROCEDURE>>, OciSession),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropProcStmt)),
    ?assertEqual(ok, oci_port:close(DropProcStmt)).

timestamp_interval_datatypes(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|       timestamp_interval_datatypes          |"),
    ?ELog("+---------------------------------------------+"),

    CreateSql = <<
        "create table "?TESTTABLE" ("
            "name varchar(30), "
            "dat DATE DEFAULT (sysdate), "
            "ts TIMESTAMP DEFAULT (systimestamp), "
            "tstz TIMESTAMP WITH TIME ZONE DEFAULT (systimestamp), "
            "tsltz TIMESTAMP WITH LOCAL TIME ZONE DEFAULT (systimestamp), "
            "iym INTERVAL YEAR(3) TO MONTH DEFAULT '234-2', "
            "ids INTERVAL DAY TO SECOND(3) DEFAULT '4 5:12:10.222')"
    >>,
    InsertNameSql = <<"insert into "?TESTTABLE" (name) values (:name)">>,
    InsertSql = <<"insert into "?TESTTABLE" (name, dat, ts, tstz, tsltz, iym, ids) "
                  "values (:name, :dat, :ts, :tstz, :tsltz, :iym, :ids)">>,
    InsertBindSpec = [ {<<":name">>, 'SQLT_CHR'}
                     , {<<":dat">>, 'SQLT_DAT'}
                     , {<<":ts">>, 'SQLT_TIMESTAMP'}
                     , {<<":tstz">>, 'SQLT_TIMESTAMP_TZ'}
                     , {<<":tsltz">>, 'SQLT_TIMESTAMP_LTZ'}
                     , {<<":iym">>, 'SQLT_INTERVAL_YM'}
                     , {<<":ids">>, 'SQLT_INTERVAL_DS'}],
    SelectSql = <<"select * from "?TESTTABLE"">>,

    DropStmt = oci_port:prep_sql(?DROP, OciSession),
    oci_port:exec_stmt(DropStmt),
    oci_port:close(DropStmt),

    CreateStmt = oci_port:prep_sql(CreateSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateStmt),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateStmt)),
    ?assertEqual(ok, oci_port:close(CreateStmt)),

    BoundInsStmt = oci_port:prep_sql(InsertNameSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    ?assertMatch(ok, oci_port:bind_vars([{<<":name">>, 'SQLT_CHR'}], BoundInsStmt)),
    ?assertMatch({rowids, _}, oci_port:exec_stmt(
        [{list_to_binary(io_lib:format("'~s'", [D]))}
         || D <- ["test1", "test2", "test3", "test4"]], BoundInsStmt)),
    ?assertMatch(ok, oci_port:close(BoundInsStmt)),

    SelectStmt = oci_port:prep_sql(SelectSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelectStmt),
    ?assertMatch({cols, [{<<"NAME">>,'SQLT_CHR',_,0,0}
                        ,{<<"DAT">>,'SQLT_DAT',7,0,0}
                        ,{<<"TS">>,'SQLT_TIMESTAMP',11,0,6}
                        ,{<<"TSTZ">>,'SQLT_TIMESTAMP_TZ',13,0,6}
                        ,{<<"TSLTZ">>,'SQLT_TIMESTAMP_LTZ',11,0,6}
                        ,{<<"IYM">>,'SQLT_INTERVAL_YM',5,3,0}
                        ,{<<"IDS">>,'SQLT_INTERVAL_DS',11,2,3}]}
                 , oci_port:exec_stmt(SelectStmt)),
    RowRet = oci_port:fetch_rows(5, SelectStmt),
    ?assertEqual(ok, oci_port:close(SelectStmt)),

    ?assertMatch({{rows, _}, true}, RowRet),
    {{rows, Rows}, true} = RowRet,
    NewRows =
    [begin
         {{C2Y,C2M,C2D}, {C2H,C2Min,C2S}} = oci_util:from_dts(C2),
         {{C3Y,C3M,C3D}, {C3H,C3Min,C3S}, C3Ns} = oci_util:from_dts(C3),
         {{C4Y,C4M,C4D}, {C4H,C4Min,C4S}, C4Ns, {C4TzH,C4TzM}} = oci_util:from_dts(C4),
         {{C5Y,C5M,C5D}, {C5H,C5Min,C5S}, C5Ns} = oci_util:from_dts(C5),
         {C6Y,C6M} = oci_util:from_intv(C6),
         {C7D,C7H,C7M,C7S,C7Ns} = oci_util:from_intv(C7),
         {list_to_binary([C1, "_1"])
          , oci_util:to_dts({{C2Y+1,C2M+1,C2D+1}, {C2H+1,C2Min+1,C2S+1}})
          , oci_util:to_dts({{C3Y+1,C3M+1,C3D+1}, {C3H+1,C3Min+1,C3S+1}, C3Ns+1})
          , oci_util:to_dts({{C4Y+1,C4M+1,C4D+1}, {C4H+1,C4Min+1,C4S+1}, C4Ns+1, {C4TzH+1,C4TzM+1}})
          , oci_util:to_dts({{C5Y+1,C5M+1,C5D+1}, {C5H+1,C5Min+1,C5S+1}, C5Ns+1})
          , oci_util:to_intv({C6Y+1,C6M+1})
          , oci_util:to_intv({C7D+1,C7H+1,C7M+1,C7S+1,C7Ns+1})}
     end
     || [C1, C2, C3, C4, C5, C6, C7] <- Rows],
    BoundAllInsStmt = oci_port:prep_sql(InsertSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundAllInsStmt),
    ?assertMatch(ok, oci_port:bind_vars(InsertBindSpec, BoundAllInsStmt)),
    Inserted = oci_port:exec_stmt(NewRows, BoundAllInsStmt),
    ?assertMatch({rowids, _}, Inserted),
    {rowids, RowIds} = Inserted,
    ?assertEqual(length(NewRows), length(RowIds)),
    ?assertMatch(ok, oci_port:close(BoundAllInsStmt)),

    DropStmtFinal = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmtFinal),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropStmtFinal)),
    ?assertEqual(ok, oci_port:close(DropStmtFinal)),
    ok.

stmt_reuse_onerror(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|             stmt_reuse_onerror              |"),
    ?ELog("+---------------------------------------------+"),

    CreateSql = <<"create table "?TESTTABLE" (unique_num number not null primary key)">>,
    InsertSql = <<"insert into "?TESTTABLE" (unique_num) values (:unique_num)">>,

    DropStmt = oci_port:prep_sql(?DROP, OciSession),
    oci_port:exec_stmt(DropStmt),
    oci_port:close(DropStmt),

    CreateStmt = oci_port:prep_sql(CreateSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateStmt),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateStmt)),
    ?assertEqual(ok, oci_port:close(CreateStmt)),

    BoundInsStmt = oci_port:prep_sql(InsertSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    ?assertMatch(ok, oci_port:bind_vars([{<<":unique_num">>, 'SQLT_INT'}], BoundInsStmt)),
    ?assertMatch({rowids, _}, oci_port:exec_stmt([{1}], BoundInsStmt)),
    ?assertMatch({error,{1,<<"ORA-00001",_/binary>>}}, oci_port:exec_stmt([{1}], BoundInsStmt)),
    ?assertMatch({rowids, _}, oci_port:exec_stmt([{2}], BoundInsStmt)),
    ?assertMatch({error,{1,<<"ORA-00001",_/binary>>}}, oci_port:exec_stmt([{2}], BoundInsStmt)),
    ?assertMatch(ok, oci_port:close(BoundInsStmt)),

    DropStmtFinal = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmtFinal),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropStmtFinal)),
    ?assertEqual(ok, oci_port:close(DropStmtFinal)),
    ok.

multiple_bind_reuse(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|             multiple_bind_reuse             |"),
    ?ELog("+---------------------------------------------+"),

    Cols = [lists:flatten(io_lib:format("col~p", [I]))
            || I <- lists:seq(1, 10)],
    BindVarCols = [io_lib:format(":P_~s", [C]) || C <- Cols],
    CreateSql = <<"create table "?TESTTABLE" (",
                  (list_to_binary(
                     string:join(
                       [io_lib:format("~s varchar(30)", [C]) || C <- Cols],
                       ", ")))/binary,
                  ")">>,
    InsertSql = <<"insert into "?TESTTABLE" (",
                    (list_to_binary(
                     string:join(
                       [io_lib:format("~s", [C]) || C <- Cols],
                       ", ")))/binary,
                  ") values (",
                  (list_to_binary(string:join(BindVarCols,", ")))/binary,")">>,
    SelectSql = <<"select * from "?TESTTABLE"">>,
    InsertBindVars = [{list_to_binary(BC), 'SQLT_CHR'} || BC <- BindVarCols],

    DropStmt = oci_port:prep_sql(?DROP, OciSession),
    oci_port:exec_stmt(DropStmt),
    oci_port:close(DropStmt),

    Data = [list_to_tuple([lists:nth(rand:uniform(3),
                                     [<<"">>, <<"big">>, <<"small">>])
                           || _ <- Cols]) || _ <- lists:seq(1, 10)],

    CreateStmt = oci_port:prep_sql(CreateSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateStmt),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateStmt)),
    ?assertEqual(ok, oci_port:close(CreateStmt)),

    BoundInsStmt = oci_port:prep_sql(InsertSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, BoundInsStmt),
    ?assertMatch(ok, oci_port:bind_vars(InsertBindVars, BoundInsStmt)),
    [?assertMatch({rowids, _}, oci_port:exec_stmt([R], BoundInsStmt)) || R <- Data],

    SelectStmt = oci_port:prep_sql(SelectSql, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelectStmt),
    ?assertEqual({cols, [{list_to_binary(string:to_upper(C)),'SQLT_CHR',60,0,0}
                        || C <- Cols]},
                 oci_port:exec_stmt(SelectStmt)),
    {{rows, Rows}, true} = oci_port:fetch_rows(length(Data)+1, SelectStmt),
    {Error, _, _} =
    lists:foldl(fun(_I, {Flag, [ID|Insert], [ID|Select]}) ->
                        %% ?debugFmt("~p. expected ~p", [I, ID]),
                        %% ?debugFmt("~p. value    ~p", [I, ID]),
                        {Flag, Insert, Select};
                   (I, {_, [ID|Insert], [SD|Select]}) ->
                        ?debugFmt("~p. expected ~p", [I, ID]),
                        ?debugFmt("~p. value    ~p", [I, SD]),
                        {true, Insert, Select}
                end, {false, Data, [list_to_tuple(R) || R <- Rows]},
                lists:seq(1, length(Data))),
    ?assertEqual(false, Error),
    ?assertEqual(ok, oci_port:close(SelectStmt)),

    ?assertMatch(ok, oci_port:close(BoundInsStmt)),

    DropStmtFinal = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmtFinal),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropStmtFinal)),
    ?assertEqual(ok, oci_port:close(DropStmtFinal)),
    ok.


-define(current_pool_session_ids(__OciSession),
        (fun(OciSess) ->
                 Stmt = oci_port:prep_sql(?SESSSQL, OciSess),
                 ?assertMatch({cols, _}, oci_port:exec_stmt(Stmt)),
                 {{rows, CurSessions}, true} = oci_port:fetch_rows(10000, Stmt),
                 ?assertEqual(ok, oci_port:close(Stmt)),
                 CurSessions
         end)(__OciSession)).

-define(kill_session(__OciSession, __SessionToKill),
        (fun(OciSessKS, Sess2Kill) ->
                 StmtKS = oci_port:prep_sql(
                            <<"alter system kill session '", Sess2Kill/binary,
                              "' immediate">>, OciSessKS),
                 case oci_port:exec_stmt(StmtKS) of
                     {error,{30, _}} -> ok;
                     {error,{31, _}} -> ok;
                     {executed, 0} -> ?ELog("~p closed", [Sess2Kill])
                 end,
                 ?assertEqual(ok, oci_port:close(StmtKS))
         end)(__OciSession, __SessionToKill)).

check_ping(#{ocisession := OciSession, conf := #{tns := Tns, user := User, password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                 check_ping                  |"),
    ?ELog("+---------------------------------------------+"),
    SessionsBefore = ?current_pool_session_ids(OciSession),
    %% Connection with ping timeout set to 1 second
    PingOciPort = erloci:new([{logging, true}, {ping_timeout, 1000},
                              {env, [{"NLS_LANG", "GERMAN_SWITZERLAND.AL32UTF8"}]}]),
    PingOciSession = oci_port:get_session(Tns, User, Pswd, PingOciPort),
    SessionsAfter = ?current_pool_session_ids(OciSession),
    [PingSession | _] = lists:flatten(SessionsAfter) -- lists:flatten(SessionsBefore),
    ?assertEqual(pong, oci_port:ping(PingOciSession)),
    ?assertEqual(ok, ?kill_session(OciSession, PingSession)),
    ?debugMsg("sleeping for 2 seconds so that ping would realize the session is dead"),
    timer:sleep(2000),
    ?assertEqual(pang, oci_port:ping(PingOciSession)),
    oci_port:close(PingOciPort).

check_session_without_ping(#{ocisession := OciSession,
                             conf := #{tns := Tns, user := User, password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|         check_session_without_ping          |"),
    ?ELog("+---------------------------------------------+"),
    SessionsBefore = ?current_pool_session_ids(OciSession),
    Opts = [{logging, true}, {env, [{"NLS_LANG", "GERMAN_SWITZERLAND.AL32UTF8"}]}],
    NoPingOciPort = erloci:new(Opts),
    NoPingOciSession = oci_port:get_session(Tns, User, Pswd, NoPingOciPort),
    SelStmt1 = oci_port:prep_sql(<<"select 4+4 from dual">>, NoPingOciSession),
    SessionsAfter = ?current_pool_session_ids(OciSession),
    ?assertMatch({cols, _}, oci_port:exec_stmt(SelStmt1)),
    [NoPingSession | _] = lists:flatten(SessionsAfter) -- lists:flatten(SessionsBefore),
    ?assertEqual(ok, ?kill_session(OciSession, NoPingSession)),
    ?assertMatch({error, {3113, _}}, oci_port:exec_stmt(SelStmt1)),
    oci_port:close(NoPingOciPort).

check_session_with_ping(#{ocisession := OciSession, conf := #{tns := Tns, user := User, password := Pswd}}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|           check_session_with_ping           |"),
    ?ELog("+---------------------------------------------+"),
    SessionsBefore = ?current_pool_session_ids(OciSession),
    %% Connection with ping timeout set to 1 second
    Opts = [{logging, true}, {ping_timeout, 1000}, {env, [{"NLS_LANG", "GERMAN_SWITZERLAND.AL32UTF8"}]}],
    PingOciPort = erloci:new(Opts),
    PingOciSession = oci_port:get_session(Tns, User, Pswd, PingOciPort),
    SelStmt1 = oci_port:prep_sql(<<"select 4+4 from dual">>, PingOciSession),
    SessionsAfter = ?current_pool_session_ids(OciSession),
    ?assertMatch({cols, _}, oci_port:exec_stmt(SelStmt1)),
    [NoPingSession | _] = lists:flatten(SessionsAfter) -- lists:flatten(SessionsBefore),
    ?assertEqual(ok, ?kill_session(OciSession, NoPingSession)),
    timer:sleep(2000),
    ?assertMatch({'EXIT', {noproc, _}}, catch oci_port:exec_stmt(SelStmt1)),
    oci_port:close(PingOciPort).

urowid(#{ocisession := OciSession}) ->
    ?ELog("+---------------------------------------------+"),
    ?ELog("|                  urowid                     |"),
    ?ELog("+---------------------------------------------+"),

    CreateStmt = oci_port:prep_sql(
                   <<"create table "?TESTTABLE" ("
                       " c1 number,"
                       " c2 varchar2(3000),"
                       " primary key(c1, c2))"
                     " organization index">>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, CreateStmt),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(CreateStmt)),
    ?assertEqual(ok, oci_port:close(CreateStmt)),

    ?ELog("testing insert returns UROWID"),
    [begin
         StmtInsert = oci_port:prep_sql(
                        <<"insert into "?TESTTABLE" values(",
                          (integer_to_binary(I))/binary, ",'",
                          (list_to_binary(
                             lists:duplicate(crypto:rand_uniform(1000,3000), I))
                          )/binary, "')">>, OciSession),
        ?assertMatch({?PORT_MODULE, statement, _, _, _}, StmtInsert),
        ?assertMatch({rowids, [_]}, oci_port:exec_stmt(StmtInsert)),
        ?assertEqual(ok, oci_port:close(StmtInsert))
     end || I <- lists:seq($0,$9)],

    ?ELog("testing select UROWID"),
    SelectStmt = oci_port:prep_sql(<<"select rowid, c1 from "?TESTTABLE>>, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, SelectStmt),
    ?assertMatch({cols, _}, oci_port:exec_stmt(SelectStmt)),
    {{rows, Rows}, true} = oci_port:fetch_rows(100, SelectStmt),
    ?assertEqual(ok, oci_port:close(SelectStmt)),

    ?ELog("testing update UROWID"),
    BoundUpdStmt = oci_port:prep_sql(
                     <<"update "?TESTTABLE" set c1 = :p_c1"
                       " where "?TESTTABLE".rowid = :p_rowid">>, OciSession),
    ?assertMatch(ok, oci_port:bind_vars([{<<":p_c1">>, 'SQLT_INT'},
                                             {<<":p_rowid">>, 'SQLT_STR'}], BoundUpdStmt)),
    ?assertMatch({rowids, _},
                 oci_port:exec_stmt(
                   [{$0 + $9 - list_to_integer(oci_util:from_num(C1)), RowId}
                    || [RowId, C1] <- Rows], -1, BoundUpdStmt)),
    ?assertMatch(ok, oci_port:close(BoundUpdStmt)),

    DropStmtFinal = oci_port:prep_sql(?DROP, OciSession),
    ?assertMatch({?PORT_MODULE, statement, _, _, _}, DropStmtFinal),
    ?assertEqual({executed, 0}, oci_port:exec_stmt(DropStmtFinal)),
    ?assertEqual(ok, oci_port:close(DropStmtFinal)),
    ok.
