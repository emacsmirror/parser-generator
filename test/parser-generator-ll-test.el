;; parser-generator-ll-test.el --- Tests for LL(k) Parser Generator -*- lexical-binding: t -*-

;; Copyright (C) 2020-2022  Free Software Foundation, Inc.


;;; Commentary:


;;; Code:


(require 'parser-generator-ll)
(require 'ert)

(defun parser-generator-ll-test--generate-tables ()
  "Test `parser-generator-ll--generate-tables'."
  (message "Started tests for (parser-generator-ll--generate-tables)")

  ;; Example 5.14 p. 350
  ;; Example 5.15 p. 351
  (parser-generator-set-e-identifier 'e)
  (parser-generator-set-look-ahead-number 2)
  (parser-generator-set-grammar
   '(
     (S A)
     (a b)
     (
      (S (a A a a) (b A b a))
      (A b e)
      )
     S
     )
   )
  (parser-generator-process-grammar)
  (let ((tables (parser-generator-ll--generate-tables)))
    ;; (message "tables: %S" tables)
    (should
     (equal
      tables
      '(
        (
         ((A) (b a))
         (
          ((b b) (b) nil)
          ((b a) (e) nil)
          )
         )
        (
         ((A) (a a))
         (
          ((a a) (e) nil)
          ((b a) (b) nil)
          )
         )
        (
         ((S) nil)
         (
          ((a b) (a A a a) ((a a)))
          ((a a) (a A a a) ((a a)))
          ((b b) (b A b a) ((b a)))
          )
         )
        )
      ))
    tables)

  (message "Passed tests for (parser-generator-ll--generate-tables)"))

(defun parser-generator-ll-test--generate-parsing-table ()
  "Test `parser-generator-ll--generate-parsing-table'."
  (message "Started tests for (parser-generator-ll--generate-parsing-table)")

  (parser-generator-set-eof-identifier '$)
  (parser-generator-set-e-identifier 'e)
  (parser-generator-set-look-ahead-number 2)
  (let* ((tables
          '(
            (
             ((A) (b a))
             (
              ((b b) (b) nil)
              ((b a) (e) nil)
              )
             )
            (
             ((A) (a a))
             (
              ((a a) (e) nil)
              ((b a) (b) nil)
              )
             )
            (
             ((S) nil)
             (
              ((a b) (a A a a) ((a a)))
              ((a a) (a A a a) ((a a)))
              ((b b) (b A b a) ((b a)))
              )
             )
            )
          )
         (parser-tables
          (parser-generator-ll--generate-parsing-table
           tables)))
    ;; (message "parser-tables: %S" parser-tables)

    (should
     (equal
      '(
        (
         ((S) nil) ;; T0
         (
          ((b b) reduce (b ((A) (b a)) b a) 1)
          ((a a) reduce (a ((A) (a a)) a a) 0)
          ((a b) reduce (a ((A) (a a)) a a) 0)
          )
         )
        (
         ((A) (a a)) ;; T1
         (
          ((b a) reduce (b) 2)
          ((a a) reduce (e) 3)
          )
         )
        (
         ((A) (b a));; T2
         (
          ((b a) reduce (e) 3)
          ((b b) reduce (b) 2)
          )
         )
        (
         b
         (
          ((b b) pop)
          ((b a) pop)
          ((b $) pop)
          )
         )
        (
         a
         (
          ((a b) pop)
          ((a a) pop)
          ((a $) pop)
          )
         )
        (
         $
         (($ $) accept)
         )
        )
      parser-tables)))

  (message "Passed tests for (parser-generator-ll--generate-parsing-table)"))

(defun parser-generator-ll-test--valid-grammar-p ()
  "Test `parser-generator-ll--valid-grammar-p'."
  (message "Started tests for (parser-generator-ll--valid-grammar-p)")


  (message "Passed tests for (parser-generator-ll--valid-grammar-p)"))

(defun parser-generator-ll-test-generate-parser-tables ()
  "Test `parser-generator-ll-generate-parser-tables'."
  (message "Started tests for (parser-generator-ll-generate-parser-tables)")


  (message "Passed tests for (parser-generator-ll-generate-parser-tables)"))

(defun parser-generator-ll-test ()
  "Run test."
  (parser-generator-ll-test--generate-tables)
  (parser-generator-ll-test--generate-parsing-table)
  (parser-generator-ll-test--valid-grammar-p)
  (parser-generator-ll-test-generate-parser-tables))


(provide 'parser-generator-ll-test)

;;; parser-generator-ll-test.el ends here
