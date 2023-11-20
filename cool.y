  /*
  *  cool.y
  *              Parser definition for the COOL language.
  *
  */
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"

  extern char *curr_filename;


  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer for the location of tokens */
  
  extern int node_lineno;          /* set before constructing a tree node
                                      to whatever you want the line number
                                      for the tree node to be */
    
    
  #define YYLLOC_DEFAULT(Current, Rhs, N)         \
  Current = Rhs[1];                             \
  node_lineno = Current;
  
  
  #define SET_NODELOC(Current)  \
  node_lineno = Current;
  
  /* IMPORTANT NOTE ON LINE NUMBERS
  *********************************
  * The above definitions and macros cause every terminal in your grammar to 
  * have the line number supplied by the lexer. The only task you have to
  * implement for line numbers to work correctly, is to use SET_NODELOC()
  * before constructing any constructs from non-terminals in your grammar.
  * Example: Consider you are matching on the following very restrictive 
  * (fictional) construct that matches a plus between two integer constants. 
  * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
  
  plus_consts	: INT_CONST '+' INT_CONST 
  
  * where INT_CONST is a terminal for an integer constant. Now, a correct
  * action for this rule that attaches the correct line number to plus_const
  * would look like the following:
  
  plus_consts	: INT_CONST '+' INT_CONST 
  {
    // Set the line number of the current non-terminal:
    // ***********************************************
    // You can access the line numbers of the i'th item with @i, just
    // like you acess the value of the i'th exporession with $i.
    //
    // Here, we choose the line number of the last INT_CONST (@3) as the
    // line number of the resulting expression (@$). You are free to pick
    // any reasonable line as the line number of non-terminals. If you 
    // omit the statement @$=..., bison has default rules for deciding which 
    // line number to use. Check the manual for details if you are interested.
    @$ = @3;
    
    
    // Observe that we call SET_NODELOC(@3); this will set the global variable
    // node_lineno to @3. Since the constructor call "plus" uses the value of 
    // this global, the plus node will now have the correct line number.
    SET_NODELOC(@3);
    
    // construct the result node:
    $$ = plus(int_const($1), int_const($3));
  }

Classes nil_Classes();
Classes single_Classes(Class_);
Classes append_Classes(Classes, Classes);
Features nil_Features();
Features single_Features(Feature);
Features append_Features(Features, Features);
Formals nil_Formals();
Formals single_Formals(Formal);
Formals append_Formals(Formals, Formals);
Expressions nil_Expressions();
Expressions single_Expressions(Expression);
Expressions append_Expressions(Expressions, Expressions);
Cases nil_Cases();
Cases single_Cases(Case);
Cases append_Cases(Cases, Cases);
Program program(Classes);
Class_ class_(Symbol, Symbol, Features, Symbol);
Feature method(Symbol, Formals, Symbol, Expression);
Feature attr(Symbol, Symbol, Expression);
Formal formal(Symbol, Symbol);
Case branch(Symbol, Symbol, Expression);
Expression assign(Symbol, Expression);
Expression static_dispatch(Expression, Symbol, Symbol, Expressions);
Expression dispatch(Expression, Symbol, Expressions);
Expression cond(Expression, Expression, Expression);
Expression loop(Expression, Expression);
Expression typcase(Expression, Cases);
Expression block(Expressions);
Expression let(Symbol, Symbol, Expression, Expression);
Expression plus(Expression, Expression);
Expression sub(Expression, Expression);
Expression mul(Expression, Expression);
Expression divide(Expression, Expression);
Expression neg(Expression);
Expression lt(Expression, Expression);
Expression eq(Expression, Expression);
Expression leq(Expression, Expression);
Expression comp(Expression);
Expression int_const(Symbol);
Expression bool_const(Boolean);
Expression string_const(Symbol);
Expression new_(Symbol);
Expression isvoid(Expression);
Expression no_expr();
Expression object(Symbol);
  
  */
  
  
  
  void yyerror(char *s);        /*  defined below; called for each parse error */
  extern int yylex();           /*  the entry point to the lexer  */
  
  /************************************************************************/
  /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
  
  Program ast_root;	            /* the result of the parse  */
  Classes parse_results;        /* for use in semantic analysis */
  int omerrs = 0;               /* number of errors in lexing and parsing */
%}
    
    /* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
%type <program> program

%type <classes> class_list
%type <class_> class

%type <case_> case
%type <cases> case_list

%type <feature> feature
%type <features> feature_list_asterisk
%type <features> feature_list_plus

%type <expression> expr
%type <expressions> expr_list_asterisk
%type <expressions> expr_list_plus

%type <formal> formal
%type <formals> formal_list_asterisk
%type <formals> formal_list_plus

%type <expression> while_expression
%type <expression> inner_let
%type <expression> nonempty_expression

    
/* Precedence declarations go here. */

%left ISVOID
%left ASSIGN
%left NOT
%nonassoc LE '<' '='
%left '*' '/'
%left '+' '-'
%left '~'
%left '@'
%left '.'
    
