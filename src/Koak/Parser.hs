--
-- EPITECH PROJECT, 2022
-- koak
-- File description:
-- Koak.Parser
--

module Koak.Parser  ( parseKoak
                    , KDEFS(..)
                    , DEFS(..)
                    , PRECEDENCE(..)
                    , PROTOTYPE(..)
                    , PROTOTYPE_ARGS(..)
                    , PROTOTYPE_ID(..)
                    , TYPE(..)
                    , FOR(..)
                    , IF(..)
                    , WHILE(..)
                    , EXPRESSIONS(..)
                    , BIN_OP(..)
                    , BINARY_OP(..)
                    , EXPRESSION(..)
                    , UN_OP(..)
                    , UNARY(..)
                    , POSTFIX(..)
                    , CALL_EXPR(..)
                    , CALL_EXPR_ARGS(..)
                    , PRIMARY(..)
                    , IDENTIFIER(..)
                    , DOT
                    , DECIMAL_CONST(..)
                    , DOUBLE_CONST(..)
                    , LITERAL(..)
                    ) where

import Koak.Lexer as KL

data KDEFS          = KDEFS_DEFS DEFS
                    | KDEFS_EXPR EXPRESSIONS
    deriving (Eq, Show)

data DEFS           = DEFS PROTOTYPE EXPRESSIONS
    deriving (Eq, Show)

newtype PRECEDENCE  = PRECEDENCE Int
    deriving (Eq, Show)

data PROTOTYPE      = PROTOTYPE_UNARY  UN_OP  PRECEDENCE IDENTIFIER PROTOTYPE_ARGS
                    | PROTOTYPE_BINARY BIN_OP PRECEDENCE IDENTIFIER PROTOTYPE_ARGS
                    | PROTOTYPE IDENTIFIER PROTOTYPE_ARGS
    deriving (Eq, Show)

data PROTOTYPE_ARGS = PROTOTYPE_ARGS [PROTOTYPE_ID] TYPE
    deriving (Eq, Show)

data PROTOTYPE_ID   = PROTOTYPE_ID IDENTIFIER TYPE
    deriving (Eq, Show)

data TYPE           = INT
                    | DOUBLE
                    | VOID
    deriving (Eq, Show)

data FOR            = FOR IDENTIFIER EXPRESSION IDENTIFIER EXPRESSION EXPRESSION EXPRESSION
    deriving (Eq, Show)

data IF             = IF EXPRESSION EXPRESSIONS (Maybe EXPRESSIONS)
    deriving (Eq, Show)

data WHILE          = WHILE EXPRESSION EXPRESSIONS
    deriving (Eq, Show)

data EXPRESSIONS    = FOR_EXPR FOR
                    | IF_EXPR IF
                    | WHILE_EXPR WHILE
                    | EXPRESSIONS EXPRESSION [EXPRESSION]
    deriving (Eq, Show)

data BIN_OP         = BI_PLUS
                    | BI_MINUS
                    | BI_MULT
                    | BI_DIV
                    | BI_MOD
                    | BI_LT
                    | BI_LTE
                    | BI_GT
                    | BI_GTE
                    | BI_EQ
                    | BI_NEQ
                    | BI_ASSIGN
    deriving (Eq, Show)

data BINARY_OP      = BINARY_OP_UN BIN_OP UNARY
                    | BINARY_OP_EXPR BIN_OP EXPRESSION
    deriving (Eq, Show)

data EXPRESSION     = EXPRESSION UNARY [BINARY_OP]
    deriving (Eq, Show)

data UN_OP          = U_NOT
                    | U_NEG
                    | U_MINUS
                    | U_PLUS
    deriving (Eq, Show)

data UNARY          = UNARY_UN UN_OP UNARY
                    | UNARY_POSTFIX POSTFIX
    deriving (Eq, Show)

data POSTFIX        = POSTFIX PRIMARY (Maybe CALL_EXPR)
    deriving (Eq, Show)

newtype CALL_EXPR   = CALL_EXPR (Maybe CALL_EXPR_ARGS)
    deriving (Eq, Show)

data CALL_EXPR_ARGS = CALL_EXPR_ARGS EXPRESSION [EXPRESSION]
    deriving (Eq, Show)

data PRIMARY        = PRIMARY_IDENTIFIER IDENTIFIER
                    | PRIMARY_LITERAL LITERAL
                    | PRIMARY_EXPRS EXPRESSIONS
    deriving (Eq, Show)

newtype IDENTIFIER  = IDENTIFIER String
    deriving (Eq, Show)

data DOT

