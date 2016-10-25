(*
 * eval.ml: semantic analysis of the abstract syntaxic tree produced by the parser.
 *          [eval] is the main function.
 *
 * Project TouIST, 2015. Easily formalize and solve real-world sized problems
 * using propositional logic and linear theory of reals with a nice language and GUI.
 *
 * https://github.com/touist/touist
 *
 * Copyright Institut de Recherche en Informatique de Toulouse, France
 * This program and the accompanying materials are made available
 * under the terms of the GNU Lesser General Public License (LGPL)
 * version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *)

open Syntax
open Pprint

exception Error of string

(* Return the list of integers between min and max
 * with an increment of step
 *)
let irange min max step =
  let rec loop acc cpt =
    if cpt = max+1 then
      acc
    else
      loop (cpt::acc) (cpt+1)
  in loop [] min |> List.rev

let frange min max step =
  let rec loop acc cpt =
    if cpt = max +. 1. then
      acc
    else
      loop (cpt::acc) (cpt+.1.)
  in loop [] min |> List.rev

let rec set_bin_op iop fop sop repr s1 s2 =
  match s1, s2 with
  | GenSet.Empty, GenSet.Empty -> GenSet.Empty
  | GenSet.ISet _, GenSet.Empty ->
      set_bin_op iop fop sop repr s1 (GenSet.ISet IntSet.empty)
  | GenSet.Empty, GenSet.ISet _ ->
      set_bin_op iop fop sop repr (GenSet.ISet IntSet.empty) s2
  | GenSet.Empty, GenSet.FSet _ ->
      set_bin_op iop fop sop repr (GenSet.FSet FloatSet.empty) s2
  | GenSet.FSet _, GenSet.Empty ->
      set_bin_op iop fop sop repr s1 (GenSet.FSet FloatSet.empty)
  | GenSet.Empty, GenSet.SSet _ ->
      set_bin_op iop fop sop repr (GenSet.SSet StringSet.empty) s2
  | GenSet.SSet _, GenSet.Empty ->
      set_bin_op iop fop sop repr s1 (GenSet.SSet StringSet.empty)
  | GenSet.ISet a, GenSet.ISet b -> GenSet.ISet (iop a b)
  | GenSet.FSet a, GenSet.FSet b -> GenSet.FSet (fop a b)
  | GenSet.SSet a, GenSet.SSet b -> GenSet.SSet (sop a b)
  | _,_ -> raise (Error ("unsupported set type(s) for '" ^ repr  ^ "'"))

let rec set_pred_op ipred fpred spred repr s1 s2 =
  match s1, s2 with
  | GenSet.Empty, GenSet.Empty -> true
  | GenSet.Empty, GenSet.ISet _ ->
      set_pred_op ipred fpred spred repr (GenSet.ISet IntSet.empty) s2
  | GenSet.ISet _, GenSet.Empty ->
      set_pred_op ipred fpred spred repr s1 (GenSet.ISet IntSet.empty)
  | GenSet.Empty, GenSet.FSet _ ->
      set_pred_op ipred fpred spred repr (GenSet.FSet FloatSet.empty) s2
  | GenSet.FSet _, GenSet.Empty ->
      set_pred_op ipred fpred spred repr s1 (GenSet.FSet FloatSet.empty)
  | GenSet.Empty, GenSet.SSet _ ->
      set_pred_op ipred fpred spred repr (GenSet.SSet StringSet.empty) s2
  | GenSet.SSet _, GenSet.Empty ->
      set_pred_op ipred fpred spred repr s1 (GenSet.SSet StringSet.empty)
  | GenSet.ISet a, GenSet.ISet b -> ipred a b
  | GenSet.FSet a, GenSet.FSet b -> fpred a b
  | GenSet.SSet a, GenSet.SSet b -> spred a b
  | _,_ -> raise (Error ("unsupported set type(s) for '" ^ repr ^ "'"))

