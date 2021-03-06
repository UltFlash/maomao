/* Copyright(C) 1995-96, Swedish Institute of Computer Science */

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   File   : SYSTEM.PL							     %
%   Authors : Mats Carlsson, Stefan Andersson				     %
%   Updated: 11 May 1996						     %
%   Purpose: Operating system utilities					     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module(system, [
	now/1,
	datime/1,
	datime/2,
	environ/2,
	host_name/1,
	host_id/1,
	file_exists/1,
	file_exists/2,
	file_property/2,
	rename_file/2,
	delete_file/1,
	delete_file/2,
	make_directory/1,
	working_directory/2,
	directory_files/2,
	mktemp/2,
	tmpnam/1,
	system/0,
	system/1,
	system/2,
	shell/0,
	shell/1,
	shell/2,
	exec/3,
        popen/3,
	sleep/1,
	pid/1,
	kill/2,
	wait/2
		  ]).

:- dynamic foreign/3, foreign_resource/2.
:- discontiguous foreign/2, foreign/3. % [PM]

%-------------------------------------------------------------------------
%   now(?When)
%   returns the current date and time as a UNIX timestamp When.

foreign(sp_time,  c, now([-integer])).

%-------------------------------------------------------------------------
%   datime(-Datime)
%   Datime is a timestamp of the form datime(Year,Month,Day,Hour,Min,Sec)
%   containing the current date and time.  All fields are integers.

datime(Datime) :-
	now(When),
	datime(When, Datime).

datime(When, datime(Year,Month,Day,Hour,Min,Sec)) :-
	c_datime(When, Year, Month, Day, Hour, Min, Sec).

foreign(sp_datime,  c, c_datime(+integer,
				-integer, -integer, -integer,
                                -integer, -integer, -integer)).


%-------------------------------------------------------------------------
%   environ(?Var, ?Value)
%   Var is the name of a UNIX environment variable, and Value is its value.
%   Both are atoms.  Can be used to enumerate all current environment
%   variables.

%% environ(Var, Value) :-
%% 	var(Var), !,
%% 	environ(0, Var, Value).
environ(Var, Value) :-
        var(Var), !,
        system_environ(Var, Value).
environ(Var, Value) :-
	c_getenv(Var, Value, 0).

% [PM] WinCE Backtrack over a snapshot of the environment.
system_environ(Var, Value) :-
   c_environ(Environ, Res),     % A snapshot of the environment
   Res == 0,                    % consider reporting errors if non-zero
   key_member(Environ, Var, Value).

key_member([KV|KVs], K,V) :-
   key_member1(KVs, K,V, KV).

key_member1([], K,V, (K=V)).
key_member1([_KV|_KVs], K,V, (K=V)).
key_member1([KV|KVs], K,V, _KV) :-
   key_member1(KVs, K,V, KV).

%% [PM] Corresponds to what was doen pre WinCE
%% system_environ(Var, Value) :-
%%   environ(0, Var, Value).
%%
%% environ(I, Variable, Value) :-
%% 	c_getenv(I, Var, Val, 0),
%% 	(   Variable = Var, Value = Val
%% 	;   J is I+1,
%% 	    environ(J, Variable, Value)
%%	).

% [PM] WinCE Not public yet
%--------------------------------------------------------------------------
%   setenv(+Var, +Value)
%   Var is the name of a UNIX environment variable, and Value is its value.
%   Both are atoms.  Sets the value of the environment variable Var in
%   the current process and in child processes spawned after the call
%   to setenv/2.
%   Note: Will leak memory on most platforms due to general losynes of
%   environment variable API.

setenv(Var, Value) :-
   atom(Var),
   atom(Value), !,
   c_setenv(Var, Value, Res),
   Res = 0.                     % FIXME: Error handling?
setenv(Var, Value) :- atom(Var), !,
   prolog:illarg(type(atom), setenv(Var, Value), 2).