newtype DECIMAL_CONST = DECIMAL_CONST Int
    deriving (Eq, Show)

newtype DOUBLE_CONST  = DOUBLE_CONST Double
    deriving (Eq, Show)

data LITERAL          = LITERAL_DECIMAL DECIMAL_CONST
                      | LITERAL_DOUBLE DOUBLE_CONST
    deriving (Eq, Show)

parseKoak :: [Token] -> [KDEFS]
parseKoak [] = []
parseKoak tokens = let (kdefs, rest) = parseKdefs tokens in kdefs : parseKoak rest

parseKdefs :: [Token] -> (KDEFS, [Token])
parseKdefs []                  = error "parseKdefs: empty list"
parseKdefs ((Word "def"):xs)
    | (last xs)   == SemiColon = error "parseKdefs: expecting ';'"
    | otherwise                = let (def, rest)   = parseDefs xs          in (KDEFS_DEFS def, rest)
parseKdefs list
    | (last list) == SemiColon = error "parseKdefs: expecting ';'"
    | otherwise                = let (exprs, rest) = parseExpressions list in (KDEFS_EXPR exprs, rest)

parseDefs :: [Token] -> (DEFS, [Token])
parseDefs [] = error "parseDefs: empty list"
parseDefs tokens = let (proto, rest1) = parsePrototype tokens  in
                   let (exprs, rest2) = parseExpressions rest1 in
                   (DEFS proto exprs, rest2)


parsePrototype :: [Token] -> (PROTOTYPE, [Token])
parsePrototype []                   = error "parseDefs: empty list"
parsePrototype ((Word "unary"):xs)  = parsePrototypeUnary  xs
parsePrototype ((Word "binary"):xs) = parsePrototypeBinary xs
parsePrototype ((Word w):xs)        = parsePrototype'      xs

parsePrototypeUnary :: [Token] -> (PROTOTYPE, [Token])
parsePrototypeUnary [] = error "parsePrototypeUnary: empty list"
parsePrototypeUnary list =  let (unop,       rest1) = parseUnOp             list  in 
                            let (prec,       rest2) = parseMaybePrecedence  rest1 in 
                            let (id,         rest3) = parseIdentifier       rest2 in 
                            let (proto_args, rest4) = parsePrototypeArgs    rest3 in
                            parsePrototypeUnary' unop prec id proto_args rest4

parsePrototypeUnary' :: UN_OP -> Maybe PRECEDENCE -> IDENTIFIER -> PROTOTYPE_ARGS -> [Token] -> (PROTOTYPE, [Token])
parsePrototypeUnary' unop (Nothing)   id proto_args list = (PROTOTYPE_UNARY unop (getDefaultUnaryPrecedence unop) id proto_args, list)
parsePrototypeUnary' unop (Just prec) id proto_args list = (PROTOTYPE_UNARY unop prec id proto_args, list)

parsePrototypeBinary :: [Token] -> (PROTOTYPE, [Token])
parsePrototypeBinary [] = error "parsePrototypeUnary: empty list"
parsePrototypeBinary list = let (binop,      rest1) = parseBinOp            list  in 
                            let (prec,       rest2) = parseMaybePrecedence  rest1 in 
                            let (id,         rest3) = parseIdentifier       rest2 in 
                            let (proto_args, rest4) = parsePrototypeArgs    rest3 in
                            parsePrototypeBinary' binop prec id proto_args rest4

parsePrototypeBinary' :: BIN_OP -> Maybe PRECEDENCE -> IDENTIFIER -> PROTOTYPE_ARGS -> [Token] -> (PROTOTYPE, [Token])
parsePrototypeBinary' binop (Nothing)   id proto_args list = (PROTOTYPE_BINARY binop (getDefaultBinaryPrecedence binop) id proto_args, list)
parsePrototypeBinary' binop (Just prec) id proto_args list = (PROTOTYPE_BINARY binop prec id proto_args, list)

parsePrototype' :: [Token] -> (PROTOTYPE, [Token])
parsePrototype' [] = error "parsePrototypeBinary: empty list"
parsePrototype' list    = let (id,    rest1) = parseIdentifier    list  in
                          let (args,  rest2) = parsePrototypeArgs rest1 in
                          (PROTOTYPE id args, rest2)

parsePrototypeArgs :: [Token] -> (PROTOTYPE_ARGS, [Token])
parsePrototypeArgs []     = error "parsePrototypeArgs: empty list"
parsePrototypeArgs (x:xs) = let (p_list,      rest1) = parsePrototypeArgsList xs    in
                            let (return_type, rest2) = parsePrototypeArgsType rest1 in
                            parsePrototypeArgs' p_list return_type rest2

