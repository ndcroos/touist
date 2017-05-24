(** Defition of the menhir incremental parser (using --table --inspection) *)

(* Project TouIST, 2015. Easily formalize and solve real_world sized problems
 * using propal logic and linear theory of reals with a nice language and GUI.
 *
 * https://github.com/touist/touist
 *
 * Copyright Institut de Recherche en Informatique de Toulouse, France
 * This program and the accompanying materials are made available
 * under the terms of the GNU Lesser General Public License (LGPL)
 * version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html *)

%{
  open Types.Ast
%}

%token <int> INT
%token <float> FLOAT
%token <bool> BOOL
%token <string> VAR
%token <string> TERM
%token <string> TUPLE
%token <string> VARTUPLE
%token ADD SUB MUL DIV MOD SQRT TOINT TOFLOAT ABS
%token AND OR XOR IMPLIES EQUIV NOT
%token EQUAL NOTEQUAL LE LT GE GT
%token IN WHEN
%token UNION INTER DIFF SUBSET RANGE POWERSET
%token EMPTY CARD
%token LBRACK RBRACK
%token LPAREN RPAREN
%token COMMA COLON AFFECT
%token IF THEN ELSE END
%token EXACT ATLEAST ATMOST
%token TOP BOTTOM
%token BIGAND BIGOR
%token DATA
%token LET
%token EOF
%token FORALL EXISTS


(* The following lines define in which order the tokens should
 * be reduced, e.g. it tells the parser to reduce * before +.
 *
 * Note that the precedence rules apply from bottom to top:
 * the top element will be the less prioritized
 *
 * %left: e.g: a PLUS b TIMES -> a PLUS b
 *   The precedence rule applies from left to right,
 *
 * %right:
 *   The precedence rule applies from right to left
 *
 * %noassoc, e.g. NOT(a)
 *   The precedence rule has no direction; this often
 *   applies for unary oparators *)

%nonassoc affect_before_exprsmt
%nonassoc low_precedence (* Lesser priority on precedence *)
%right EQUIV IMPLIES
%left OR
%left AND
%left XOR
(*%left LE GE LT GT EQUAL NOTEQUAL*)
%left NOT
%nonassoc EQUAL NOTEQUAL LT LE GT GE IN
(* neg_prec = preced. of 'SUB x' has a lesser preced. than 'x SUB x' *)
(* sub_prec = predecence of 'x SUB x' *)
%left ADD SUB sub_prec neg_prec
%left MUL DIV
%left MOD (* Highest priority on precedence *)

(* This wierd [high_precedence] is not a TERMINAL, not a
 * production rule... It is an arbitrary name that allows
 * to give precedence indications on production rules.
 * Ex:
 *     formula: SUB formula %prec high_precedence
 * will give this production rule a predecence given by
 * where the
 *     %nonassoc high_precedence
 * is written. Here, we want this production rule to be
 * reduced before any other one because it is the "minus" sign,
 * ex:
 *     -3.905
 * and, like
 *     not(a)
 * the minus sign MUST be reduced as fast as possible. *)

%on_error_reduce comma_list(expr)
%on_error_reduce comma_list(expr_smt)

%on_error_reduce comma_list(indices)

%on_error_reduce comma_list(var)

(* %on_error_reduce is a nice "trick" to display a a more accurate
   context when an error is handled. For example, with this text:

       "begin formula formula a(b,c end formula"

   - b is shifted and then reduced thanks to the lookahead ","
   - c is shifted and then reduced thanks to the lookahead "end"
   - end is now evaluated; the parser is still fullfilling the rule
        separated_nonempty_list(COMMA,term_or_exp)                (1)
        -> term_or_exp . COMMA | term_or_exp . RPAREN
     At this moment, the term_or_exp is the "c"; as END does not match
     RPAREN or COMMA, the rule (1) fails to be reduceable.

   The problem is that the $0 token in parser.messages will be
     $0 = end
     $1 = c
     $2 = ,    etc...
   because we were trying to reduce "b (RPAREN | COMMA)".
   There is no way to display the "a" which was the actuall important
   information because we don't actually know on which $i it is.

   %on_error_reduce will actually tell the parser not to fail immediately
   and let the "caller rule" that was calling (1). Here, (1) was called
   twice recursively. The failing rule will hence be

     TERM LPAREN separated_nonempty_list(COMMA,term_or_exp) . RPAREN (2)

   Hence we are sure that $1 will give b,c and $3 will give "a" !
*)

(* The two entry points of our parser *)
%start <Types.Ast.ast> touist_simple, touist_smt, touist_qbf

%% (* Everthing below that mark is expected to be a production rule *)
   (* Note that VAR { $0 } is equivalent to v=VAR { v } *)

comma_list(T):
  | x=T { x::[] }
  | x=T COMMA l=comma_list(T) { x::l }