setenv(Var, Value) :-
   prolog:illarg(type(atom), setenv(Var, Value), 1).


%% [PM] WinCE Now pass out the value as a term
%% foreign(sp_getenv,    c, c_getenv(+string, -string, [-integer])).
foreign(sp_getenv1,    c, c_getenv(+string, -term, [-integer])).

%% [PM] WinCE
foreign(sp_setenv,    c, c_setenv(+string, +string, [-integer])).

%% [PM] WinCE backtrack over a copy of environ.
foreign(sp_environ,    c, c_environ(-term, [-integer])).
%% foreign(sp_argenv,    c, c_getenv(+integer, -string, -string, [-integer])).

%-------------------------------------------------------------------------
%   host_id(-HID)
%   HID is the unique identifier of the host executing the current
%   SICStus Prolog process.

foreign(sp_host_id,  c, host_id([-string])).

%   host_name(-HostName)
%   HostName is the standard host name of the host executing the current
%   SICStus Prolog process.

foreign(sp_host_name,c, host_name([-string])).


%=========================================================================
% [PM] WinCE Predicates to expand and unexpand relative file-names relative working directory.
system_absolute_file_name(FileRel, FileAbs) :-
   prolog:'$unix_cd'(Old, Old), % not working_directory/2 !!
   %% access(none) is implicit and critical (must not barf on
   %% directories or non-existing files).
   absolute_file_name(FileRel, FileAbs, [relative_to(Old)]).


%=========================================================================
% Predicates to handle files and directories

%-------------------------------------------------------------------------
%   file_exists(+FileName)
%   FileName is the name of an existing file or directory.

%% file_exists(FileName) :-
%% 	c_file_exists(FileName, 0, 0).
file_exists(FileName) :-
   % [PM] WinCE do not use [access(exists), fileerrors(off)], it would search
   system_absolute_file_name(FileName, FileNameAbs), % [PM] WinCE
   c_file_exists(FileNameAbs, 0, 0).

foreign(sp_access, c, c_file_exists(+string,+integer,[-integer])).

%   file_exists(+FileName, +Permissions)
%   FileName is the name of an existing file or directory which can be
%   accessed according to Permissions.  Permissions is an atom, an integer
%   (see access(2)), or a list of atoms and/or integers.  The atoms must
%   be drawn from the list [read,write,search,exists].

file_exists(FileName, Permissions) :-
	ground(Permissions),
	permission_bits(Permissions, 0, Bits), !,
	%% c_file_exists(FileName, Bits, 0).
        system_absolute_file_name(FileName, FileNameAbs), % [PM] WinCE
	c_file_exists(FileNameAbs, Bits, 0).
file_exists(FileName, Permissions) :-
	prolog:illarg(domain(term,list_of([read,write,search,exists,'Integer'])),
	              file_exists(FileName,Permissions), 2).


permission_bits([], Bits, Bits) :- !.
permission_bits([Head|Tail], Bits0, Bits) :- !,
	permission_bits(Head, Bits0, Bits1),
	permission_bits(Tail, Bits1, Bits).
permission_bits(read, Bits0, Bits) :- !, Bits is Bits0 \/ 4.
permission_bits(write, Bits0, Bits) :- !, Bits is Bits0 \/ 2.
permission_bits(search, Bits0, Bits) :- !, Bits is Bits0 \/ 1.
permission_bits(exists, Bits0,  Bits) :- !, Bits = Bits0.
permission_bits(N, Bits0, Bits) :-
	integer(N),
	Bits is Bits0 \/ (N/\7).

%-------------------------------------------------------------------------
%   file_property(+File,?Property)

file_property(File, Property) :-
	file_property(Property, Key, Prop),
        system_absolute_file_name(File, FileNameAbs), % [PM] WinCE
	sp_file_property(FileNameAbs, Key, Prop).

file_property(type(Prop), 0, Prop).
file_property(size(Prop), 1, Prop).
file_property(mod_time(Prop), 2, Prop).