parsePrototypeArgs' :: [PROTOTYPE_ID] -> TYPE -> [Token] -> (PROTOTYPE_ARGS, [Token])
parsePrototypeArgs' p_list return_type (OpenParenthesis:ClosedParenthesis:xs) = (PROTOTYPE_ARGS p_list return_type, xs)
parsePrototypeArgs' _      _    (_:ClosedParenthesis:xs)                      = error "parsePrototypeArgs: missing '('"
parsePrototypeArgs' _      _    (OpenParenthesis:_:xs)                        = error "parsePrototypeArgs: missing ')'"
parsePrototypeArgs' _      _    _                                             = error "parsePrototypeArgs: missing '(' ')'"

parsePrototypeArgsList :: [Token] -> ([PROTOTYPE_ID], [Token])
parsePrototypeArgsList list = let (p_list, tokens) = parsePrototypeArgsList' list [] in (reverse p_list, tokens)

parsePrototypeArgsList' :: [Token] -> [PROTOTYPE_ID] -> ([PROTOTYPE_ID], [Token])
parsePrototypeArgsList' list@(Word _:_) p_list = let (proto_id, rest) = parsePrototypeId list in parsePrototypeArgsList' rest (proto_id:p_list)
parsePrototypeArgsList' list            p_list = (p_list, list)

parsePrototypeArgsType :: [Token] -> (TYPE, [Token])
parsePrototypeArgsType []         = error "parsePrototypeArgs: empty list"
parsePrototypeArgsType (Colon:xs) = parseType xs

parsePrecedence :: [Token] -> (PRECEDENCE, [Token])
parsePrecedence list = parsePrecedence' $ parseMaybePrecedence list

parsePrecedence' :: (Maybe PRECEDENCE, [Token]) -> (PRECEDENCE, [Token])
parsePrecedence' (Nothing,   list) = error "parsePrecedence: precedence is missing"
parsePrecedence' (Just p,    list) = (p, list)

parseMaybePrecedence :: [Token] -> (Maybe PRECEDENCE, [Token])
parseMaybePrecedence (Number n:xs)   = (Just $ PRECEDENCE $ round n, xs)
parseMaybePrecedence (_:list)        = (Nothing,                     list)

parsePrototypeId :: [Token] -> (PROTOTYPE_ID, [Token])
parsePrototypeId [] = error "parsePrototypeId: empty list"
parsePrototypeId _ = error "Not Implemented"

parseType :: [Token] -> (TYPE, [Token])
parseType []                 = error "parseType: empty list"
parseType (Word "int":xs)    = (INT, xs)
parseType (Word "double":xs) = (DOUBLE, xs)
parseType (Word "void":xs)   = (VOID, xs)
parseType _                  = error "parseType: Invalid Token"

parseFor :: [Token] -> (FOR, [Token])
parseFor [] = error "parseFor: empty list"
parseFor _ = error "Not Implemented"

parseIf :: [Token] -> (IF, [Token])
parseIf [] = error "parseIf: empty list"
parseIf _ = error "Not Implemented"

parseWhile :: [Token] -> (WHILE, [Token])
parseWhile [] = error "parseWhile: empty list"
parseWhile _ = error "Not Implemented"

parseExpressions :: [Token] -> (EXPRESSIONS, [Token])
parseExpressions [] = error "parseExpressions: empty list"
parseExpressions _ = error "Not Implemented"

parseBinOp :: [Token] -> (BIN_OP, [Token])
parseBinOp [] = error "parseBinOp: empty list"
parseBinOp _ = error "Not Implemented"

parseBinaryOp :: [Token] -> (BINARY_OP, [Token])
parseBinaryOp [] = error "parseBinaryOp: empty list"
parseBinaryOp _ = error "Not Implemented"

parseExpression :: [Token] -> (EXPRESSION, [Token])
parseExpression [] = error "parseExpression: empty list"
parseExpression _ = error "Not Implemented"

parseUnOp :: [Token] -> (UN_OP, [Token])
parseUnOp [] = error "parseUnOp: empty list"
parseUnOp _ = error "Not Implemented"

parseUnary :: [Token] -> (UNARY, [Token])
parseUnary [] = error "parseUnary: empty list"
parseUnary _ = error "Not Implemented"

parsePostfix :: [Token] -> (POSTFIX, [Token])
parsePostfix [] = error "parsePostfix: empty list"
parsePostfix _ = error "Not Implemented"

