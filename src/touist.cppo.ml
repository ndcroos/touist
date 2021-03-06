open Parse
open Msgs

type error =
  | OK
  | UNKNOWN
  | CMD_USAGE
  | CMD_UNSUPPORTED
  | TOUIST_SYNTAX
  | TOUIST_TIMEOUT
  | TOUIST_MEMORY
  | TOUIST_UNKNOWN
  | SOLVER_UNSAT
  | SOLVER_UNKNOWN
  | SOLVER_TIMEOUT
  | SOLVER_MEMORY

let get_code (e : error) : int = match e with
  | OK              -> 0
  | UNKNOWN         -> 1
  | CMD_USAGE       -> 2
  | CMD_UNSUPPORTED -> 3
  | TOUIST_SYNTAX   -> 4
  | TOUIST_TIMEOUT  -> 5
  | TOUIST_MEMORY   -> 6
  | TOUIST_UNKNOWN  -> 7
  | SOLVER_UNSAT    -> 8
  | SOLVER_UNKNOWN  -> 9
  | SOLVER_TIMEOUT  -> 10
  | SOLVER_MEMORY   -> 11

type language = Sat | Smt | Qbf
let sat_flag = ref false
let qbf_flag = ref false
let smt_flag = ref ""
let mode = ref Sat
let version_asked = ref false
let input_file_path = ref "/dev/stdin"
let output_file_path = ref ""
let output_table_file_path = ref ""
let output_file_basename = ref ""
let use_stdin = ref false
let output = ref stdout
let output_table = ref stdout
let input = ref stdin
let solve_flag = ref false
let limit = ref 1
let only_count = ref false
let show_hidden_lits = ref false
let equiv_file_path = ref ""
let input_equiv = ref stdin
let linter = ref false (* for displaying syntax errors (during parse and eval) *)
let error_format = ref "%f: line %l, col %c-%C: %t: %m" (* display absolute position of error *)
let debug = ref false
let debug_syntax = ref false
let debug_cnf = ref false
let latex = ref false
let latex_full = ref false
let show = ref false
let wrap_width = ref 76

(* [process_arg_alone] is the function called by the command-line argument
   parser when it finds an argument with no preceeding -flag (-f, -x...).
   In our case, an argument not preceeded by a flag is the touistl input file. *)
let process_arg_alone (file_path:string) : unit = input_file_path := file_path

let exit_with (exit_code:error) = exit (get_code exit_code)