foreign(sp_file_property, sp_file_property(+string,+integer,[-term])).

%-------------------------------------------------------------------------
%   rename_file(+OldName, +NewName)
%   OldName is the name of an existing file or directory, which will be
%   renamed to NewName.  If the operation fails, an exception is raised.

% [PM] WinCE
rename_file(OldName, NewName) :-
   system_absolute_file_name(OldName, OldNameAbs),
   system_absolute_file_name(NewName, NewNameAbs),
   rename_file_raw(OldNameAbs, NewNameAbs).

foreign(sp_rename,     c, rename_file_raw(+string,+string)).
%% foreign(sp_rename,     c, rename_file(+string,+string)).

%-------------------------------------------------------------------------
%   delete_file(+FileName)
%   Same as delete_file(+FileName, [recursive])

%   delete_file(+FileName, +Options)
%   FileName is the name of an existing file or directory. Options is a
%   list of options. Possible options are 'directory', 'recursive' or
%   'ignore'.  If FileName is not a directory it is deleted, otherwise
%   if the option 'directory' is specified but not 'recursive', the
%   directory will be deleted if it is empty. If 'recursive' is
%   specified and FileName is a directory, the directory and all its
%   subdirectories and files will be deleted.  If the operation fails,
%   an exception is raised unless the 'ignore' option is specified.

delete_file(FileName) :-
   system_absolute_file_name(FileName, FileNameAbs), % [PM] WinCE
   delete_file_recursive(FileNameAbs, _).

delete_file(FileName, Options) :-
	Goal = delete_file(FileName,Options),
	(   delete_file_options(Options, Dir, Recursive, Ignore) -> true
	;   prolog:illarg(domain(list(atom),delete_file_options), Goal, 2)
	),
        system_absolute_file_name(FileName, FileNameAbs), % [PM] WinCE
	(   nonvar(Recursive) ->
	    delete_file_recursive(FileNameAbs, Ignore)
	;   file_exists(FileNameAbs),
	    file_property(FileNameAbs, type(directory)),
	    nonvar(Dir) ->
	    sp_delete_dir(FileNameAbs, Ignore)
	;   sp_delete_file(FileNameAbs, Ignore)
	).

delete_file_options(-, _, _, _) :- !, fail.
delete_file_options([], _, _, _).
delete_file_options([Option|Options], Dir, Recursive, Ignore) :-
	delete_file_option(Option, Dir, Recursive, Ignore),
	delete_file_options(Options, Dir, Recursive, Ignore).

delete_file_option(-, _, _, _) :- !, fail.
delete_file_option(directory, true, _, _).
delete_file_option(recursive, _, true, _).
delete_file_option(ignore, _, _, true).

delete_file_recursive(DirAbs, Ignore) :-
        %% [PM] caller ensures Dir is absolute
	file_exists(DirAbs),
	file_property(DirAbs, type(directory)), !,
	directory_files_raw(DirAbs, Files),
	atom_concat(DirAbs, /, DirS),
	delete_files_rec(Files, DirS, Ignore),
	sp_delete_dir(DirAbs, Ignore).
delete_file_recursive(DirAbs, Ignore) :-
	sp_delete_file(DirAbs, Ignore).

delete_files_rec([], _, _).
delete_files_rec([File|Files], DirAbs, Ignore) :-
        (   File == '.' -> true
        ;   File == ..  -> true
        ;   atom_concat(DirAbs, File, DirFileAbs),
            delete_file_recursive(DirFileAbs, Ignore)
        ),
        delete_files_rec(Files, DirAbs, Ignore).

foreign(sp_del_file, sp_delete_file(+string,+term)).
foreign(sp_del_dir, sp_delete_dir(+string,+term)).

%-------------------------------------------------------------------------
%   working_directory(?OldDirectory, ?NewDirectory) OldDirectory is
%   the current working directory, and the working directory is set to
%   NewDirectory.  In particular, the goal working_directory(D,D)
%   unifies D with the current working directory without changing
%   anything.

