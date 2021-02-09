;;; parser-generator-lr-export.el --- Export LR(k) Parser -*- lexical-binding: t -*-


;;; Commentary:


;;; Code:


(require 'parser-generator-lr)

(defun parser-generator-lr-export-to-elisp (namespace)
  "Export parser with NAMESPACE."

  ;; Make sure all requisites are defined
  (unless parser-generator-lr--action-tables
    (error "Missing generated ACTION-tables!"))
  (unless parser-generator-lr--goto-tables
    (error "Missing generated GOTO-tables!"))
  (unless parser-generator--table-productions-number-reverse
    (error "Table for reverse production-numbers is undefined!"))
  (unless parser-generator--table-look-aheads-p
    (error "Table for valid look-aheads is undefined!"))
  (unless parser-generator--look-ahead-number
    (error "Missing a look-ahead number!"))
  (unless parser-generator--e-identifier
    (error "Missing definition for e-identifier!"))
  (unless parser-generator--eof-identifier
    (error "Missing definition for EOF-identifier!"))
  (unless parser-generator--table-non-terminal-p
    (error "Table for non-terminals is undefined!"))
  (unless parser-generator--table-terminal-p
    (error "Table for terminals is undefined!"))
  (unless parser-generator--table-translations
    (error "Table for translations by production-number is undefined!"))
  (unless parser-generator-lex-analyzer--get-function
    (error "Missing lex-analyzer get function!"))
  (unless parser-generator-lex-analyzer--function
    (error "Missing lex-analyzer function!"))

  (let ((code))
    (with-temp-buffer
      (goto-char (point-min))

      ;; Header
      (insert
       (format
        ";;; %s.el --- Exported Emacs Parser Generator -*- lexical-binding: t -*-\n\n\n"
        namespace))
      (insert ";;; Commentary:\n\n\n;;; Code:\n\n\n")

      (insert ";;; Constants:\n\n\n")

      ;; Action-tables
      (insert
       (format
        "(defconst\n  %s--action-tables\n  %s\n  \"Generated action-tables.\")\n\n"
        namespace
        parser-generator-lr--action-tables))

      ;; Goto-tables
      (insert
       (format
        "(defconst\n  %s--goto-tables\n  %s\n  \"Generated goto-tables.\")\n\n"
        namespace
        parser-generator-lr--goto-tables))

      ;; Table production-number
      (insert
       (format
        "(defconst\n  %s--table-productions-number-reverse\n  %s\n  \"Hash-table indexed by production-number and value is production.\")\n\n"
        namespace
        parser-generator--table-productions-number-reverse))

      ;; Table look-aheads
      (insert
       (format
        "(defconst\n  %s--table-look-aheads\n  %s\n  \"Hash-table of valid look-aheads.\")\n\n"
        namespace
        parser-generator--table-look-aheads-p))

      ;; Table terminals
      (insert
       (format
        "(defconst\n  %s--table-terminal-p\n  %s\n  \"Hash-table of valid terminals.\")\n\n"
        namespace
        parser-generator--table-non-terminal-p))

      ;; Table non-terminals
      (insert
       (format
        "(defconst\n  %s--table-non-terminal-p\n  %s\n  \"Hash-table of valid non-terminals.\")\n\n"
        namespace
        parser-generator--table-non-terminal-p))

      ;; Table translations
      (insert
       (format
        "(defconst\n  %s--table-translations\n  %s\n  \"Hash-table of translations.\")\n\n"
        namespace
        parser-generator--table-translations))

      ;; Lex-Analyzer Get Function
      (insert
       (format
        "(defconst\n  %s-lex-analyzer--get-function\n  (lambda %s %s)\n  \"Lex-Analyzer Get Function.\")\n\n"
        namespace
        (nth 2 parser-generator-lex-analyzer--get-function)
        (nth 3 parser-generator-lex-analyzer--get-function)))

      ;; Lex-Analyzer Function
      (insert
       (format
        "(defconst\n  %s-lex-analyzer--function\n  (lambda %s %s)\n  \"Lex-Analyzer Function.\")\n\n"
        namespace
        (nth 2 parser-generator-lex-analyzer--function)
        (nth 3 parser-generator-lex-analyzer--function)))

      ;; Lex-Analyzer Reset Function
      (insert
       (format
        "(defconst\n  %s-lex-analyzer--reset-function\n  "
        namespace))
      (if parser-generator-lex-analyzer--reset-function
          (insert
           (format
            "(lambda %s %s)\n"
            (nth 2 parser-generator-lex-analyzer--reset-function)
            (nth 3 parser-generator-lex-analyzer--reset-function)))
        (insert "nil\n"))
      (insert "  \"Lex-Analyzer Reset Function.\")\n\n")

      ;; E-identifier
      (insert
       (format
        "(defconst\n  %s--e-identifier\n  '%s\n  \"e-identifier\")\n\n"
        namespace
        parser-generator--e-identifier))

      ;; EOF-identifier
      (insert
       (format
        "(defconst\n  %s--eof-identifier\n  '%s\n  \"EOF-identifier.\")\n\n"
        namespace
        parser-generator--eof-identifier))

      ;; Look-ahead number
      (insert
       (format
        "(defconst\n  %s--look-ahead-number\n  %s\n  \"Look-ahead number.\")\n\n"
        namespace
        parser-generator--look-ahead-number))

      (insert "\n;;; Variables:\n\n\n")

      ;; Lex-analyzer index
      (insert
       (format
        "(defvar\n  %s-lex-analyzer--index\n  0\n  \"Current index of lex-analyzer.\")\n\n"
        namespace))

      (insert "\n;;; Functions:\n\n\n")

      (insert ";;; Lex-Analyzer:\n\n\n")

      ;; Lex-Analyzer Get Function
      (insert
       (format
        "(defun
  %s-lex-analyzer--get-function (token)
  \"Get information about TOKEN.\"
  (unless
    %s-lex-analyzer--get-function
    (error \"Missing lex-analyzer get function!\"))
  (let ((meta-information))
    (condition-case
      error
      (progn
        (setq
          meta-information
          (funcall
            %s-lex-analyzer--get-function
            token)))"
        namespace
        namespace
        namespace))
      (insert "
      (error
        (error
          \"Lex-analyze failed to get token meta-data of %s, error: %s\"
          token
          (car (cdr error)))))
    (unless meta-information
      (error \"Could not find any token meta-information for: %s\" token))
    meta-information))\n")

      ;; Lex-Analyzer Reset Function
      (insert
       (format "
(defun
  %s-lex-analyzer--reset
  ()
  \"Reset Lex-Analyzer.\"
  (setq
    %s-lex-analyzer--index
    1)
  (when
    %s-lex-analyzer--reset-function
    (funcall
      %s-lex-analyzer--reset-function)))\n"
               namespace
               namespace
               namespace
               namespace))

      ;; Lex-Analyzer Peek Next Look Ahead
      (insert
       (format "
(defun
  %s-lex-analyzer--peek-next-look-ahead
  ()
  \"Peek next look-ahead number of tokens via lex-analyzer.\"
  (let ((look-ahead)
        (look-ahead-length 0)
        (index %s-lex-analyzer--index)
        (k (max
            1
            %s--look-ahead-number)))
    (while (<
            look-ahead-length
            k)
      (condition-case error
          (progn
            (let ((next-look-ahead
                   (funcall
                    %s-lex-analyzer--function
                    index)))
              (if next-look-ahead
                  (progn
                    (unless (listp (car next-look-ahead))
                      (setq next-look-ahead (list next-look-ahead)))
                    (dolist (next-look-ahead-item next-look-ahead)
                      (when (<
                             look-ahead-length
                             k)
                        (push next-look-ahead-item look-ahead)
                        (setq look-ahead-length (1+ look-ahead-length))
                        (setq index (cdr (cdr next-look-ahead-item))))))
                (push (list %s--eof-identifier) look-ahead)
                (setq look-ahead-length (1+ look-ahead-length))
                (setq index (1+ index)))))"
               namespace
               namespace
               namespace
               namespace
               namespace))
      (insert "
        (error
         (error
          \"Lex-analyze failed to peek next look-ahead at %s, error: %s\"
          index
          (car (cdr error))))))
    (nreverse look-ahead)))\n")

      ;; Lex-Analyzer Pop Token
      (insert
       (format "
(defun
  %s-lex-analyzer--pop-token ()
  \"Pop next token via lex-analyzer.\"
  (let ((iteration 0)
        (tokens))
    (while (< iteration 1)
      (condition-case error
          (progn
            (let ((token
                   (funcall
                    %s-lex-analyzer--function
                    %s-lex-analyzer--index)))
              (when token
                (unless (listp (car token))
                  (setq token (list token)))
                (let ((first-token (car token)))
                  (setq
                   %s-lex-analyzer--index
                   (cdr (cdr first-token)))
                  (push first-token tokens)))))"
               namespace
               namespace
               namespace
               namespace))
      (insert "
        (error (error
                \"Lex-analyze failed to pop token at %s, error: %s\"")
      (insert (format "
                %s-lex-analyzer--index
                (car (cdr error)))))
      (setq iteration (1+ iteration)))
    (nreverse tokens)))\n"
                      namespace))

      (insert "\n;;; Syntax-Analyzer / Parser:\n\n\n");

      ;; Get grammar production by number
      (insert
       (format "
(defun
  %s--get-grammar-production-by-number
  (production-number)
  \"If PRODUCTION-NUMBER exist, return it's production.\"
  (gethash
   production-number
   %s--table-productions-number-reverse))\n"
               namespace
               namespace))

      ;; Valid symbol p
      (insert
       (format "
(defun
  %s--valid-symbol-p
  (symbol)
  \"Return whether SYMBOL is valid or not.\"
  (let ((is-valid t))
    (unless (or
             (%s--valid-e-p symbol)
             (%s--valid-eof-p symbol)
             (%s--valid-non-terminal-p symbol)
             (%s--valid-terminal-p symbol))
      (setq is-valid nil))
    is-valid))\n"
               namespace
               namespace
               namespace
               namespace
               namespace))

      ;; Valid e-p
      (insert
       (format "
(defun
  %s--valid-e-p
  (symbol)
  \"Return whether SYMBOL is the e identifier or not.\"
  (eq
   symbol
   %s--e-identifier))\n"
               namespace
               namespace))

      ;; Valid EOF-p
      (insert
       (format "
(defun
  %s--valid-eof-p
  (symbol)
  \"Return whether SYMBOL is the EOF identifier or not.\"
  (eq
    symbol
    %s--eof-identifier))\n"
               namespace
               namespace))

      ;; Valid non-terminal-p
      (insert
       (format "
(defun %s--valid-non-terminal-p (symbol)
  \"Return whether SYMBOL is a non-terminal in grammar or not.\"
  (gethash
   symbol
   %s--table-non-terminal-p))\n"
               namespace
               namespace))

      ;; Valid terminal-p
      (insert
       (format "
(defun %s--valid-terminal-p (symbol)
  \"Return whether SYMBOL is a terminal in grammar or not.\"
  (gethash
   symbol
   %s--table-terminal-p))\n"
               namespace
               namespace))

      ;; Get grammar translation by number
      (insert
       (format "
(defun
  %s--get-grammar-translation-by-number
  (production-number)
  \"If translation for PRODUCTION-NUMBER exist, return it.\"
  (gethash
    production-number
    %s--table-translations))\n"
               namespace
               namespace))

      ;; Parse / translate function
      (insert
       (format "
(defun
  %s--parse
  (&optional
    input-tape-index
    pushdown-list
    output
    translation
    translation-symbol-table
    history)
  \"Perform a LR-parse via lex-analyzer, optionally at INPUT-TAPE-INDEX with PUSHDOWN-LIST, OUTPUT, TRANSLATION, TRANSLATION-SYMBOL-TABLE and HISTORY.\"
  (unless input-tape-index
    (setq input-tape-index 1))
  (unless pushdown-list
    (push 0 pushdown-list))
  (unless translation-symbol-table
    (setq
     translation-symbol-table
     (make-hash-table :test 'equal)))

  (if (and
       input-tape-index
       (> input-tape-index 1))
      (setq
       %s-lex-analyzer--index
       input-tape-index)
    (%s-lex-analyzer--reset))

  (let ((accept)
        (pre-index 0))
    (while (not accept)

      ;; Save history when index has changed to enable incremental parsing / translating
      (when
          (>
           %s-lex-analyzer--index
           pre-index)
        (push
         `(,%s-lex-analyzer--index
           ,pushdown-list
           ,output
           ,translation
           ,translation-symbol-table)
         history)
        (setq
         pre-index
         %s-lex-analyzer--index))

      ;; (1) The look-ahead string u, consisting of the next k input symbols, is determined.
      (let ((look-ahead
             (%s-lex-analyzer--peek-next-look-ahead))
            (look-ahead-full))

        ;; Save token stream indexes in separate variable if needed later
        (setq look-ahead-full look-ahead)

        ;; Create simplified look-ahead for logic below
        (setq look-ahead nil)
        (dolist (look-ahead-item look-ahead-full)
          (if (listp look-ahead-item)
              (push (car look-ahead-item) look-ahead)
            (push look-ahead-item look-ahead)))
        (setq look-ahead (nreverse look-ahead))

        (let ((table-index
               (car pushdown-list)))
          (let ((action-table
                 (gethash
                  table-index
                  %s--action-tables)))"
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace))
      (insert "
            (unless action-table
              (error
               \"Action-table with index %s is empty! Push-down-list: %s\"
               table-index
               pushdown-list))")

      (insert
       (format "
            (let ((action-match nil)
                  (action-table-length (length action-table))
                  (action-index 0)
                  (possible-look-aheads))

              ;; (2) The parsing action f of the table on top of the pushdown list is applied to the lookahead string u.
              (while (and
                      (not action-match)
                      (< action-index action-table-length))
                (let ((action (nth action-index action-table)))
                  (let ((action-look-ahead (car action)))
                    (push
                     action-look-ahead
                     possible-look-aheads)
                    (when
                        (equal
                         action-look-ahead
                         look-ahead)
                      (setq
                       action-match
                       (cdr action)))
                    (when
                        (and
                         (=
                          %s--look-ahead-number
                          0)
                         (not
                          action-look-ahead))
                      ;; LR(0) reduce actions occupy entire row
                      ;; and is applied regardless of look-ahead
                      (setq
                       action-match
                       (cdr action))))
                  (setq
                   action-index
                   (1+ action-index))))

              (unless action-match
                ;; (c) If f(u) = error, we halt parsing (and, in practice
                ;; transfer to an error recovery routine)."
               namespace))
      (insert "
                (error
                 (format
                  \"Invalid syntax! Expected one of %s found %s at %s\"
                  possible-look-aheads
                  look-ahead")
      (insert (format "
                  %s-lex-analyzer--index)
                 possible-look-aheads
                 look-ahead
                 %s-lex-analyzer--index))

              (cond

               ((equal action-match '(shift))
                ;; (a) If f(u) = shift, then the next input symbol, say a
                ;; is removed from the input and shifted onto the pushdown list.
                ;; The goto function g of the table on top of the pushdown list
                ;; is applied to a to determine the new table to be placed on
                ;; top of the pushdown list. We then return to step(1). If
                ;; there is no next input symbol or g(a) is undefined, halt
                ;; and declare error.

                (let ((a (list (car look-ahead)))
                      (a-full (list (car look-ahead-full))))
                  (let ((goto-table
                         (gethash
                          table-index
                          %s--goto-tables)))
                    (let ((goto-table-length (length goto-table))
                          (goto-index 0)
                          (searching-match t)
                          (next-index)
                          (possible-look-aheads))

                      (while (and
                              searching-match
                              (< goto-index goto-table-length))
                        (let ((goto-item (nth goto-index goto-table)))
                          (let ((goto-item-symbol (list (car goto-item)))
                                (goto-item-next-index (car (cdr goto-item))))
                            (push goto-item-symbol possible-look-aheads)

                            (when (equal
                                   goto-item-symbol
                                   a)
                              (setq next-index goto-item-next-index)
                              (setq searching-match nil))))

                        (setq goto-index (1+ goto-index)))"
                      namespace
                      namespace
                      namespace))

      (insert "
                      (unless next-index
                        (error
                         \"In shift, found no GOTO-item for %s at %s, expected one of %s\"
                         a")
      (insert
       (format "
                         %s-lex-analyzer--index
                         possible-look-aheads))

                      ;; Maybe push both tokens here?
                      (push (car a-full) pushdown-list)
                      (push next-index pushdown-list)
                      (%s-lex-analyzer--pop-token)))))

               ((equal (car action-match) 'reduce)
                ;; (b) If f(u) = reduce i and production i is A -> a,
                ;; then 2|a| symbols are removed from the top of the pushdown
                ;; list, and production number i is placed in the output
                ;; buffer. A new table T' is then exposed as the top table
                ;; of the pushdown list, and the goto function of T' is applied
                ;; to A to determine the next table to be placed on top of the
                ;; pushdown list. We place A and this new table on top of the
                ;; the pushdown list and return to step (1)

                (let ((production-number (car (cdr action-match))))

                  (let ((production
                         (%s--get-grammar-production-by-number
                          production-number)))
                    (let ((production-lhs (car production))
                          (production-rhs (car (cdr production)))
                          (popped-items-contents))
                      (unless (equal
                               production-rhs
                               (list %s--e-identifier))
                        (let ((pop-items (* 2 (length production-rhs)))
                              (popped-items 0)
                              (popped-item))
                          (while (< popped-items pop-items)
                            (setq popped-item (pop pushdown-list))
                            (when (and
                                   (listp popped-item)
                                   (%s--valid-symbol-p
                                    (car popped-item)))
                              (push
                               popped-item
                               popped-items-contents))
                            (setq popped-items (1+ popped-items)))))
                      (push production-number output)

                      (let ((popped-items-meta-contents)
                            (all-expanded t))
                        ;; Collect arguments for translation
                        (dolist (popped-item popped-items-contents)
                          (if (and
                               (listp popped-item)
                               (cdr popped-item))
                              ;; If item is a terminal, use it's literal value
                              (push
                               (%s-lex-analyzer--get-function
                                popped-item)
                               popped-items-meta-contents)
                            (if (gethash
                                 popped-item
                                 translation-symbol-table)
                                (push
                                 (gethash
                                  popped-item
                                  translation-symbol-table)
                                 popped-items-meta-contents)
                              (setq
                               all-expanded
                               nil)
                              (push
                               nil
                               popped-items-meta-contents))))
                        (setq
                         popped-items-meta-contents
                         (nreverse popped-items-meta-contents))

                        ;; Perform translation at reduction if specified
                        (if
                            (%s--get-grammar-translation-by-number
                             production-number)
                            (let ((partial-translation
                                   (funcall
                                    (%s--get-grammar-translation-by-number
                                     production-number)
                                    popped-items-meta-contents)))
                              (puthash
                               production-lhs
                               partial-translation
                               translation-symbol-table)
                              (setq
                               translation
                               partial-translation))

                          ;; When no translation is specified just use arguments as translation
                          (when all-expanded
                            (let ((partial-translation
                                   popped-items-meta-contents))
                              (puthash
                               production-lhs
                               partial-translation
                               translation-symbol-table)
                              (setq
                               translation
                               partial-translation)))))

                      (let ((new-table-index (car pushdown-list)))
                        (let ((goto-table
                               (gethash
                                new-table-index
                                %s--goto-tables)))
                          (let ((goto-table-length
                                 (length goto-table))
                                (goto-index 0)
                                (searching-match t)
                                (next-index))

                            (while (and
                                    searching-match
                                    (< goto-index goto-table-length))
                              (let ((goto-item (nth goto-index goto-table)))
                                (let ((goto-item-symbol (list (car goto-item)))
                                      (goto-item-next-index (car (cdr goto-item))))

                                  (when (equal
                                         goto-item-symbol
                                         production-lhs)
                                    (setq next-index goto-item-next-index)
                                    (setq searching-match nil))))

                              (setq goto-index (1+ goto-index)))

                            (when next-index
                              (push production-lhs pushdown-list)
                              (push next-index pushdown-list)))))))))

               ((equal action-match '(accept))
                ;;    (d) If f(u) = accept, we halt and declare the string
                ;;    in the output buffer to be the right parse of the original
                ;;    input string.

                (setq accept t))"
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace
               namespace))

      (insert "
               (t (error
                   \"Invalid action-match: %s!\"
                   action-match))))))))
    (unless accept
      (error
       \"Parsed entire string without getting accepting! Output: %s\"
       (reverse output)))
    (when history
      (setq history (reverse history)))
    (when output
      (setq output (reverse output)))
    (list
     output
     translation
     translation-symbol-table
     history)))\n")

      ;; Parse
      (insert
       (format "
(defun %s-parse
    (&optional
     input-tape-index
     pushdown-list
     output
     translation
     history)
  \"Perform a LR-parse via lex-analyzer, optionally at INPUT-TAPE-INDEX with PUSHDOWN-LIST, OUTPUT, TRANSLATION and HISTORY.\"
  (let ((result
         (%s--parse
          input-tape-index
          pushdown-list
          output
          translation
          history)))
    (nth 0 result)))\n"
               namespace
               namespace))

      ;; Translate
      (insert
       (format "
(defun %s-translate
    (&optional
     input-tape-index
     pushdown-list
     output
     translation
     history)
  \"Perform a LR-parse via lex-analyzer, optionally at INPUT-TAPE-INDEX with PUSHDOWN-LIST, OUTPUT, TRANSLATION and HISTORY.\"
  (let ((result
         (%s--parse
          input-tape-index
          pushdown-list
          output
          translation
          history)))
    (nth 1 result)))\n"
               namespace
               namespace))

      ;; Footer
      (insert
       (format
        "\n(provide '%s)"
        namespace))
      (insert
       (format
        "\n\n;;; %s.el ends here"
        namespace))

      (setq
       code
       (buffer-substring-no-properties
        (point-min)
        (point-max))))
    code))


(provide 'parser-generator-lr-export)

;;; parser-generator-lr-export.el ends here