(* The main program *)
let () =
  let cmd = (FilePath.basename Sys.argv.(0)) in (* ./touistl exec. name *)
  let argspecs = [ (* This list enumerates the different flags (-x,-f...)*)
    (* "-flag", Arg.toSomething (ref var), "Usage for this flag"*)
    ("-o", Arg.Set_string (output_file_path), "OUTPUT is the translated file");
    ("--table", Arg.Set_string (output_table_file_path),
     "TABLE (--sat only) The output file that contains the literals table.
      By default, prints to stdout.");
    ("--sat", Arg.Set sat_flag,
        "Select the SAT solver (enabled by default when --smt or --qbf not selected)");
    ("--qbf", Arg.Set qbf_flag,
        "Select the QBF solver");
    ("--smt", Arg.Set_string (smt_flag), (
        "LOGIC Select the SMT solver with the specified LOGIC from the
        SMT2-LIB specification:
        QF_IDL allows to deal with boolean and integer, E.g, x - y < b
        QF_RDL is the same as QF_IDL but with reals
        QF_LIA (not documented)
        QF_LRA (not documented)
       See http://smtlib.cs.uiowa.edu/logics.shtml for more info."
      ));
    ("--version", Arg.Set version_asked, "Display version number");
    ("-", Arg.Set use_stdin,"reads from stdin instead of file");
    ("--debug", Arg.Set debug, "Print information for debugging touist");
    ("--debug-syntax", Arg.Set debug_syntax, "Print information for debugging
    syntax errors given by parser.messages");
    ("--debug-cnf", Arg.Set debug_cnf,"Print step by step CNF transformation");
    ("--show", Arg.Set show,"Show the expanded AST after evaluation (= expansion)");
    ("--solve", Arg.Set solve_flag,"Solve the problem and print the first model if it exists");
    ("--limit", Arg.Set_int limit,"(with --solve) Instead of one model, return N models if they exist.
                                            With 0, return every possible model.");
    ("--count", Arg.Set only_count,"(with --solve) Instead of displaying models, return the number of models");
    ("--latex", Arg.Set latex,"Transform to latex for simple processors (e.g., mathjax)");
    ("--latex-full", Arg.Set latex_full,"Transform to latex for full processors (e.g., pdflatex)");
    ("--show-hidden", Arg.Set show_hidden_lits,"(with --solve) Show the hidden '&a' literals used when translating to CNF");
    ("--equiv", Arg.Set_string equiv_file_path,"INPUT2 (with --solve) Check that INPUT2 has the same models as INPUT (equivalency)");
    ("--linter", Arg.Set linter,"Display syntax and semantic errors and exit");
    ("--error-format", Arg.Set_string error_format,"Customize the formatting of error messages");
    ("--wrap-width", Arg.Set_int wrap_width,"Wrapping width for error messages [default: 76]");
  ]
  in
  let usage =
    "TouIST solves propositional logic problems written in TouIST language\n"^
    "and supports conversion to SAT-DIMACS and SMT-LIB2 solver formats.\n"^
    "Usage: " ^ cmd ^ " [--sat] [-o OUTPUT] [--table TABLE] (INPUT | -)\n"^
    "Usage: " ^ cmd ^ " --smt (QF_IDL|QF_RDL|QF_LIA|QF_LRA) [-o OUTPUT] (INPUT | -)\n"^
    "Usage: " ^ cmd ^ " --qbf [-o OUTPUT] (INPUT | -)\n"^
    "Note: in --sat mode, if TABLE and OUTPUT aren't given, both output will be mixed in stdout."
  in
  (* Step 1: we parse the args. If an arg. is "alone", we suppose
   * it is the touistl input file (this is handled by [process_arg_alone]) *)
  Arg.parse argspecs process_arg_alone usage; (* parses the arguments *)
  if !debug then Printexc.record_backtrace true;
  Msgs.wrap_width := !wrap_width;
  Msgs.format := !error_format;
  Msgs.color := (Unix.isatty Unix.stderr);

  try

  (* Step 1.5: if we are asked the version number
   * NOTE: !version_asked means like in C, *version_asked.
   * It doesn't mean "not version_asked" *)
  if !version_asked then (
    print_endline ("Version: " ^ Version.version);
    if Version.has_git_tag then print_endline ("Git: "^Version.git_tag);
    let built_list = ["minisat"] @ (if Version.has_yices2 then ["yices2"] else [])
                                 @ (if Version.has_qbf then ["qbf"] else []) in
    print_endline ("Built with: " ^ List.fold_left (fun acc e -> match acc with "" -> e | _ -> acc^", "^e) "" built_list);
    exit_with OK
  );

  (* Step 2: we see if we got every parameter we need *)

  (* Check (file | -) and open input and output *)
  if (!input_file_path = "/dev/stdin") && not !use_stdin (* NOTE: !var is like *var in C *)
  then single_msg (Error,Usage,"you must give an input file (use - for reading from stdin).\n",None);

  if !use_stdin then input := stdin else input := open_in !input_file_path;

  let count = List.fold_left (fun acc v -> if v then acc+1 else acc) 0
  in
  if (count [!sat_flag; !smt_flag<>""; !qbf_flag]) > 1 then
    single_msg (Error,Usage,"only one of --sat, --smt or --qbf must be given.\n",None);

  (* Set the mode *)
  if      !sat_flag     then mode := Sat
  else if !smt_flag<>"" then mode := Smt
  else if !qbf_flag     then mode := Qbf
  else mode := Sat;


#ifdef yices2
  (* SMT Mode: check if one of the available QF_? has been given after --smt *)
  if (!mode = Smt) && not (Solvesmt.logic_supported !smt_flag) then
    single_msg (Error,Usage,"you must give a correct SMT-LIB \
    logic after --smt (try --help)\nExample: --smt QF_IDL\n",None);
#endif

  if !output_file_path <> ""
  then output := open_out !output_file_path;

  if !output_table_file_path <> "" && !mode = Sat
  then output_table := open_out !output_table_file_path;

  if !equiv_file_path <> ""
  then input_equiv := open_in !equiv_file_path;

  (* latex = parse and transform with latex_of_ast *)
  if !latex || !latex_full || !linter then begin
    let ast_plain =
      match !mode with
      | Sat -> Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
      | Smt -> Parse.parse_smt ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
      | Qbf -> Parse.parse_qbf ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
    in
    if !linter then let _ = ast_plain |> Eval.eval ~smt:(!mode = Smt) ~onlychecktypes:true
    in
    if !latex then Printf.fprintf !output "%s\n" (Latex.latex_of_ast ~full:false ast_plain);
    if !latex_full then
      Printf.fprintf !output "\\documentclass[fleqn]{article}\n\
      \\usepackage{mathtools}\n\
      \\allowdisplaybreaks\n\
      \\begin{document}\n\
      \\begin{multline*}\n\
      %s\n\
      \\end{multline*}\n\
      \\end{document}\n" (Latex.latex_of_ast ~full:true ast_plain);
    exit_with OK
  end;

  (* linter = only show syntax and semantic errors *)
  if !linter then begin
    let _ = match !mode with
    | Sat -> Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
      |> Eval.eval ~smt:(!mode = Smt) ~onlychecktypes:true
    | Smt -> Parse.parse_smt ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
      |> Eval.eval ~smt:(!mode = Smt) ~onlychecktypes:true
    | Qbf -> Parse.parse_qbf ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
      |> Eval.eval ~smt:(!mode = Smt) ~onlychecktypes:true
    in exit_with OK
  end;
  if !show then begin
    let ast = match !mode with
    | Sat -> Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
        |> Eval.eval ~smt:(!mode = Smt)
    | Smt -> Parse.parse_smt ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
        |> Eval.eval ~smt:(!mode = Smt)
    | Qbf -> Parse.parse_qbf ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
        |> Eval.eval ~smt:(!mode = Smt)
    in (Printf.fprintf !output "%s\n" (Pprint.string_of_ast ~utf8:true ast);
       exit_with OK)
    end;

  (* Step 3: translation *)
  if !mode = Sat then
    (* A. solve has been asked *)
    if !solve_flag then
      if !equiv_file_path <> "" then begin
        let solve input =
          let ast = Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan input) |> Eval.eval
          in let models = Cnf.ast_to_cnf ~debug:!debug_cnf ast |> Sat.cnf_to_clauses |> Sat.solve_clauses
          in models
        in
        let models = solve !input
        and models2 = solve !input_equiv
        in match Sat.ModelSet.equal !models !models2 with
        | true -> Printf.fprintf !output "Equivalent\n"; exit_with OK
        | false -> Printf.fprintf !output "Not equivalent\n"; exit_with SOLVER_UNSAT
      end
      else
        let ast = Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input) |> Eval.eval in
        let clauses,table = Cnf.ast_to_cnf ~debug:!debug_cnf ast |> Sat.cnf_to_clauses
        in
        let models =
          (if !only_count then Sat.solve_clauses (clauses,table)
           else
             let print_model model i =
               if !limit != 1
               then Printf.fprintf !output "==== model %d\n%s\n" i (Sat.Model.pprint ~sep:"\n" table model)
               else Printf.fprintf !output "%s\n" (Sat.Model.pprint ~sep:"\n" table model)
              in Sat.solve_clauses ~limit:!limit ~print:print_model (clauses,table))
        in
        match Sat.ModelSet.cardinal !models with
        | i when !only_count -> Printf.fprintf !output "%d\n" i; exit_with OK
        | 0 -> Printf.fprintf stderr "unsat\n"; exit_with SOLVER_UNSAT
        | 1 -> (* case where we already printed models in [solve_clause] *)
          exit_with OK
        | i -> (* case where we already printed models in [solve_clause] *)
          Printf.fprintf !output "==== found %d models, limit is %d (--limit N for more models)\n" i !limit; exit_with OK
    else
      (* B. solve not asked: print the Sat file *)
      let ast = Parse.parse_sat ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input) |> Eval.eval in
      let clauses,tbl = Cnf.ast_to_cnf ~debug:!debug_cnf ast |> Sat.cnf_to_clauses
      in
      (* tbl contains the literal-to-name correspondance table.
         The number of literals is (Hashtbl.length tbl) *)
      Sat.print_clauses_to_dimacs !output (Hashtbl.length tbl) clauses;
      Sat.print_table !output_table ~prefix:(if !output = !output_table then "c " else "") tbl;
      exit_with OK
        (* table_prefix allows to add the 'c' before each line of the table
           display, when and only when everything is outputed in a single
           file. Example:
              c 98 p(1,2,3)     -> c means 'comment' in any Sat file   *)

  else if !mode = Smt && not !solve_flag then begin
    let ast = Parse.parse_smt ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
        |> Eval.eval ~smt:(!mode = Smt) in
    let smt = Smt.to_smt2 !smt_flag ast in
    Buffer.output_buffer !output smt;
    exit_with OK
  end
  else if !mode = Smt && !solve_flag then begin
    #ifdef yices2
      let ast = Parse.parse_smt ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
          |> Eval.eval ~smt:(!mode = Smt) in
      let str = Solvesmt.ast_to_yices ast |> Solvesmt.model !smt_flag in
      if str = ""
      then (Printf.fprintf stderr "unsat\n"; exit_with SOLVER_UNSAT)
      else Printf.fprintf !output "%s\n" str;
      exit_with OK;
    #else
      Printf.fprintf stderr
        ("This touist binary has not been compiled with yices2 support.");
      exit_with CMD_UNSUPPORTED
    #endif
  end
  else if !mode = Qbf then begin
      let ast = Parse.parse_qbf ~debug:!debug_syntax ~filename:!input_file_path (string_of_chan !input)
        |> Eval.eval ~smt:(!mode = Smt) in
      let prenex = Qbf_of_ast.prenex ast in
      let cnf = Qbf_of_ast.cnf prenex in
      if !debug_cnf then begin
        Printf.fprintf stderr "formula: %s\n" (Pprint.string_of_ast ~utf8:true ast);
        Printf.fprintf stderr " prenex: %s\n" (Pprint.string_of_ast ~utf8:true prenex);
        Printf.fprintf stderr "    cnf: %s\n" (Pprint.string_of_ast ~utf8:true cnf)
      end;
      if not !solve_flag then begin
        Printf.fprintf stderr
        ("The QDIMACS export has not been implemented yet. But you can --solve!\n");
        exit_with CMD_UNSUPPORTED;
      end
      else (* --solve*)
    #ifdef qbf
      let qcnf,table = Solveqbf.qcnf_of_cnf cnf in
      match Solveqbf.solve ~hidden:!show_hidden_lits (qcnf,table) with
      | Some str -> Printf.fprintf !output "%s\n" str
      | None ->
        (Printf.fprintf stderr ("unsat\n");
        exit_with SOLVER_UNSAT);
    #else
      Printf.fprintf stderr
        ("This touist binary has not been compiled with qbf support.");
      exit_with CMD_UNSUPPORTED
    #endif
  end;

  (* I had to comment these close_out and close_in because it would
  raise 'bad descriptor file' for some reason. Because the program is always
  going to shut at this point, we can rely on the operating system for closing
  opened files.

  close_out !output;
  close_out !output_table;
  close_in !input;
  *)

  exit_with OK

  with
    | Fatal msg ->
      if !debug then Printf.eprintf "Stacktrace:\n%s\n" (Printexc.get_backtrace ());
      Printf.eprintf "%s\n" (Msgs.string_of_msg msg);
      exit_with (match msg with _,Usage,_,_ -> CMD_USAGE | _ -> TOUIST_SYNTAX)
    | Sys_error err ->
      Printf.eprintf "%s\n" (Msgs.string_of_msg (Error,Usage,err^"\n",None));
      exit_with CMD_USAGE
    | x -> raise x