/* this version is sensitive to load contexts etc.
working_directory(OldDirectory, NewDirectory) :-
	Goal = working_directory(OldDirectory,NewDirectory),
	absolute_file_name(., OldDirectory), 
	prolog:absolute_file_name_nd(NewDirectory, '', Goal, Abs, _, _), !,
	(   prolog:'$unix_cd'(_, Abs) -> true
	;   prolog:illarg(existence(directory,Abs,0), Goal, 2, Abs)
	).
*/
working_directory(OldDirectory, NewDirectory) :-
	prolog:'$unix_cd'(Old, Old),
	OldDirectory = Old,
        system_absolute_file_name(NewDirectory, NewDirectoryAbs), % [PM] WinCE
	(   prolog:'$unix_cd'(_, NewDirectoryAbs) -> true
	;   Goal = working_directory(OldDirectory,NewDirectory),
	    prolog:illarg(existence(directory,NewDirectory,0), Goal, 2)
	).

%-------------------------------------------------------------------------
%   directory_files(+Directory, ?Files) Unifies Files with a list of
%   files (and directories etc.) in Directory

%% [PM] WinCE string must be an absolute filename
foreign(sp_directory_files, directory_files_raw(+string,[-term])).
%% foreign(sp_directory_files, directory_files(+string,[-term])).

%% [PM] WinCE
directory_files(Directory, Files) :-
   system_absolute_file_name(Directory, DirectoryAbs),
   directory_files_raw(DirectoryAbs, Files).

%-------------------------------------------------------------------------
%   make_directory(+DirectoryName) Makes a new directory

%% [PM] WinCE
make_directory(DirectoryName) :-
   system_absolute_file_name(DirectoryName, DirectoryNameAbs),
   make_directory_raw(DirectoryNameAbs).

foreign(sp_make_dir, make_directory_raw(+string)).
%% foreign(sp_make_dir, make_directory(+string)).

%-------------------------------------------------------------------------
%   mktemp(+Template, -FileName)
%   Interface *similar* to the UNIX function mktemp(3).  A unique file name is
%   created and unified with FileName.  Template should contain
%   a file name with six trailing Xs.  The file name is that template
%   with the six Xs replaced to make the file name unique

mktemp(Template, FileName) :-
   system_absolute_file_name(Template, TemplateAbs), % [PM] WinCE
   c_mktemp(TemplateAbs, FileNameAbs0, Res),

   %% [PM] WinCE A change from 3.9.1 is that FileName is always
   %%      absolute even if Template was not.
   %%      Unfortunately, if Template is compound or contains
   %%      environment variable expansions, there is no way, in
   %%      general, to ensure that FileName is "as relative as"
   %%      Template. Discussed with Mats, decided that making the
   %%      resultant FileName always absolute is not a problem.
   FileName = FileNameAbs,
   mktemp_result(Res, Template, FileNameAbs0,FileNameAbs).

%% [PM] 3.9.1 Added error handling. xref system.c
mktemp_result(0, _Template, FileName0,FileName) :-
   FileName = FileName0.
mktemp_result(-1, Template, FileName0,FileName) :-
   Goal = mktemp(Template, FileName),
   ErrorMsg = FileName0,
   prolog:illarg(system(ErrorMsg), Goal, 0).
mktemp_result(-2, Template, _FileName0,FileName) :-
   Goal = mktemp(Template, FileName),
   ArgNo=1,
   prolog:illarg(domain(atom,file_template_with_six_trailing_X), Goal, ArgNo).
   
%-------------------------------------------------------------------------
%   tmpnam(-FileName)
%   Interface *similar* to the ANSI-C function tmpnam(3).  A unique
%   file name is % created and unified with FileName.
tmpnam(FileName) :-
   c_tmpnam(FileName0, Res),
   %% [PM] WinCe FileName0 is always absolute
   tmpnam_result(Res, FileName0,FileName).

