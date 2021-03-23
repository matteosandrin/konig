(* Abstract Syntax Tree *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or |
          Addnode | Delnode
type uop = Neg | Not

type typ = Int | Bool | Float | Void |
           Char | Edge | Graph |
           list | node

(* The type definitions for "list" and "node" contain other types (i.e. list<int>) *)
type list = List * typ
type node = Node * typ