open Printf

let say fmt = ksprintf (printf "%s\n%!") fmt

let default_dir () =
  Filename.get_temp_dir_name () ^ "/pglocal/"
let default_port = 4242

let pg_server () =
  let cmdf fmt =
    ksprintf (fun s ->
        let ret = Sys.command s in
        if ret = 0 then () else failwith (sprintf "command %S returned %d" s ret)
      ) fmt in
  let dir = 
    try Sys.getenv "POSTGRESQL_PATH" with _ -> default_dir () in
  let port =
    try Sys.getenv "POSTGRESQL_PORT" |> int_of_string with _ -> default_port in
  let start () =
    cmdf "rm -fr %s" dir;
    cmdf "mkdir -p %s" dir;
    cmdf "initdb -D %s" dir;
    cmdf "mkdir -p %s/var_run/" dir;
    cmdf "echo \"unix_socket_directories = '%s/var_run/'\" >> %s/postgresql.conf" dir dir;
    cmdf "PGPORT=%d pg_ctl start -l %s/log -D %s" port dir dir;
    say "Starting postgresql test server on port %d with %s" port dir;
  in
  let stop () = cmdf "PGPORT=%d pg_ctl -D %s -m fast stop" port dir in
  object
    method start = start ()
    method stop = stop ()
    method status = cmdf "PGPORT=%d pg_ctl -D %s status" port dir
    method port = port
    method conninfo = sprintf "postgresql:///template1?port=%d" port
  end

let usage () =
  say "usage: %s {start, stop, status, uri}" Sys.argv.(0);
  say "environment:";
  say "  POSTGRESQL_PORT: integer, default is %d" default_port;
  say "  POSTGRESQL_PATH: full-path, default is %s" (default_dir ());
  ()

let () =
  match Sys.argv.(1) with
  | "start" -> (pg_server ())#start
  | "status" -> (pg_server ())#status
  | "stop" -> (pg_server ())#stop
  | "uri" -> say "%s" (pg_server ())#conninfo
  | exception _ ->
    usage ();
    exit 1
  | other ->
    usage ();
    exit 1