%% [PM] 3.9.1 Added error handling. xref system.c
tmpnam_result(0, FileName0,FileName) :-
   FileName = FileName0.
tmpnam_result(-1, FileName0,FileName) :-
   Goal = tmpnam(FileName),
   ErrorMsg = FileName0,
   prolog:illarg(system(ErrorMsg), Goal, 0).
tmpnam_result(-2, _FileName0,FileName) :- % cannot happen
   Goal = tmpnam(FileName),
   prolog:illarg(system('internal error'), Goal, 0).
        

foreign(sp_mktemp,     c, c_mktemp(+string,-string,[-integer])).

foreign(sp_tmpnam,     c, c_tmpnam(-string,[-integer])).


%=========================================================================
% Predicates to run other programs

%-------------------------------------------------------------------------
% system/0-2
% Start a new shell process. The shell invoked by system/0-2 is:
%   on Unix, sh (the Bourne shell normally)
%   on DOS, Win32 or OS/2, the value of the env variable COMSPEC 

%   system
%   Starts a new interactive shell process. The control is returned to
%   Prolog upon termination of the shell process.

foreign(sp_system0, c, system).

%   system(+Command)
%   Passes Command to a new shell process for execution.  Succeeds if
%   the return status value is 0.

system(Command) :-
	system(Command, 0).

%   system(+Command, -Status)
%   Passes Command to a new shell process for execution.  The status
%   value is returned in Status.

foreign(sp_system2,     c, system(+string,[-integer])).

%-------------------------------------------------------------------------
% system/0-2
% Start a new shell process. The shell invoked by system/0-2 is
% determined by the environment variable SHELL. On DOS, Win32 or OS/2,
% the value of COMSPEC is used if SHELL is not defined.

%   shell
%   Starts a new interactive shell process. The control is returned to
%   Prolog upon termination of the shell process.

foreign(sp_shell0,     c, shell).

%   shell(+Command)
%   Passes Command to a new shell for execution.  Succeeds if the return
%   status value is 0.

shell(Command) :-
	shell(Command, 0).

%   shell(+Command, -Status)
%   Passes Command to a new shell for execution. The status value is
%   returned in Status.

foreign(sp_shell2,     c, shell(+string,[-integer])).

%-------------------------------------------------------------------------
%   exec(+Command,[+Stdin,+Stdout,+Stderr],-PID)
%   Passes Command to a new Bourne shell process for execution.  The standard
%   I/O streams of the new process are connected according to what is
%   specified by the terms Stdin, Stdout, and Stderr respectively.
%   Possible values are:
%   
%   null
%       Connected to /dev/null.
%   
%   std
%       The standard stream is shared with the calling process.
%   
%   pipe(Stream)
%       Stream must be unbound.
%       A pipe is created which connects the Prolog stream Stream to the
%       standard stream of the new process.
%
%   PID is the process ID of the child process.

exec(Command, List, PID) :-
	List = [Stdin,Stdout,Stderr],
	Goal = exec(Command, List, PID),
	exec_encode(Stdin, IC, Goal),
	exec_encode(Stdout, OC, Goal),
	exec_encode(Stderr, EC, Goal),
	c_exec(Command, IC, OC, EC, IS, OS, ES, PID, 0),
	exec_decode(Stdin, IS),
	exec_decode(Stdout, OS),
	exec_decode(Stderr, ES).

exec_decode(std, _).
exec_decode(null, _).
exec_decode(pipe(Stream), Code) :- stream_code(Stream, Code).

exec_encode(X, _, Goal) :- var(X), !,
	prolog:illarg(var, Goal, 1, X).
exec_encode(std, 0, _) :- !.
exec_encode(null, 1, _) :- !.
exec_encode(pipe(_), 2, _) :- !.
exec_encode(X, _, Goal) :-
	prolog:illarg(domain(term,one_of([null,std,pipe(_)])), Goal, 1, X).