let num_pred_op n1 n2 ipred fpred repr =
  match n1,n2 with
  | Int x, Int y     -> Bool (ipred x y)
  | Float x, Float y -> Bool (fpred x y)
  | _,_ -> raise (Error ("unsupported operand types for '" ^ repr ^ "'"))

let num_bin_op n1 n2 iop fop repr =
  match n1,n2 with
  | Int x, Int y     -> Int   (iop x y)
  | Float x, Float y -> Float (fop x y)
  | _,_ -> raise (Error ("unsupported operand types for '" ^ repr ^ "'"))

let bool_bin_op b1 b2 op repr =
  match b1,b2 with
  | Bool x, Bool y -> Bool (op x y)
  | _,_ -> raise (Error ("unsupported operand types for '" ^ repr ^ "'"))

let unwrap_int = function
  | Int x -> x
  | x -> raise (Error ("expected int, got " ^ (string_of_exp x)))

let unwrap_float = function
  | Float x -> x
  | x -> raise (Error ("expected float, got " ^ (string_of_exp x)))

let unwrap_str = function
  | Term (x,None)   -> x
  | Term (x,Some _) -> raise (Error ("unevaluated term: " ^ x))
  | x -> raise (Error ("expected term, got " ^ (string_of_exp x)))

(* Two structures are used to store the information on variables.

   [env] a simple list [(name,content),...] passed as recursive argument that
   stores int & floats. It allows 'local' variables (i.e., local to the block).
   It is used for bigand and bigor and let

   [extenv] is a global hashtable with (name, content)

*)
let extenv = Hashtbl.create 10

let rec eval exp env =
  eval_prog exp env

and eval_prog exp env =
  let rec loop = function
    | []    -> raise (Error ("no clauses"))
    | [x]   -> x
    | x::xs -> And (x, loop xs)
  in
  match exp with
  | Prog (None, clauses) -> eval_exp_no_expansion (loop clauses) env
  | Prog (Some decl, clauses) ->
      List.iter (fun x -> eval_affect x env) decl;
      eval_exp_no_expansion (loop clauses) env

and eval_affect exp env =
  match exp with
  | Affect (x,y) ->
      Hashtbl.replace extenv (expand_var_name x env) (eval_exp y env)

