# Emacs Parser Generator

[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://travis-ci.org/cjohansson/emacs-parser-generator.svg?branch=master)](https://travis-ci.org/cjohansson/emacs-parser-generator)

The idea of this plugin is to provide functions for various kinds of context-free grammar parser generations with support for syntax-directed-translations (SDT) and semantic-actions. This project is about implementing algorithms described in the book `The Theory of Parsing, Translation and Compiling (Volume 1)` by `Alfred V. Aho and Jeffrey D. Ullman` (1972). Also this project is about me learning how to parse languages.

This is just started, so most stuff are *WIP*.

## Lexical Analysis

We use a regular-language based lexical analyzer that can be implemented by a finite-state-machine (FSM). Read more [here](docs/Lexical-Analysis.md).

## Syntax Analysis / Parsing

We use push down transducer (PDT) based algorithms.

### With Backtracking

* The Bottom-Up Parsing Algorithm *WIP*
* The Top-Down Parsing Algorithm *WIP*
* The Cocke-Younger-Kasami Algorithm *WIP*
* The Parsing Method of Earley *WIP*

### Without Backtracking

* LL(k) *WIP*
* Deterministic Shift-Reduce Parsing *WIP*
* [LR(k)](docs/Deterministic-Right-Parser-for-LRk-Grammars.md)
* Formal Shift-Reduce Parsing Algorithms *WIP*
* Simple Precedence Grammars *WIP*
* Extended Precedence Grammars *WIP*
*Weak Precedence Grammars *WIP*
* Bounded-Right-Context Grammars *WIP*
* Mixed Strategy Precedence Grammars *WIP*
* Operator Precedence Grammars *WIP*
* Floyd-Evans Production Language *WIP*

## Grammar

Grammar consists of `N`, `T`, `P` and `S`, where `N` is non-terminals, `T` is terminals, `P` is productions and `S` is start-production. Example:

* N = `'(S A B C)`
* T = `'(a b c)`
* P = `'((S (A B)) (A (B a) e) (B (C b) C) (C c e))`
* S = `'S`

``` emacs-lisp
(parser-generator--set-grammar '((S A B C) (a b c) ((S (A B)) (A (B a) e) (B (C b) C) (C c e)) S))
```

### e

The symbol defined in variable `parser-generator--e-identifier`, with default-value: 'e`, symbolizes the e symbol. The symbol is allowed in some grammars and not in others.

### Non-terminals

A non-terminal is either a symbol or a string so `"A"` and `A` are equally valid.

### Terminals

A terminal is either a symbol or a string so `"{"` and `A` are equally valid.

### Sentential-form

A list of one or more non-terminals and terminals, example `'(A "A" c ":")`, the e-symbol is allowed depending on grammar.

### Productions

A production consists of a list of at least two elements. The first element is the left-hand-side (LHS) and should contain at least one element. The right-hand-side (RHS) consists of the rest of the elements, if there is more than one list in RHS then each list will be treated as a alternative production RHS.

Example, production `S -> A | B` is defined as:

``` emacs-lisp
'(S A B)
```

Another example, production `S -> IF "{" EXPRESSION "}" | EXIT` is declared as:

``` emacs-lisp
'(S (IF "{" EXPRESSION "}") EXIT)
```

### Start

The start symbol is the entry-point of the grammar and should be either a string or a symbol and should exists in the list of productions as the LHS.

### Look-ahead number

Is a simple integer above zero. You set it like this: `(parser-generator--set-look-ahead-number 1)` for `1` number look-ahead.

### Syntax-directed-translation (SDT)

*WIP* Where should this be defined?

### Semantic-actions (SA)

*WIP* Where should this be defined?

## Functions

### FIRST(S)

Calculate the first look-ahead number of terminals of the sentential-form `S`, example:

``` emacs-lisp
(require 'ert)

(parser-generator--set-grammar '((S A B C) (a b c) ((S (A B)) (A (B a) e) (B (C b) C) (C c e)) S))
(parser-generator--set-look-ahead-number 2)
(parser-generator--process-grammar)

(should
  (equal
    '((a) (a c) (a b) (c a) (b a) (e) (c) (b) (c b))
    (parser-generator--first 'S)))
```

### E-FREE-FIRST(S)

Calculate the e-free-first look-ahead number of terminals of sentential-form `S`, example:

``` emacs-lisp
(require 'ert)

(parser-generator--set-grammar '((S A B C) (a b c) ((S (A B)) (A (B a) e) (B (C b) C) (C c e)) S))
(parser-generator--set-look-ahead-number 2)
(parser-generator--process-grammar)

(should
  (equal
    '((c b) (c a))
    (parser-generator--e-free-first 'S)))
```

### FOLLOW(S)

Calculate the look-ahead number of terminals possibly following S.

``` emacs-lisp
(require 'ert)

(parser-generator--set-grammar '((S A B) (a c d f) ((S (A a)) (A B) (B (c f) d)) S))
(parser-generator--set-look-ahead-number 2)
(parser-generator--process-grammar)

(should
  (equal
   '((a))
   (parser-generator--follow 'A)))
```

## Test

Run in terminal `make clean && make tests && make compile`