(* A touistl code is a blank-separated list of either formulas or 
   global variable affectations. Global affectations can only occur
   in this 'top' list ('top' because it is at the top of the ast tree). *)
affect_or(T):
  | a=global_affect {a}  %prec affect_before_exprsmt
  | f=T option(DATA) {f} (* DATA is now useless but stays for compatibilty *)

(* [touist_simple] is the entry point of the parser in sat mode *)
touist_simple:
  | f=affect_or(formula_simple)+ EOF {Loc (Touist_code (f),($startpos,$endpos))}


(* [touist_smt] is the entry point of the parser in smt mode *)
touist_smt:
  | f=affect_or(formula_smt)+ EOF {Loc (Touist_code (f),($startpos,$endpos))}

touist_qbf: f=affect_or(formula_qbf)+ EOF {Loc (Touist_code (f),($startpos,$endpos))}

(* Used in tuple expression; see tuple_variable and tuple_term *)
%inline indices: i=expr { i }

(* a tuple_term is of the form abc(1,d,3): the indices can be *)
prop:
  | t=TERM {Loc (Prop t,($startpos,$endpos))} (* simple_term *)
  | t=TUPLE (*LPAREN*) l=comma_list(indices) RPAREN (* tuple_term *)
    {Loc (UnexpProp (t, Some l),($startpos,$endpos))}

(* For now, we don't check the type of the variables during the parsing.
   This means that all variables are untyped during parsing.
   The start and end positions of the current rule are $startpos and $endpos.
   These two placeholders can only be used in a semantic action, not in the
   %{ %} header. *)
var:
  | v=VAR {Loc (Var (v,None),($startpos,$endpos))}
  | v=VARTUPLE (*LPAREN*) l=comma_list(indices) RPAREN (* tuple_variable *)
    {Loc (Var (v,Some l),($startpos,$endpos))}

(* a global variable is a variable used in the 'data' block
  for defining sets and constants; it can be of the form of a
  tuple_variable, i.e. with prefix+indices: '$i(1,a,d)'.
  The indices can be either expression or term *)
%inline global_affect: v=var AFFECT e=expr {Loc (Affect (v,e),($startpos,$endpos))}

%inline if_statement(T): IF cond=expr THEN v1=T ELSE v2=T END {Loc (If (cond,v1,v2),($startpos,$endpos))}

%inline in_parenthesis(T): LPAREN x=T RPAREN {Loc (Paren x,($startpos,$endpos))}

%inline num_operations_standard(T):
  | x=T    ADD     y=T  {Loc (Add (x,y),($startpos,$endpos))}
  | x=T    SUB     y=T  {Loc (Sub (x,y),($startpos,$endpos))} %prec sub_prec
  |        SUB     x=T  {Loc (Neg x,($startpos,$endpos))     } %prec neg_prec
  | x=T    MUL     y=T  {Loc (Mul (x,y),($startpos,$endpos))}
  | x=T    DIV     y=T  {Loc (Div (x,y),($startpos,$endpos))}

%inline num_operations_others(T):
  | x=T    MOD     y=T  {Loc (Mod (x,y),($startpos,$endpos))}
  | ABS (*LPAREN*) x=T RPAREN {Loc (Abs x,($startpos,$endpos))}

%inline int: x=INT {Loc (Int x,($startpos,$endpos))}
%inline float: x=FLOAT {Loc (Float x,($startpos,$endpos))}
%inline bool: x=BOOL {Loc (Bool x,($startpos,$endpos))}

expr:
  | b=var {b}
  | x=int {x}
  | TOINT (*LPAREN*) x=expr RPAREN {Loc (To_int x,($startpos,$endpos))}
  | CARD  (*LPAREN*) s=expr RPAREN {Loc (Card s,($startpos,$endpos))}
  | x=float {x}
  | x=in_parenthesis(expr)
  | x=num_operations_standard(expr)
  | x=num_operations_others(expr)
  | x=if_statement(expr) { x }
  | SQRT    (*LPAREN*) x=expr RPAREN {Loc (Sqrt x,($startpos,$endpos))}
  | TOFLOAT (*LPAREN*) x=expr RPAREN {Loc (To_float x,($startpos,$endpos))}
  | b=bool {b}
  | b=connectors(expr)
  | b=equality(expr)
  | b=order(expr) {b}
  | EMPTY  (*LPAREN*) s=expr RPAREN {Loc (Empty s,($startpos,$endpos))}
  | SUBSET (*LPAREN*) s1=expr   COMMA s2=expr   RPAREN {Loc (Subset (s1,s2),($startpos,$endpos))}
  | p=prop {p}
  | x=expr   IN s=expr {Loc (In (x,s),($startpos,$endpos))}
  | x=set_decl_range(expr)
  | x=set_empty
  | x=set_decl_explicit(expr)
  | x=set_operation(expr) {x}

