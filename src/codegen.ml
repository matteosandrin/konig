(* Code generation *)

module L = Llvm
module A = Ast
open Sast

(* translate : Sast.program -> Llvm.module *)
module StringMap = Map.Make(String)

let translate (globals, functions) =
  let context = L.global_context () in
  let llmem = L.MemoryBuffer.of_file "konig.bc" in
  let llm = Llvm_bitreader.parse_bitcode context llmem in
  
  (* Create the LLVM compilation module into which
     we will generate code *)
  let the_module = L.create_module context "Konig" in

  (* Get types from the context *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context
  and float_t    = L.double_type context
  and void_t     = L.void_type   context 
  and arr_t      = L.pointer_type (match L.type_by_name llm "struct.Array" with
      None -> raise (Failure "the array type is not defined.")
    | Some x -> x)
  and str_t      = L.pointer_type (L.i8_type context)
  and node_t     = L.pointer_type (match L.type_by_name llm "struct.Node" with
      None -> raise (Failure "the node type is not defined.")
    | Some x -> x)
  and edge_t     = L.pointer_type (match L.type_by_name llm "struct.Edge" with
    None -> raise (Failure "the node type is not defined.")
  | Some x -> x)
  and graph_t    = L.pointer_type (match L.type_by_name llm "struct.Graph" with
      None -> raise (Failure "the graph type is not defined.")
    | Some x -> x)
  and void_ptr_t = L.pointer_type (L.i8_type context)
  in

  (* Return the LLVM type for a MicroC type *)
  let rec ltype_of_typ = function
      A.Int   -> i32_t
    | A.Bool  -> i1_t
    | A.Float -> float_t
    | A.Void  -> void_t
    | A.Char  -> i8_t
    | A.Edge  -> edge_t
    | A.List A.Char -> str_t
    | A.List typ  -> arr_t
    | A.Node typ  -> node_t
    | A.Graph -> graph_t
  in

  (* Create a map of global variables after creating each *)
  let global_vars : L.llvalue StringMap.t =
    let global_var m (t, n) = 
      let init = match t with
          A.Float -> L.const_float (ltype_of_typ t) 0.0
        | _ -> L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in

  (* print functions *)
  let printf_t : L.lltype = 
      L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue = 
      L.declare_function "printf" printf_t the_module in
  let print_node_t =
      L.function_type i32_t [| node_t |] in
  let print_node_f =
      L.declare_function "print_node" print_node_t the_module in
  let print_graph_t =
      L.function_type i32_t [| graph_t |] in
  let print_graph_f =
      L.declare_function "print_graph" print_graph_t the_module in

  (* list functions *)
  let init_array_t =
      L.function_type arr_t [||] in
  let init_array_f = 
      L.declare_function "init_array" init_array_t the_module in
  let append_array_t =
      L.function_type i32_t [| arr_t; void_ptr_t |] in
  let append_array_f = 
      L.declare_function "append_array" append_array_t the_module in
  let get_array_t =
      L.function_type void_ptr_t [| arr_t; i32_t |] in
  let get_array_f = 
      L.declare_function "get_array" get_array_t the_module in

  (* node functions *)
  let init_node_t =
      L.function_type node_t [| void_ptr_t |] in
  let init_node_f = 
      L.declare_function "init_node" init_node_t the_module in
  let add_node_t =
      L.function_type graph_t [| node_t; graph_t |] in
  let add_node_f = 
      L.declare_function "add_node" add_node_t the_module in
  let del_node_t =
      L.function_type graph_t [| node_t; graph_t |] in
  let del_node_f = 
      L.declare_function "del_node" del_node_t the_module in

  (* edge functions *)
  let set_edge_t =
      L.function_type edge_t [| graph_t; node_t; node_t; float_t |] in
  let set_edge_f =
      L.declare_function "set_edge" set_edge_t the_module in
  let set_dir_edge_t =
      L.function_type edge_t [| graph_t; node_t; node_t; float_t |] in
  let set_dir_edge_f =
      L.declare_function "set_dir_edge" set_dir_edge_t the_module in
  

  (* graph functions *)
  let init_graph_t = 
      L.function_type graph_t [||] in
  let init_graph_f =
      L.declare_function "init_graph" init_graph_t the_module in

  (* property getters *)
  let get_node_val_t =
      L.function_type void_ptr_t [| node_t |] in
  let get_node_val_f = 
      L.declare_function "get_node_val" get_node_val_t the_module in
  let get_edge_directed_t =
      L.function_type i1_t [| edge_t |] in
  let get_edge_directed_f = 
      L.declare_function "get_edge_directed" get_edge_directed_t the_module in
  let get_edge_weight_t =
      L.function_type float_t [| edge_t |] in
  let get_edge_weight_f = 
      L.declare_function "get_edge_weight" get_edge_weight_t the_module in

  (* Define each function (arguments and return type) so we can 
     call it even before we've created its body *)
  let function_decls : (L.llvalue * sfunc_decl) StringMap.t =
    let function_decl m fdecl =
      let name = fdecl.sfname
      and formal_types = 
	Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.sformals)
      in let ftype = L.function_type (ltype_of_typ fdecl.styp) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g\n" "fmt" builder in

    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
      let add_formal m (t, n) p = 
        L.set_value_name n p;
	let local = L.build_alloca (ltype_of_typ t) n builder in
        ignore (L.build_store p local builder);
	StringMap.add n local m 

      (* Allocate space for any locally declared variables and add the
       * resulting registers to our map *)
      and add_local m (t, n) =
	let local_var = L.build_alloca (ltype_of_typ t) n builder
	in StringMap.add n local_var m 
      in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.slocals 
    in

    (* Return the value for a variable or formal argument.
       Check local names first, then global names *)
    let lookup n = try StringMap.find n local_vars
                   with Not_found -> StringMap.find n global_vars
    in

    (* Construct code for an expression; return its value *)
    let rec expr builder ((gtyp, e) : sexpr) = match e with
	      SLiteral i  -> L.const_int i32_t i
      | SBoolLit b  -> L.const_int i1_t (if b then 1 else 0)
      | SFliteral l -> L.const_float_of_string float_t l
      | SStrLit s   -> L.build_global_stringptr s "str" builder
      | SNoexpr     -> L.const_int i32_t 0
      | SId s       -> L.build_load (lookup s) s builder
      | SListLit exps ->
        let arr = L.build_call init_array_f [||] "init_array" builder in
        let exps' = List.map (fun e -> expr builder e) exps in
        let typ = (fst (List.hd exps)) in
        let append e_val =
          let data = 
            let d = L.build_malloc (ltype_of_typ typ) "data" builder in
            ignore(L.build_store e_val d builder); d
          in
          let vdata = L.build_bitcast data void_ptr_t "vdata" builder in
          L.build_call append_array_f [| arr; vdata |] "append_array" builder
        in
        ignore(List.map (fun e -> append e) exps'); arr
      | SNodeLit exps ->
        let typ = (fst (List.hd exps)) in
        let data = 
          let e_val = expr builder (List.hd exps) in
          let d = L.build_malloc (ltype_of_typ typ) "data" builder in
          ignore(L.build_store e_val d builder); d
        in
        let vdata = L.build_bitcast data void_ptr_t "vdata" builder in
        (L.build_call init_node_f [| vdata |] "init_node" builder)
      | SGraphLit exps -> L.build_call init_graph_f [||] "init_node" builder
      | SAssign (s, e) -> let e' = expr builder e in
                          ignore(L.build_store e' (lookup s) builder); e'
      | SIndex (s, e) -> 
        let arr   = L.build_load (lookup s) s builder in
        let t     = ltype_of_typ gtyp in
        let idx   = expr builder e in
        let data  = L.build_call get_array_f [| arr; idx |] "get_array" builder in
        let vdata = L.build_bitcast data (L.pointer_type t) "vdata" builder in
        L.build_load vdata "vdata" builder
      | SProp (e, prop) -> 
        let cast_and_load ptr = (
          let typ = (L.pointer_type (ltype_of_typ gtyp)) in
          let data = L.build_bitcast ptr typ "data" builder in
          L.build_load data "data" builder)
        in
        let e' = (expr builder e) in (
        match (fst e, prop) with
          (Node(_), "val") -> 
            let vdata = L.build_call get_node_val_f [| e' |] "get_node_val" builder in
            cast_and_load vdata 
        | (Edge, "directed") ->
            L.build_call get_edge_directed_f [| e' |] "get_edge_directed" builder
        | (Edge, "weight") ->
            L.build_call get_edge_weight_f [| e' |] "get_edge_weight" builder
        | _ -> raise (Failure ("ERROR: internal error, semant should have rejected")))
      | SBinop ((A.Float,_ ) as e1, op, e2) ->
        let e1' = expr builder e1
        and e2' = expr builder e2 in
        (match op with 
          A.Add     -> L.build_fadd
        | A.Sub     -> L.build_fsub
        | A.Mult    -> L.build_fmul
        | A.Div     -> L.build_fdiv 
        | A.Equal   -> L.build_fcmp L.Fcmp.Oeq
        | A.Neq     -> L.build_fcmp L.Fcmp.One
        | A.Less    -> L.build_fcmp L.Fcmp.Olt
        | A.Leq     -> L.build_fcmp L.Fcmp.Ole
        | A.Greater -> L.build_fcmp L.Fcmp.Ogt
        | A.Geq     -> L.build_fcmp L.Fcmp.Oge
        | A.And | A.Or ->
            raise (Failure "internal error: semant should have rejected and/or on float")
        ) e1' e2' "tmp" builder
      | SBinop (e1, A.Addnode, e2) -> 
        let n = expr builder e1
        and g = expr builder e2 in
        L.build_call add_node_f [| n; g |] "add_node" builder
      | SBinop (e1, A.Delnode, e2) ->
        let n = expr builder e1
        and g = expr builder e2 in
        L.build_call del_node_f [| n; g |] "del_node" builder
      | SBinop (e1, op, e2) ->
        let e1' = expr builder e1
        and e2' = expr builder e2 in
        (match op with
          A.Add     -> L.build_add
        | A.Sub     -> L.build_sub
        | A.Mult    -> L.build_mul
        | A.Div     -> L.build_sdiv
        | A.And     -> L.build_and
        | A.Or      -> L.build_or
        | A.Equal   -> L.build_icmp L.Icmp.Eq
        | A.Neq     -> L.build_icmp L.Icmp.Ne
        | A.Less    -> L.build_icmp L.Icmp.Slt
        | A.Leq     -> L.build_icmp L.Icmp.Sle
        | A.Greater -> L.build_icmp L.Icmp.Sgt
        | A.Geq     -> L.build_icmp L.Icmp.Sge
        ) e1' e2' "tmp" builder
      | SUnop(op, ((t, _) as e)) ->
        let e' = expr builder e in
        (match op with
          A.Neg when t = A.Float -> L.build_fneg 
        | A.Neg                  -> L.build_neg
        | A.Not                  -> L.build_not) e' "tmp" builder
      (* print functions *)
      | SCall ("print", [e]) | SCall ("printb", [e]) ->
        L.build_call printf_func [| int_format_str ; (expr builder e) |]
          "printf" builder
      | SCall ("printf", [e]) -> 
        L.build_call printf_func [| float_format_str ; (expr builder e) |]
          "printf" builder
      | SCall ("printNode", [e]) ->
        L.build_call print_node_f [| (expr builder e) |] "print_node" builder
      | SCall ("printGraph", [e]) ->
        L.build_call print_graph_f [| (expr builder e) |] "print_graph" builder
      (* edge functions *)
      | SCall ("setEdge", [g; n1; n2; w]) ->
        let g'  = (expr builder g)
        and n1' = (expr builder n1)
        and n2' = (expr builder n2)
        and w' = (expr builder w)
        in
        L.build_call set_edge_f [| g'; n1'; n2'; w' |] "set_edge" builder
      | SCall ("setDirEdge", [g; n1; n2; w]) ->
        let g'  = (expr builder g)
        and n1' = (expr builder n1)
        and n2' = (expr builder n2)
        and w' = (expr builder w)
        in
        L.build_call set_dir_edge_f [| g'; n1'; n2'; w' |] "set_dir_edge" builder
      | SCall (f, args) ->
         let (fdef, fdecl) = StringMap.find f function_decls in
	 let llargs = List.rev (List.map (expr builder) (List.rev args)) in
	 let result = (match fdecl.styp with 
                        A.Void -> ""
                      | _ -> f ^ "_result") in
         L.build_call fdef (Array.of_list llargs) result builder
    in
    
    (* LLVM insists each basic block end with exactly one "terminator" 
       instruction that transfers control.  This function runs "instr builder"
       if the current block does not already have a terminator.  Used,
       e.g., to handle the "fall off the end of the function" case. *)
    let add_terminal builder instr =
      match L.block_terminator (L.insertion_block builder) with
	Some _ -> ()
      | None -> ignore (instr builder) in
	
    (* Build the code for the given statement; return the builder for
       the statement's successor (i.e., the next instruction will be built
       after the one generated by this call) *)

    let rec stmt builder = function
	SBlock sl -> List.fold_left stmt builder sl
      | SExpr e -> ignore(expr builder e); builder 
      | SReturn e -> ignore(match fdecl.styp with
                              (* Special "return nothing" instr *)
                              A.Void -> L.build_ret_void builder 
                              (* Build return statement *)
                            | _ -> L.build_ret (expr builder e) builder );
                     builder
      | SIf (predicate, then_stmt, else_stmt) ->
         let bool_val = expr builder predicate in
	 let merge_bb = L.append_block context "merge" the_function in
         let build_br_merge = L.build_br merge_bb in (* partial function *)

	 let then_bb = L.append_block context "then" the_function in
	 add_terminal (stmt (L.builder_at_end context then_bb) then_stmt)
	   build_br_merge;

	 let else_bb = L.append_block context "else" the_function in
	 add_terminal (stmt (L.builder_at_end context else_bb) else_stmt)
	   build_br_merge;

	 ignore(L.build_cond_br bool_val then_bb else_bb builder);
	 L.builder_at_end context merge_bb

      | SWhile (predicate, body) ->
	  let pred_bb = L.append_block context "while" the_function in
	  ignore(L.build_br pred_bb builder);

	  let body_bb = L.append_block context "while_body" the_function in
	  add_terminal (stmt (L.builder_at_end context body_bb) body)
	    (L.build_br pred_bb);

	  let pred_builder = L.builder_at_end context pred_bb in
	  let bool_val = expr pred_builder predicate in

	  let merge_bb = L.append_block context "merge" the_function in
	  ignore(L.build_cond_br bool_val body_bb merge_bb pred_builder);
	  L.builder_at_end context merge_bb

      (* Implement for loops as while loops *)
      | SFor (e1, e2, e3, body) -> stmt builder
	    ( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] )
    in

    (* Build the code for each statement in the function *)
    let builder = stmt builder (SBlock fdecl.sbody) in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.styp with
        A.Void -> L.build_ret_void
      | A.Float -> L.build_ret (L.const_float float_t 0.0)
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module