parseCallExpr :: [Token] -> (CALL_EXPR, [Token])
parseCallExpr [] = error "parseCallExpr: empty list"
parseCallExpr _ = error "Not Implemented"

parseCallExprArgs :: [Token] -> (CALL_EXPR_ARGS, [Token])
parseCallExprArgs [] = error "parseCallExprArgs: empty list"
parseCallExprArgs _ = error "Not Implemented"

parsePrimary :: [Token] -> (PRIMARY, [Token])
parsePrimary [] = error "parsePrimary: empty list"
parsePrimary _ = error "Not Implemented"

parseIdentifier :: [Token] -> (IDENTIFIER, [Token])
parseIdentifier [] = error "parseIdentifier: empty list"
parseIdentifier ((Word w):xs) = (IDENTIFIER w, xs)
parseIdentifier _  = error "parseIdentifier: expecting ';'"

isValidIdentifier :: [Token] -> Bool
isValidIdentifier ((Word w):xs) = True
isValidIdentifier _             = False

parseDot :: [Token] -> (DOT, [Token])
parseDot [] = error "parseDot: empty list"
parseDot _ = error "Not Implemented"

parseDecimalConst :: [Token] -> (DECIMAL_CONST, [Token])
parseDecimalConst [] = error "parseDecimalConst: empty list"
parseDecimalConst _ = error "Not Implemented"

parseDoubleConst :: [Token] -> (DOUBLE_CONST, [Token])
parseDoubleConst [] = error "parseDoubleConst: empty list"
parseDoubleConst _ = error "Not Implemented"

parseLitteral :: [Token] -> (LITERAL, [Token])
parseLitteral [] = error "parseLitteral: empty list"
parseLitteral _ = error "Not Implemented"


-- parseExpressions :: [Token] -> (EXPRESSIONS, [Token])
-- parseExpressions _ = error "parseExpressions: empty list"
-- parseExpressions list@(x:xs)
--     | x == Word "for"   = let (for, rest)   = parseFor xs in (FOR_EXPR for, rest)
--     | x == Word "if"    = let (if_, rest)   = parseIf xs in (IF_EXPR if_, rest)
--     | x == Word "while" = let (while, rest) = parseWhile xs in (WHILE_EXPR while, rest)
--     | otherwise = let (expr, rest) = parseExpression list in (EXPRESSIONS expr [], rest)

isBinaryOp :: Token -> Bool
isBinaryOp KL.Plus          = True
isBinaryOp KL.Minus         = True
isBinaryOp KL.Multiply      = True
isBinaryOp KL.Divide        = True
isBinaryOp KL.Modulo        = True
isBinaryOp KL.Lower         = True
isBinaryOp KL.LowerEqual    = True
isBinaryOp KL.Greater       = True
isBinaryOp KL.GreaterEqual  = True
isBinaryOp KL.Equal         = True
isBinaryOp KL.NotEqual      = True
isBinaryOp KL.Assign        = True
isBinaryOp _                = False

isUnaryOp :: Token -> Bool
isUnaryOp KL.Plus       = True
isUnaryOp KL.Minus      = True
isUnaryOp KL.LogicalNot = True
isUnaryOp _             = False

getDefaultUnaryPrecedence :: UN_OP -> PRECEDENCE
getDefaultUnaryPrecedence U_PLUS    = PRECEDENCE 0
getDefaultUnaryPrecedence U_MINUS   = PRECEDENCE 0
getDefaultUnaryPrecedence U_NOT     = PRECEDENCE 0
getDefaultUnaryPrecedence U_NEG     = PRECEDENCE 0

getDefaultBinaryPrecedence :: BIN_OP -> PRECEDENCE
getDefaultBinaryPrecedence BI_PLUS     = PRECEDENCE 0
getDefaultBinaryPrecedence BI_MINUS    = PRECEDENCE 0
getDefaultBinaryPrecedence BI_MULT     = PRECEDENCE 0
getDefaultBinaryPrecedence BI_DIV      = PRECEDENCE 0
getDefaultBinaryPrecedence BI_MOD      = PRECEDENCE 0
getDefaultBinaryPrecedence BI_LT       = PRECEDENCE 0
getDefaultBinaryPrecedence BI_LTE      = PRECEDENCE 0
getDefaultBinaryPrecedence BI_GT       = PRECEDENCE 0
getDefaultBinaryPrecedence BI_GTE      = PRECEDENCE 0
getDefaultBinaryPrecedence BI_EQ       = PRECEDENCE 0
getDefaultBinaryPrecedence BI_NEQ      = PRECEDENCE 0
getDefaultBinaryPrecedence BI_ASSIGN   = PRECEDENCE 0