%inline equality(T):
  | x=T  EQUAL    y=T   {Loc (Equal (x,y),($startpos,$endpos)) }
  | x=T  NOTEQUAL y=T   {Loc (Not_equal (x,y),($startpos,$endpos)) }

%inline order(T):
  | x=T   LT      y=T   {Loc (Lesser_than (x,y),($startpos,$endpos)) }
  | x=T   LE      y=T   {Loc (Lesser_or_equal (x,y),($startpos,$endpos)) }
  | x=T   GT      y=T   {Loc (Greater_than (x,y),($startpos,$endpos)) }
  | x=T   GE      y=T   {Loc (Greater_or_equal (x,y),($startpos,$endpos)) }

%inline connectors(T):
  | NOT           x=T   {Loc (Not x,($startpos,$endpos))}
  | x=T  AND      y=T   {Loc (And (x,y),($startpos,$endpos)) }
  | x=T  OR       y=T   {Loc (Or (x,y),($startpos,$endpos)) }
  | x=T  XOR      y=T   {Loc (Xor (x,y),($startpos,$endpos)) }
  | x=T  IMPLIES  y=T   {Loc (Implies (x,y),($startpos,$endpos)) }
  | x=T  EQUIV    y=T   {Loc (Equiv (x,y),($startpos,$endpos)) }

%inline set_decl_range(T): LBRACK s1=T RANGE s2=T RBRACK {Loc (Range (s1,s2),($startpos,$endpos))}
%inline set_decl_explicit(T): LBRACK l=comma_list(T) RBRACK {Loc (Set_decl l,($startpos,$endpos))}
%inline set_empty: LBRACK RBRACK {Loc (Set_decl [],($startpos,$endpos))}
  
%inline set_operation(T):
  | UNION (*LPAREN*) s1=T COMMA s2=T RPAREN {Loc (Union (s1,s2),($startpos,$endpos))}
  | INTER (*LPAREN*) s1=T COMMA s2=T RPAREN {Loc (Inter (s1,s2),($startpos,$endpos))}
  | DIFF  (*LPAREN*) s1=T COMMA s2=T RPAREN {Loc (Diff (s1,s2),($startpos,$endpos))}
  | POWERSET (*LPAREN*) s=T RPAREN {Loc (Powerset s,($startpos,$endpos))}

%inline formula(F):
  | f=in_parenthesis(F)
  | f=if_statement(F)
  | f=connectors(F)
  | f=generalized_connectors(F) (* are only on formulas! No need for parametrization *)
  | f=let_affect(expr,F) {f}

let_affect(T,F): LET var=var AFFECT content=T COLON form=F 
  {Loc (Let (var,content,form),($startpos,$endpos))} %prec low_precedence

formula_simple:
  | f=var {f}
  | f=formula(formula_simple)
  | f=prop {f}
  | TOP { Top }
  | BOTTOM { Bottom }

formula_qbf:
  | f=var {f}
  | f=formula(formula_qbf)
  | f=prop {f}
  | TOP { Top }
  | BOTTOM { Bottom }
  | f=exists(formula_qbf)
  | f=forall(formula_qbf) {f}

formula_smt:
  | f=formula(formula_smt)
  | f=expr_smt { f }

(* WARNING: SMT can handle things like '(x + 2) > 3.1', meaning that the
   types are mixed. *)
expr_smt:
  | f=prop {f}
  | TOP { Top }
  | BOTTOM { Bottom }
  | x=var {x}
  | x=int
  | x=float
  | x=order(expr_smt)
  | x=num_operations_standard(expr_smt)
  | x=equality(expr_smt) {x}
  | x=in_parenthesis(expr_smt) {x}

%inline generalized_connectors(F):
  | BIGAND v=comma_list(var) IN s=comma_list(expr) c=when_cond? COLON f=F END 
    {Loc (Bigand (v,s,c,f),($startpos,$endpos))}
  | BIGOR  v=comma_list(var) IN s=comma_list(expr) c=when_cond? COLON f=F END 
    {Loc (Bigor (v,s,c,f),($startpos,$endpos))}
  | EXACT (*LPAREN*)   x=expr COMMA s=expr RPAREN {Loc (Exact (x,s),($startpos,$endpos))}
  | ATLEAST (*LPAREN*) x=expr COMMA s=expr RPAREN {Loc (Atleast (x,s),($startpos,$endpos))}
  | ATMOST (*LPAREN*)  x=expr COMMA s=expr RPAREN {Loc (Atmost (x,s),($startpos,$endpos))}

%inline when_cond: WHEN x=expr { x }

%inline prop_or_var: p=prop | p=var {p}

%inline exists(F): EXISTS v=comma_list(prop_or_var) COLON form=F { List.fold_right (fun v acc -> Loc (Exists (v,acc),($startpos,$endpos))) v form }
%inline forall(F): FORALL v=comma_list(prop_or_var) COLON form=F { List.fold_right (fun v acc -> Loc (Forall (v,acc),($startpos,$endpos))) v form }