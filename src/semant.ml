(* Semantic checking for the MicroC compiler *)

open Ast
open Sast
open Prettyast
open Prettysast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (globals, functions) =

  (* Verify a list of bindings has no void types or duplicate names *)
  let check_binds (kind : string) (binds : bind list) =
    List.iter (function
	(Void, b) -> raise (Failure ("illegal void " ^ kind ^ " " ^ b))
      | _ -> ()) binds;
    let rec dups = function
        [] -> ()
      |	((_,n1) :: (_,n2) :: _) when n1 = n2 ->
	  raise (Failure ("duplicate " ^ kind ^ " " ^ n1))
      | _ :: t -> dups t
    in dups (List.sort (fun (_,a) (_,b) -> compare a b) binds)
  in

  (**** Check global variables ****)

  check_binds "global" globals;

  (**** Check functions ****)

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_bind map (name, ty) = StringMap.add name {
      typ = Void;
      fname = name; 
      formals = [(ty, "x")];
      locals = []; body = [] } map
    in List.fold_left add_bind StringMap.empty [
      ("print", Int);
      ("printb", Bool);
      ("printf", Float);
      ("printString", Str);
      ("printNode", Node(Void));
      ("printEdge", Edge);
      ("printGraph", Graph(Void));
    ]
  in
  let built_in_decls = StringMap.add "setEdge" {
    typ = Edge;
    fname = "setEdge";
    formals = [(Graph(Void), "g"); (Node(Void), "from"); (Node(Void), "to"); (Float, "weight")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "setDirEdge" {
    typ = Edge;
    fname = "setDirEdge";
    formals = [(Graph(Void), "g"); (Node(Void), "from"); (Node(Void), "to"); (Float, "weight")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "getEdge" {
    typ = Edge;
    fname = "getEdge";
    formals = [(Graph(Void), "g"); (Node(Void), "from"); (Node(Void), "to")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "deleteEdge" {
    typ = Edge;
    fname = "deleteEdge";
    formals = [(Graph(Void), "g"); (Node(Void), "from"); (Node(Void), "to")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "updateEdge" {
    typ = Edge;
    fname = "updateEdge";
    formals = [(Graph(Void), "g"); (Node(Void), "from"); (Node(Void), "to"); (Float, "weight")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "append" {
    typ = Int;
    fname = "append";
    formals = [(List(Void), "array"); (Void, "data")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "pop" {
    typ = Int;
    fname = "pop";
    formals = [(List(Void), "array"); (Int, "index")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "neighbors" {
    typ = List(Node(Void));
    fname = "neighbors";
    formals = [(Graph(Void), "g"); (Node(Void), "n")];
    locals = [];
    body = [];
  } built_in_decls
  in
  let built_in_decls = StringMap.add "viz" {
    typ = Int;
    fname = "viz";
    formals = [(Graph(Void), "g"); (Str, "path")];
    locals = [];
    body = [];
  } built_in_decls
  in

  (* Add function name to symbol table *)
  let add_func map fd = 
    let built_in_err = "function " ^ fd.fname ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.fname
    and make_err er = raise (Failure er)
    and n = fd.fname (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
         _ when StringMap.mem n built_in_decls -> make_err built_in_err
       | _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n fd map 
  in

  (* Collect all function names into one symbol table *)
  let function_decls = List.fold_left add_func built_in_decls functions
  in
  
  (* Return a function from our symbol table *)
  let find_func s = 
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = find_func "main" in (* Ensure "main" is defined *)

  let check_function func =
    (* Make sure no formals or locals are void or duplicates *)
    check_binds "formal" func.formals;
    check_binds "local" func.locals;

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign lvaluet rvaluet err =
      match (lvaluet, rvaluet) with
        (* this allows us to cast a Node<int> to Node<void>, to support print_node *)
          (_, Void) -> lvaluet
        | (Void, _) -> rvaluet
        | (Node(_), Node(Void)) -> lvaluet
        | (Node(Void), Node(_)) -> rvaluet
        | (Graph(_), Graph(Void)) -> lvaluet
        | (Graph(Void), Graph(_)) -> rvaluet
        | (List(_), List(Void)) -> lvaluet
        | (List(Void), List(_)) -> rvaluet
        | (List(Node(_)), List(Node(Void))) -> lvaluet
        | (List(Node(Void)), List(Node(_))) -> rvaluet
        | _ -> if lvaluet = rvaluet
          then lvaluet
          else raise (Failure err)
    in   

    (* Build local symbol table of variables for this function *)
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
	                StringMap.empty (globals @ func.formals @ func.locals )
    in

    (* Return a variable from our local symbol table *)
    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* check that all the expressions in the list have the same type as the first one *)
    let check_all_types_same sexps err = match sexps with
        (typ, _) :: tail ->
          List.iter (fun (t, e) ->
            if t <> typ
            then raise (Failure (err)))
          tail; typ
      | [] -> Void
    in

    (* Return a semantically-checked expression, i.e., with a type *)
    let rec expr = function
        Literal  l -> (Int, SLiteral l)
      | Fliteral l -> (Float, SFliteral l)
      | BoolLit l  -> (Bool, SBoolLit l)
      | StrLit l   -> (Str, SStrLit l)
      | Noexpr     -> (Void, SNoexpr)
      | Id s       -> (type_of_identifier s, SId s)
      | ListLit(exps) as ex ->
        let sexps = (List.map (fun e -> expr e) exps) in
        let err = "expressions must all have the same type in " ^ string_of_expr ex in
        (List(check_all_types_same sexps err), SListLit(sexps))
      | NodeLit(exps) ->
        let sexps = match (List.length exps) with
            1 -> (List.map (fun e -> expr e) exps)
          | _ -> raise ( Failure ("illegal number of arguments for new node{val}. Must have exactly one argument"))
        in 
        let typ = (fst (List.hd sexps))
        in (Node(typ), SNodeLit(sexps))
      | GraphLit(exps) -> 
        let sexps = match (List.length exps) with
            0 -> (List.map (fun e -> expr e) exps)
          | _ -> raise ( Failure ("illegal number of arguments for new graph{}. Must have exactly zero arguments"))
        in (Graph(Void), SGraphLit(sexps))
      | Assign(var, e) as ex -> 
          let lt = type_of_identifier var
          and (rt, e') = expr e in
          let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
            string_of_typ rt ^ " in " ^ string_of_expr ex
          in (check_assign lt rt err, SAssign(var, (rt, e')))
      | Prop(e, prop) -> 
        let (etyp, _) as e' = expr e in
        let pt = match (etyp, prop) with
            (Node t, "val") -> t
          | (Node t, "id") -> Str
          | (Edge, "directed") -> Bool
          | (Edge, "weight") -> Float 
          | (Edge, "id") -> Str
          | (List t, "length") -> Int
          | (Graph t, "nodes") -> List(Node(t))
          | (Graph t, "edges") -> List(Edge)
          | (_, _) -> raise (Failure ("illegal property access"))
        in
        (pt, SProp (e', prop))
      | Unop(op, e) as ex -> 
          let (t, e') = expr e in
          let ty = match op with
            Neg when t = Int || t = Float -> t
          | Not when t = Bool -> Bool
          | _ -> raise (Failure ("illegal unary operator " ^ 
                                 string_of_uop op ^ string_of_typ t ^
                                 " in " ^ string_of_expr ex))
          in (ty, SUnop(op, (t, e')))
      | Binop(e1, op, e2) as e -> 
          let (t1, e1') = expr e1 
          and (t2, e2') = expr e2 in
          (* All binary operators require operands of the same type *)
          let same = t1 = t2 in
          (* Determine expression type based on operator and operand types *)
          let ty = match op with
            Add | Sub | Mult | Div when same && t1 = Int   -> Int
          | Add | Sub | Mult | Div when same && t1 = Float -> Float
          | Equal | Neq            when same               -> Bool
          | Less | Leq | Greater | Geq
                     when same && (t1 = Int || t1 = Float) -> Bool
          | And | Or when same && t1 = Bool -> Bool
          | Addnode | Delnode when 
            match (t1, t2) with
                (Node(subt1), Graph(subt2)) -> subt1 = subt1
              | _      -> false
            -> t1
          | _ -> raise (
	      Failure ("illegal binary operator " ^
                       string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                       string_of_typ t2 ^ " in " ^ string_of_expr e))
          in (ty, SBinop((t1, e1'), op, (t2, e2')))
      | Call(fname, args) as call -> 
          let fd = find_func fname in
          let param_length = List.length fd.formals in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          else let check_call (ft, _) e = 
            let (et, e') = expr e in 
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
            in (check_assign ft et err, e')
          in 
          let args' = List.map2 check_call fd.formals args
          in (fd.typ, SCall(fname, args'))
      | Index (name, ex) ->
          let (t, e) = expr ex in
          match t with
            Int -> (match (type_of_identifier name) with
              List(t') -> (t' , SIndex(name, (Int, e)))
              | _ -> raise ( Failure ("illegal type. expecting an array, found " ^ string_of_typ (type_of_identifier name))))
            | _ -> raise ( Failure ("illegal array index type. expecting Int, found " ^ string_of_typ t))
    in

    let check_bool_expr e = 
      let (t', e') = expr e
      and err = "expected Boolean expression in " ^ string_of_expr e
      in if t' != Bool then raise (Failure err) else (t', e') 
    in

    (* Return a semantically-checked statement i.e. containing sexprs *)
    let rec check_stmt = function
        Expr e -> SExpr (expr e)
      | If(p, b1, b2) -> SIf(check_bool_expr p, check_stmt b1, check_stmt b2)
      | For(e1, e2, e3, st) ->
	  SFor(expr e1, check_bool_expr e2, expr e3, check_stmt st)
      | While(p, s) -> SWhile(check_bool_expr p, check_stmt s)
      | Return e -> let (t, e') = expr e in
        if t = func.typ then SReturn (t, e') 
        else raise (
	  Failure ("return gives " ^ string_of_typ t ^ " expected " ^
		   string_of_typ func.typ ^ " in " ^ string_of_expr e))
	    
	    (* A block is correct if each statement is correct and nothing
	       follows any Return statement.  Nested blocks are flattened. *)
      | Block sl -> 
          let rec check_stmt_list = function
              [Return _ as s] -> [check_stmt s]
            | Return _ :: _   -> raise (Failure "nothing may follow a return")
            | Block sl :: ss  -> check_stmt_list (sl @ ss) (* Flatten blocks *)
            | s :: ss         -> check_stmt s :: check_stmt_list ss
            | []              -> []
          in SBlock(check_stmt_list sl)

    in (* body of check_function *)
    { styp = func.typ;
      sfname = func.fname;
      sformals = func.formals;
      slocals  = func.locals;
      sbody = match check_stmt (Block func.body) with
	SBlock(sl) -> sl
      | _ -> raise (Failure ("internal error: block didn't become a block?"))
    }
  in (globals, List.map check_function functions)