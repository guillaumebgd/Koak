--
-- EPITECH PROJECT, 2022
-- KOAK
-- File description:
-- Main
--
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}

module Main where

import System.Environment                         ( getArgs )
import System.Exit                                ( ExitCode(ExitFailure)
                                                  , exitWith
                                                  , exitSuccess
                                                  )
import Control.Exception                          ( Handler(..)
                                                  , catches
                                                  , throw
                                                  )

import qualified Argument.Parser.Exception as APE ( KoakArgumentParserException( KoakHelpException ) )
import qualified Koak.Lexer.Exception      as KLE ( KoakLexerException(..) )
import qualified Koak.Parser.Exception     as KPE ( KoakParserException(..) )
import qualified Koak.Typing.Exception     as KTE ( KoakTypingException(..) )
import qualified Koak.Evaluator.Exception  as KEE ( KoakEvaluatorException(..) )

import qualified Argument.Parser           as AP  ( KoakArguments(..)
                                                  , Filepath(..)
                                                  , parseArguments
                                                  )
import qualified Koak.Parser               as KP
import qualified Koak.Typing               as KT
import qualified Koak.TypingContext        as KTC
import qualified Koak.Evaluator            as KE
import qualified Koak.EvaluatorContext     as KEC

main :: IO ()
main = (getArgs >>= handleExecution . AP.parseArguments) `catches` [ Handler exceptionHandlerAPE
                                                                   , Handler exceptionHandlerKLE
                                                                   , Handler exceptionHandlerKPE
                                                                   , Handler exceptionHandlerKTE
                                                                   , Handler exceptionHandlerKEE
                                                                   ]

handleExecution :: AP.KoakArguments -> IO ()
handleExecution (AP.KoakArguments (AP.Filepath file)) = readFile file >>= launchExecution

launchExecution :: String -> IO ()
launchExecution file = launchExecution' $ KP.parseKoak file

launchExecution' :: KP.Stmt -> IO ()
launchExecution' stmt = launchExecution'' stmt $ KT.checkKoakTyping stmt KTC.getDefaultKContext

launchExecution'' :: KP.Stmt -> Either KTE.KoakTypingException KTC.Kcontext -> IO ()
launchExecution'' _    (Left value) = throw value
launchExecution'' stmt (Right _)    = launchExecution''' $ KE.evaluateKoak $ KP.getKdefsFromStmt stmt

launchExecution''' :: KE.KoakEvaluation -> IO ()
launchExecution''' (KE.KoakEvaluation (x:_) _) = print x

exceptionHandlerAPE :: APE.KoakArgumentParserException -> IO ()
exceptionHandlerAPE APE.KoakHelpException = print APE.KoakHelpException >> exitSuccess
exceptionHandlerAPE exception             = print exception             >> exitWith (ExitFailure 84)

exceptionHandlerKLE :: KLE.KoakLexerException -> IO ()
exceptionHandlerKLE exception             = print exception             >> exitWith (ExitFailure 84)

exceptionHandlerKPE :: KPE.KoakParserException -> IO ()
exceptionHandlerKPE exception             = print exception             >> exitWith (ExitFailure 84)

exceptionHandlerKTE :: KTE.KoakTypingException -> IO ()
exceptionHandlerKTE exception             = print exception             >> exitWith (ExitFailure 84)

exceptionHandlerKEE :: KEE.KoakEvaluatorException -> IO ()
exceptionHandlerKEE exception             = print exception             >> exitWith (ExitFailure 84)
