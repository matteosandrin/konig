/* Ocamlyacc parser for Konig */

%{
open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE LSQUARE RSQUARE COMMA DOT PLUS MINUS TIMES DIVIDE ASSIGN
%token ADDNODE DELNODE
%token NOT EQ NEQ LT LEQ GT GEQ AND OR DOT
%token KO NEW RETURN IF ELSE FOR WHILE INT BOOL FLOAT CHAR LIST NODE EDGE GRAPH VOID
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token <string> STRLIT
%token EOF

%start program
%type <Ast.program> program

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left DOT
%left EQ NEQ
%left LT GT LEQ GEQ
%left ADDNODE DELNODE
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { ([], [])               }
 | decls vdecl { (($2 :: fst $1), snd $1) }
 | decls fdecl { (fst $1, ($2 :: snd $1)) }

fdecl:
   KO typ ID LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
     { { typ = $2;
	 fname = $3;
	 formals = List.rev $5;
	 locals = List.rev $8;
	 body = List.rev $9 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1,$2)]     }
  | formal_list COMMA typ ID { ($3,$4) :: $1 }

typ:
    INT   { Int   }
  | BOOL  { Bool  }
  | FLOAT { Float }
  | CHAR  { Char }
  | EDGE  { Edge }
  | GRAPH { Graph }
  | VOID  { Void  }
  | LIST LT typ GT { List($3) }
  | NODE LT typ GT { Node($3) }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   typ ID SEMI { ($1, $2) }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI                               { Expr $1               }
  | RETURN expr_opt SEMI                    { Return $2             }
  | LBRACE stmt_list RBRACE                 { Block(List.rev $2)    }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7)        }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
                                            { For($3, $5, $7, $9)   }
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)         }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

// expr_id:
//     ID               { Id($1)                 }
  // | expr_id DOT expr_id   { Binop($1, Access, $3)  } // TODO: implement dot notation

expr:
    LITERAL          { Literal($1)            }
  | FLIT             { Fliteral($1)           }
  | BLIT             { BoolLit($1)            }
  | STRLIT           { StrLit($1)             }
  | ID               { Id($1)                 }
  | expr PLUS   expr { Binop($1, Add,   $3)   }
  | expr MINUS  expr { Binop($1, Sub,   $3)   }
  | expr TIMES  expr { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr { Binop($1, Div,   $3)   }
  | expr EQ     expr { Binop($1, Equal, $3)   }
  | expr NEQ    expr { Binop($1, Neq,   $3)   }
  | expr LT     expr { Binop($1, Less,  $3)   }
  | expr LEQ    expr { Binop($1, Leq,   $3)   }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3)   }
  | expr AND    expr { Binop($1, And,   $3)   }
  | expr OR     expr { Binop($1, Or,    $3)   } 
  | expr DOT    expr  { Prop($1, $3)  } // (Dot notation)
  | expr ADDNODE expr { Binop($1, Addnode, $3) } // (add node)
  | expr DELNODE expr { Binop($1, Delnode, $3) } // (delete node)
  | MINUS expr %prec NOT { Unop(Neg, $2)      }
  | NOT expr         { Unop(Not, $2)          }
  | ID ASSIGN expr   { Assign($1, $3)         }
  | ID LPAREN args_opt RPAREN { Call($1, $3)  }
  | LPAREN expr RPAREN { $2                   }
  | ID LSQUARE expr RSQUARE { Index($1, $3) } // (list indexing)
  | LSQUARE args_opt RSQUARE { ListLit($2) } // (list literal)
  | NEW NODE LBRACE args_opt RBRACE { NodeLit($4) } // (node literal)
  | NEW GRAPH LBRACE args_opt RBRACE { GraphLit($4)  } // (graph literal)

args_opt:
    /* nothing */ { [] }
  | args_list  { List.rev $1 }

args_list:
    expr                    { [$1] }
  | args_list COMMA expr { $3 :: $1 }