foreign(sp_exec, c, c_exec(+string,
                           +integer, +integer, +integer,
                           -address('SP_stream'), -address('SP_stream'), -address('SP_stream'),
			   -integer, [-integer])).

%-------------------------------------------------------------------------
%   popen(+Command, +Mode, ?Stream)
%   Interface to the UNIX function popen(3).  Passes Command to a new UNIX
%   sh process for execution.  Mode may be either read or write.  In the
%   former case, the output from the process is piped to Stream.  In the
%   latter case, the input to the process is piped from Stream.  Stream
%   may be read/written using the ordinary Stream I/O predicates.  It must
%   be closed using close/1.

popen(Command, Mode, Stream) :-
	c_popen(Command, Mode, Code),
	stream_code(Stream, Code).

foreign(sp_popen,     c, c_popen(+string,+string,[-address('SP_stream')])).

%-------------------------------------------------------------------------
%   sleep(+Seconds)
%   Puts the SICStus Prolog process asleep for Second seconds.

foreign(sp_sleep,     c, sleep(+float)).

%-------------------------------------------------------------------------
%   pid(-PID)
%   PID is the identifier of the current SICStus Prolog process.

foreign(sp_getpid,     c, pid([-integer])).

%-------------------------------------------------------------------------
%   kill(+PID, +Signal)
%   Send the UNIX signal Signal to the process identified by PID.

foreign(sp_kill,     c, kill(+integer,+integer)).

%-------------------------------------------------------------------------
%   wait(+PID, -Status)
%   Waits for the child process identified by PID to terminate.  Its exit
%   status is returned in Status.  Interface to the UNIX function
%   waitpid(3).

foreign(sp_wait,     c, wait(+integer,[-integer])).

%-------------------------------------------------------------------------
%  sp_win32_times(-KernelTime, -UserTime, Res)
%  Res is 1 on succes.
%  KernelTime is a 64bit integer in 100ns units of process time spent in Kernel mode
%  UserTime ditto for user mode.
%  Only works on NT or later. Based on GetThreadTimes (Used to be based on GetProcessTimes)
%% foreign(sp_win32_times,     c, sp_win32_times(-integer,-integer,-integer,-integer,[-integer])).
foreign(sp_win32_times2,     c, sp_win32_times(-term,-term,[-integer])).


%-------------------------------------------------------------------------

%% [PM] 3.10.2 fixme error handling
signal(SignalName, Handler) :-
   format(user_error, 'system:signal/2 needs error handling', []), flush_output(user_error),
   atom(SignalName), !,
   sp_signal(SignalName, 0, Result),
   Result > 0,
   SignalNumber = Result,
   retractall(signal_handler(SignalNumber,_)),
   assert(signal_handler(SignalNumber, Handler)),
   true.


%% What SP_signal->SP_event handler will call 
handle_signal(SignalNumber) :-
   ( signal_handler(SignalNumber, Handler) ->
       once(Handler)
   ; true
   ).

   

foreign(sp_signal,     c, sp_signal(+string, +integer,[-integer])). % [PM] 3.10.2


%-------------------------------------------------------------------------

foreign_resource(system, [
	init(system_init),
	deinit(system_deinit),
	sp_time,
	sp_datime,
	sp_getenv1,
	sp_setenv,

        sp_environ,             % [PM] WinCE
	%% sp_argenv,

	sp_host_name,
	sp_host_id,
	sp_access,
	sp_rename,
	sp_del_file,
	sp_del_dir,
	sp_file_property,
	sp_directory_files,
	sp_make_dir,
	sp_mktemp,
	sp_tmpnam,
	sp_system0,
	sp_system2,
	sp_shell0,
	sp_shell2,
	sp_exec,
	sp_popen,
	sp_sleep,
	sp_getpid,
	sp_kill,
	sp_wait,
        sp_win32_times2,
        sp_signal
			 ]).

:- load_foreign_resource(library(system(system))).
