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
          '((((A) (b a)) (((b b) (b) nil) ((b a) (e) nil)))
            (((A) (a a)) (((a a) (e) nil) ((b a) (b) nil)))
            (((S) nil) (((a b) (a A a a) ((a a))) ((a a) (a A a a) ((a a))) ((b b) (b A b a) ((b a)))))))
         (parser-tables
          (parser-generator-ll--generate-parsing-table
           tables)))
    (message "parser-tables: %S" parser-tables)

    ;; TODO Make this pass
    (should
     (equal
      '(
        (
         ((S) nil)
         (
          ((a a) reduce (a T1 a a) 1)
          ((a b) reduce (a T1 a a) 1)
          ((b b) reduce (b T2 b a) 2)
          )
         )
        (
         ((A) (a a))
         (
          ((a a) reduce (e) 4)
          ((b a) reduce (b) 3)
          )
         )
        (
         ((A) (a b))
         (
          ((b a) reduce (e) 4)
          ((b b) reduce (b) 3)
          )
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