and eval_exp exp env =
  match exp with
  | Int x   -> Int x
  | Float x -> Float x
  | Bool x  -> Bool x
  | Var x ->
      let name = expand_var_name x env in
      begin
        try List.assoc name env
        with Not_found ->
          try Hashtbl.find extenv name
          with Not_found -> raise (Error ("variable '" ^ name ^"' has not been declared"))
      end
  | Set x -> Set x
  | Set_decl x -> eval_set x env
  | Neg x ->
      begin
        match eval_exp x env with
        | Int x'   -> Int   (- x')
        | Float x' -> Float (-. x')
        | _ -> raise (Error (string_of_exp exp))
      end
  | Add (x,y) -> num_bin_op (eval_exp x env) (eval_exp y env) (+) (+.) "+"
  | Sub (x,y) -> num_bin_op (eval_exp x env) (eval_exp y env) (-) (-.) "-"
  | Mul (x,y) -> num_bin_op (eval_exp x env) (eval_exp y env) ( * ) ( *. ) "*"
  | Div (x,y) -> num_bin_op (eval_exp x env) (eval_exp y env) (/) (/.) "/"
  | Mod (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Int x', Int y' -> Int (x' mod y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Sqrt x ->
      begin
        match eval_exp x env with
        | Float x' -> Float (sqrt x')
        | _ -> raise (Error (string_of_exp exp))
      end
  | To_int x ->
      begin
        match eval_exp x env with
        | Float x' -> Int (int_of_float x')
        | Int x'   -> Int x'
        | _ -> raise (Error (string_of_exp exp))
      end
  | To_float x ->
      begin
        match eval_exp x env with
        | Int x'   -> Float (float_of_int x')
        | Float x' -> Float x'
        | _ -> raise (Error (string_of_exp exp))
      end
  | Not x ->
      begin
        match eval_exp x env with
        | Bool x' -> Bool (not x')
        | _ -> raise (Error (string_of_exp exp))
      end
  | And (x,y) -> bool_bin_op (eval_exp x env) (eval_exp y env) (&&) "and"
  | Or (x,y) -> bool_bin_op (eval_exp x env) (eval_exp y env) (||) "or"
  | Xor (x,y) ->
      bool_bin_op (eval_exp x env)
                  (eval_exp y env)
                  (fun p q -> (p || q) && (not (p && q))) "xor"
  | Implies (x,y) ->
      bool_bin_op (eval_exp x env) (eval_exp y env) (fun p q -> not p || q) "=>"
  | Equiv (x,y) ->
      bool_bin_op (eval_exp x env)
                  (eval_exp y env)
                  (fun p q -> (not p || q) && (not q || p)) "<=>"
  | If (x,y,z) ->
      let test =
        match eval_exp x env with
        | Bool true  -> true
        | Bool false -> false
        | _ -> raise (Error (string_of_exp exp))
      in
      if test then eval_exp y env else eval_exp z env
  | Union (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Set x', Set y' ->
            Set (set_bin_op (IntSet.union)
                            (FloatSet.union)
                            (StringSet.union) "union" x' y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Inter (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Set x', Set y' ->
            Set (set_bin_op (IntSet.inter)
                            (FloatSet.inter)
                            (StringSet.inter) "inter" x' y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Diff (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Set x', Set y' ->
            Set (set_bin_op (IntSet.diff)
                            (FloatSet.diff)
                            (StringSet.diff) "diff" x' y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Range (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Int x', Int y'     -> Set (GenSet.ISet (IntSet.of_list (irange x' y' 1)))
        | Float x', Float y' -> Set (GenSet.FSet (FloatSet.of_list (frange x' y' 1.)))
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Empty x ->
      begin
        match eval_exp x env with
        | Set x' ->
            begin
              match x' with
              | GenSet.Empty    -> Bool true
              | GenSet.ISet x'' -> Bool (IntSet.is_empty x'')
              | GenSet.FSet x'' -> Bool (FloatSet.is_empty x'')
              | GenSet.SSet x'' -> Bool (StringSet.is_empty x'')
            end
        | _ -> raise (Error (string_of_exp exp))
      end
  | Card x ->
      begin
        match eval_exp x env with
        | Set x' ->
            begin
              match x' with
              | GenSet.Empty    -> Int 0
              | GenSet.ISet x'' -> Int (IntSet.cardinal x'')
              | GenSet.FSet x'' -> Int (FloatSet.cardinal x'')
              | GenSet.SSet x'' -> Int (StringSet.cardinal x'')
            end
        | _ -> raise (Error (string_of_exp exp))
      end
  | Subset (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Set x', Set y' ->
            Bool (set_pred_op (IntSet.subset)
                              (FloatSet.subset)
                              (StringSet.subset) "subset" x' y')
        | _ -> raise (Error (string_of_exp exp))
      end
  | In (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Int x', Set (GenSet.ISet y') -> Bool (IntSet.mem x' y')
        | Float x', Set (GenSet.FSet y') -> Bool (FloatSet.mem x' y')
        | Term (x',None), Set (GenSet.SSet y') -> Bool (StringSet.mem x' y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Equal (x,y) ->
      begin
        match eval_exp x env, eval_exp y env with
        | Int x', Int y' -> Bool (x' = y')
        | Float x', Float y' -> Bool (x' = y')
        | Term (x',None), Term (y',None) -> Bool (x' = y')
        | Set x', Set y' ->
            Bool (set_pred_op (IntSet.equal)
                              (FloatSet.equal)
                              (StringSet.equal) "=" x' y')
        | _,_ -> raise (Error (string_of_exp exp))
      end
  | Not_equal        (x,y) -> eval_exp (Not (Equal (x,y))) env
  | Lesser_than      (x,y) -> num_pred_op (eval_exp x env) (eval_exp y env) (<) (<) "<"
  | Lesser_or_equal  (x,y) -> num_pred_op (eval_exp x env) (eval_exp y env) (<=) (<=) "<="
  | Greater_than     (x,y) -> num_pred_op (eval_exp x env) (eval_exp y env) (>) (>) ">"
  | Greater_or_equal (x,y) -> num_pred_op (eval_exp x env) (eval_exp y env) (>=) (>=) ">="
  | e -> raise (Error ("this expression is not an 'evaluable' expression: " ^ string_of_exp e))

and eval_set set_decl env =
  let eval_form = List.map (fun x -> eval_exp x env) set_decl in
  match eval_form with
  | [] -> Set (GenSet.Empty)
  | (Int _)::xs ->
      Set (GenSet.ISet (IntSet.of_list (List.map unwrap_int eval_form)))
  | (Float _)::xs ->
      Set (GenSet.FSet (FloatSet.of_list (List.map unwrap_float eval_form)))
  | (Term (_,None))::xs ->
      Set (GenSet.SSet (StringSet.of_list (List.map unwrap_str eval_form)))
  | _ -> raise (Error ("set: " ^ (string_of_exp_list ", " eval_form)))

and eval_exp_no_expansion exp env =
  match exp with
  | Int x   -> Int x
  | Float x -> Float x
  | Neg x ->
      begin
        match eval_exp_no_expansion x env with
        | Int   x' -> Int   (- x')
        | Float x' -> Float (-. x')
        | x' -> Neg x'
        (*| _ -> raise (Error (string_of_exp exp))*)
      end
  | Add (x,y) ->
      begin
        match eval_exp_no_expansion x env, eval_exp_no_expansion y env with
        | Int x', Int y'     -> Int   (x' +  y')
        | Float x', Float y' -> Float (x' +. y')
        | Int _, Term _
        | Term _, Int _ -> Add (x,y)
        | x', y' -> Add (x', y')
        (*| _,_ -> raise (Error (string_of_exp exp))*)
      end
  | Sub (x,y) ->
      begin
        match eval_exp_no_expansion x env, eval_exp_no_expansion y env with
        | Int x', Int y'     -> Int   (x' -  y')
        | Float x', Float y' -> Float (x' -. y')
        (*| Term x', Term y' -> Sub (Term x', Term y')*)
        | x', y' -> Sub (x', y')
        (*| _,_ -> raise (Error (string_of_exp exp))*)
      end
  | Mul (x,y) ->
      begin
        match eval_exp_no_expansion x env, eval_exp_no_expansion y env with
        | Int x', Int y'     -> Int   (x' *  y')
        | Float x', Float y' -> Float (x' *. y')
        | x', y' -> Mul (x', y')
        (*| _,_ -> raise (Error (string_of_exp exp))*)
      end
  | Div (x,y) ->
      begin
        match eval_exp_no_expansion x env, eval_exp_no_expansion y env with
        | Int x', Int y'     -> Int   (x' /  y')
        | Float x', Float y' -> Float (x' /. y')
        | x', y' -> Div (x', y')
        (*| _,_ -> raise (Error (string_of_exp exp))*)
      end
  | Equal            (x,y) -> Equal            (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Not_equal        (x,y) -> Not_equal        (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Lesser_than      (x,y) -> Lesser_than      (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Lesser_or_equal  (x,y) -> Lesser_or_equal  (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Greater_than     (x,y) -> Greater_than     (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Greater_or_equal (x,y) -> Greater_or_equal (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Top    -> Top
  | Bottom -> Bottom
  | Term x -> Term ((expand_var_name x env), None)
  | Var x ->
      let name = expand_var_name x env in
      begin
        (* Check if this variable has been affected locally (recursive-wise)
           by bigand, bigor or let. *)
        try (match List.assoc name env with
             | Int x' -> Int x'
             | Float x' -> Float x'
             | _ -> raise (Error ("'" ^ name ^ "' has been declared locally (in bigand, bigor or let)\nLocally declared variables must be float or int")))
        with Not_found ->
        (* Check if this variable name has been affected globally by something *)
          try (match Hashtbl.find extenv name with
               | Int x' -> Int x'
               | Float x' -> Float x'
               | Set (_) -> raise (Error ("'" ^ name ^ " has been declared globally, meaning that it is\n
                                          expected to be a number. Instead, you gave a set."))
               | _ -> failwith ("'" ^ name ^ " has been declared globally, meaning that it is\n
                                expected to be a ."))
          with Not_found ->
            let (x',y') = x in
            try
              let term = match List.assoc x' env with
               | Int x'' -> Int x''
               | Float x'' -> Float x''
               | _ -> raise (Error "baz")
              in eval_exp_no_expansion (Term ((string_of_exp term),y')) env
            with Not_found -> raise (Error name)
      end
  | Not Top    -> Bottom
  | Not Bottom -> Top
  | Not x      -> Not (eval_exp_no_expansion x env)
  | And (Bottom, _) | And (_, Bottom) -> Bottom
  | And (Top,x)
  | And (x,Top) -> eval_exp_no_expansion x env
  | And     (x,y) -> And (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Or (Top, _) | Or (_, Top) -> Top
  | Or (Bottom,x)
  | Or (x,Bottom) -> eval_exp_no_expansion x env
  | Or      (x,y) -> Or  (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Xor     (x,y) -> Xor (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Implies (_,Top)
  | Implies (Bottom,_) -> Top
  | Implies (x,Bottom) -> eval_exp_no_expansion (Not x) env
  | Implies (Top,x) -> eval_exp_no_expansion x env
  | Implies (x,y) -> Implies (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Equiv   (x,y) -> Equiv (eval_exp_no_expansion x env, eval_exp_no_expansion y env)
  | Exact (x,y) ->
      begin
        match eval_exp y env with
        | Set (GenSet.SSet s) ->
            exact_str (StringSet.exact (unwrap_int (eval_exp x env)) s)
        | _ -> raise (Error (string_of_exp y))
      end
  | Atleast (x,y) ->
      begin
        match eval_exp y env with
        | Set (GenSet.SSet s) ->
            atleast_str (StringSet.atleast (unwrap_int (eval_exp x env)) s)
        | _ ->
            raise (Error (string_of_exp y))
      end
  | Atmost (x,y) ->
      begin
        match eval_exp y env with
        | Set (GenSet.SSet s) ->
            atmost_str (StringSet.atmost (unwrap_int (eval_exp x env)) s)
        | _ ->
            raise (Error (string_of_exp y))
      end
  | Bigand (v,s,t,e) ->
      let test =
        match t with
        | Some x -> x
        | None   -> Bool true
      in
      begin
        match v,s with
        | [],[] | _,[] | [],_ -> raise (Error (string_of_exp exp))
        | [x],[y] ->
            begin
              match eval_exp y env with
              | Set (GenSet.Empty)  -> bigand_empty env x [] test e
              | Set (GenSet.ISet a) -> bigand_int   env x (IntSet.elements a)    test e
              | Set (GenSet.FSet a) -> bigand_float env x (FloatSet.elements a)  test e
              | Set (GenSet.SSet a) -> bigand_str   env x (StringSet.elements a) test e
              | _ -> raise (Error (string_of_exp exp))
            end
        | x::xs,y::ys ->
            eval_exp_no_expansion (Bigand ([x],[y],None,(Bigand (xs,ys,t,e)))) env
      end
  | Bigor (v,s,t,e) ->
      let test =
        match t with
        | Some x -> x
        | None   -> Bool true
      in
      begin
        match v,s with
        | [],[] | _,[] | [],_ -> raise (Error (string_of_exp exp))
        | [x],[y] ->
            begin
              match eval_exp y env with
              | Set (GenSet.Empty)  -> bigor_empty env x [] test e
              | Set (GenSet.ISet a) -> bigor_int   env x (IntSet.elements a)    test e
              | Set (GenSet.FSet a) -> bigor_float env x (FloatSet.elements a)  test e
              | Set (GenSet.SSet a) -> bigor_str   env x (StringSet.elements a) test e
              | _ -> raise (Error (string_of_exp exp))
            end
        | x::xs,y::ys ->
            eval_exp_no_expansion (Bigor ([x],[y],None,(Bigor (xs,ys,t,e)))) env
      end
  | If (x,y,z) ->
      let test = eval_test x env in
      if test then eval_exp_no_expansion y env else eval_exp_no_expansion z env
  | Let (v,x,c) -> eval_exp_no_expansion c (((expand_var_name v env),x)::env)
  | e -> raise (Error ("this expression is not a formula: " ^ string_of_exp e))


and exact_str lst =
  let rec go = function
    | [],[]       -> Top
    | t::ts,[]    -> And (And (Term (t,None), Top), go (ts,[]))
    | [],f::fs    -> And (And (Top, Not (Term (f,None))), go ([],fs))
    | t::ts,f::fs -> And (And (Term (t,None), Not (Term (f,None))), go (ts,fs))
  in
  match lst with
  | []    -> Bottom
  | x::xs -> Or (go x, exact_str xs)

and atleast_str lst =
  List.fold_left (fun acc str -> Or (acc, clause_of_string_list str)) Bottom lst

and atmost_str lst =
  List.fold_left (fun acc str ->
    Or (acc, List.fold_left (fun acc' str' ->
      And (acc', Not (Term (str',None)))) Top str)) Bottom lst

and clause_of_string_list =
  List.fold_left (fun acc str -> And (acc, Term (str,None))) Top

and and_of_term_list =
  List.fold_left (fun acc t -> And (acc, t)) Top

and bigand_empty env var values test exp = Top
and bigand_int env var values test exp =
  let exp' = If (test,exp,Top) in
  match values with
  | []    -> Top
  | [x]   -> eval_exp_no_expansion exp' ((var, Int x)::env)
  | x::xs -> And (eval_exp_no_expansion exp' ((var, Int x)::env) ,bigand_int env var xs test exp)
and bigand_float env var values test exp =
  let exp' = If (test,exp,Top) in
  match values with
  | []    -> Top
  | [x]   -> eval_exp_no_expansion exp' ((var, Float x)::env)
  | x::xs -> And (eval_exp_no_expansion exp' ((var, Float x)::env) ,bigand_float env var xs test exp)
and bigand_str env var values test exp =
  let exp' = If (test,exp,Top) in
  match values with
  | []    -> Top
  | [x]   -> eval_exp_no_expansion exp' ((var, Term  (x,None))::env)
  | x::xs ->
      And (eval_exp_no_expansion exp' ((var, Term  (x,None))::env), bigand_str env var xs test exp)
and bigor_empty env var values test exp = Bottom
and bigor_int env var values test exp =
  let exp' = If (test,exp,Bottom) in
  match values with
  | []    -> Bottom
  | [x]   -> eval_exp_no_expansion exp' ((var, Int x)::env)
  | x::xs -> Or (eval_exp_no_expansion exp' ((var, Int x)::env), bigor_int env var xs test exp)
and bigor_float env var values test exp =
  let exp' = If (test,exp,Bottom) in
  match values with
  | []    -> Bottom
  | [x]   -> eval_exp_no_expansion exp' ((var, Float x)::env)
  | x::xs -> Or (eval_exp_no_expansion exp' ((var, Float x)::env), bigor_float env var xs test exp)
and bigor_str env var values test exp =
  let exp' = If (test,exp,Bottom) in
  match values with
  | []    -> Bottom
  | [x]   -> eval_exp_no_expansion exp' ((var, Term  (x,None))::env)
  | x::xs ->
      Or (eval_exp_no_expansion exp' ((var, Term (x,None))::env), bigor_str env var xs test exp)

and eval_test exp env =
  match eval_exp exp env with
  | Bool x -> x
  | _ -> raise (Error (string_of_exp exp))

and expand_var_name var env =
  match var with
  | (x,None)   -> x
  | (x,Some y) ->
       x ^ "("
         ^ (string_of_exp_list ", " (List.map (fun e -> eval_exp e env) y))
         ^ ")"