%%
  ////// GRAMMAR RULES //////
  /* 
    Save the root of the abstract syntax tree in a global variable.
  */
program	: class_list 
          {  
            @$ = @1; ast_root = program($1); 
          };
  
class_list  : class 
              { 
                $$ = single_Classes($1); 
                parse_results = $$; 
              }
            | class_list class 
              { 
                $$ = append_Classes($1,single_Classes($2)); parse_results = $$; 
              };

  /* If no parent is specified, the class inherits from the Object class. */
class	: CLASS TYPEID '{' feature_list_asterisk '}' ';' 
        { 
          $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); 
        }
      | CLASS TYPEID INHERITS TYPEID '{' feature_list_asterisk '}' ';' 
        { 
          $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); 
        }
      | ERROR
        {

        };


feature_list_asterisk : feature_list_plus 
                        {
                          $$ = $1; 
                        }
                      | 
                        {
                          $$ = nil_Features();
                        };

feature_list_plus : feature ';' feature_list_plus
                    {
                      $$ = append_Features(single_Features($1), $3);
                    }
                  | feature 
                    {
                      $$ = single_Features($1);
                    };

feature : OBJECTID '(' formal_list_asterisk ')' ':' TYPEID '{' expr_list_asterisk '}'
          {
            $$ = method($1, $3, $6, $8);
          }
        | OBJECTID ':' TYPEID ASSIGN expr
          {
            $$ = attr($1, $3, $5);
          }
        | OBJECTID ':' TYPEID
          {
            $$ = attr($1, $3, no_expr());
          }
        | ERROR
          {
            
          };

formal_list_asterisk  : formal_list_plus
                        {

                        }
                      |
                        {

                        };

formal_list_plus  : formal ',' formal_list_plus
                    {

                    }
                  | formal 
                    {

                    };

formal  : OBJECTID ':' TYPEID
          {

          };

expr_list_asterisk  : expr_list_asterisk ',' nonempty_expression
                      {

                      }
                    | nonempty_expression 
                      {

                      }
                    | 
                      {

                      };

expr_list_plus  : nonempty_expression ';'
                  {

                  }
                | nonempty_expression ';' expr_list_plus
                  {

                  }
                | ERROR
                  {

                  };

expr  : nonempty_expression
        {

        }
      |
        {

        };

nonempty_expression : OBJECTID ASSIGN nonempty_expression
                      {

                      }
                    | nonempty_expression '@' TYPEID '.' OBJECTID '(' expr_list_asterisk ')' 
                      {

                      }
                    | nonempty_expression '.' OBJECTID '(' expr_list_asterisk ')'
                      {

                      }
                    | OBJECTID '(' expr_list_asterisk ')'
                      {

                      }
                    | IF nonempty_expression THEN nonempty_expression ELSE nonempty_expression FI
                      {

                      }
                    | while_expression
                      {

                      }
                    | '{' expr_list_plus '}'
                      {

                      }
                    | LET inner_let
                      {

                      }
                    | CASE nonempty_expression OF case_list ESAC
                      {

                      }
                    | NEW TYPEID
                      {

                      }
                    | ISVOID nonempty_expression
                      {

                      }
                    | nonempty_expression '+' nonempty_expression
                      {

                      }
                    | nonempty_expression '-' nonempty_expression
                      {

                      }
                    | nonempty_expression '*' nonempty_expression
                      {

                      }
                    | nonempty_expression '/' nonempty_expression
                      {

                      }
                    | nonempty_expression '<' nonempty_expression
                      {

                      }
                    | nonempty_expression '=' nonempty_expression
                      {

                      }
                    | nonempty_expression LE nonempty_expression
                      {

                      }
                    | '~' nonempty_expression
                      {

                      }
                    | NOT nonempty_expression
                      {

                      }
                    | '(' nonempty_expression ')'
                      {

                      }
                    | OBJECTID
                      {

                      }
                    | BOOL_CONST
                      {

                      }
                    | INT_CONST
                      {

                      }
                    | STR_CONST
                      {

                      }
                    | ERROR
                      {

                      };

while_expression  : WHILE nonempty_expression LOOP expr POOL
                    {

                    }
                  | WHILE nonempty_expression LOOP ERROR
                    {

                    };

case_list : case_list case ';'
            {

            }
          | case ';'
            {

            };

case  : OBJECTID ':' TYPEID DARROW expr
        {

        };

inner_let : OBJECTID ':' TYPEID ASSIGN expr IN expr
            {

            }
          | OBJECTID ':' TYPEID IN expr
            {

            }
          | OBJECTID ':' TYPEID ASSIGN expr ',' inner_let
            {

            }
          | OBJECTID ':' TYPEID ',' inner_let
            {

            };

/* end of grammar */
%%
    
/* This function is called automatically when Bison detects a parse error. */
void yyerror(char *s)
{
  extern int curr_lineno;
  
  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
  << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;
  
  if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
}
    
    
