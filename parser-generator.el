;;; parser-generator.el --- Parser Generator library -*- lexical-binding: t -*-


;;; Commentary:


;;; Code:


;;; Variables:


(defvar parser-generator--allow-e-productions
  nil
  "Flag whether e-productions is allowed or not.")

(defvar parser-generator--debug
  nil
  "Whether to print debug messages or not.")

(defvar parser-generator--e-identifier
  'e
  "The identifier used for e-symbol.  Default value 'e.")

(defvar parser-generator--grammar
  nil
  "Current grammar used in parser.")

(defvar parser-generator--f-sets
  nil
  "Generated F-sets for grammar.")

(defvar parser-generator--f-free-sets
  nil
  "Generated e-free F-sets for grammar.")

(defvar parser-generator--look-ahead-number
  nil
  "Current look-ahead number used.")

(defvar parser-generator--table-look-aheads-p
  nil
  "Hash-table of look-aheads for quick checking.")

(defvar parser-generator--table-non-terminal-p
  nil
  "Hash-table of terminals for quick checking.")

(defvar parser-generator--table-productions-rhs
  nil
  "Hash-table of productions RHS indexed by LHS for quick retrieving.")

(defvar parser-generator--table-productions-number
  nil
  "Hash-table indexed by production and value is production-number.")

(defvar parser-generator--table-productions-number-reverse
  nil
  "Hash-table indexed by production-number and value is production.")

(defvar parser-generator--table-terminal-p
  nil
  "Hash-table of non-terminals for quick checking.")


;; Macros


(defmacro parser-generator--debug (&rest message)
  "Output MESSAGE but only if debug is enabled."
  `(when parser-generator--debug
     ,@message))


;; Helper Functions


(defun parser-generator--clear-cache ()
  "Clear cache."
  (setq parser-generator--f-sets nil)
  (setq parser-generator--f-free-sets nil))

(defun parser-generator--distinct (elements)
  "Return distinct of ELEMENTS."
  (let ((processed (make-hash-table :test 'equal))
        (new-elements))
    (dolist (element elements)
      (unless (gethash element processed)
        (puthash element t processed)
        (push element new-elements)))
    (nreverse new-elements)))

(defun parser-generator--get-grammar-look-aheads ()
  "Return all possible look-ahead set."
  (unless parser-generator--look-ahead-number
    (error "No look-ahead number defined!"))
  (let ((terminals (parser-generator--get-grammar-terminals))
        (look-aheads)
        (k parser-generator--look-ahead-number)
        (stack '((0 0 nil)))
        (marked-paths (make-hash-table :test 'equal))
        (added-look-aheads (make-hash-table :test 'equal)))
    (let ((terminals-max-index (1- (length terminals)))
          (terminal-index)
          (look-ahead-length)
          (look-ahead))
      (while stack
        (let ((item (pop stack)))
          (setq terminal-index (nth 0 item))
          (setq look-ahead-length (nth 1 item))
          (setq look-ahead (nth 2 item))

          (while (and
                  (< look-ahead-length k)
                  (<= terminal-index terminals-max-index))
            (let ((potential-look-ahead look-ahead)
                  (next-terminal (nth terminal-index terminals)))
              (push next-terminal potential-look-ahead)
              (if (gethash potential-look-ahead marked-paths)
                  (setq terminal-index (1+ terminal-index))
                (puthash potential-look-ahead t marked-paths)

                (push `(,terminal-index ,look-ahead-length,look-ahead) stack)

                (setq look-ahead-length (1+ look-ahead-length))
                (setq look-ahead potential-look-ahead)
                (setq terminal-index 0))))

          (let ((look-ahead-to-add))
            (if look-ahead
                (progn

                  (when (= look-ahead-length k)
                    (setq look-ahead-to-add (reverse look-ahead)))

                  (when (= look-ahead-length (1- k))
                    (push parser-generator--e-identifier look-ahead)
                    (setq look-ahead-to-add (reverse look-ahead))))

              (when (= k 1)
                (setq look-ahead-to-add `(,parser-generator--e-identifier))))

            (when (and look-ahead-to-add
                       (not (gethash look-ahead-to-add added-look-aheads)))
              (puthash look-ahead-to-add t added-look-aheads)
              (push look-ahead-to-add look-aheads))))))

    (sort look-aheads 'parser-generator--sort-list)))

(defun parser-generator--get-grammar-non-terminals (&optional G)
  "Return non-terminals of grammar G."
  (unless G
    (if parser-generator--grammar
        (setq G parser-generator--grammar)
      (error "No grammar G defined!")))
  (nth 0 G))

(defun parser-generator--get-grammar-production-number (production)
  "If PRODUCTION exist, return it's number."
  (unless parser-generator--table-productions-number
    (error "Table for production-numbers is undefined!"))
  (gethash production parser-generator--table-productions-number))

(defun parser-generator--get-grammar-production-by-number (production-number)
  "If PRODUCTION-NUMBER exist, return it's production."
  (unless parser-generator--table-productions-number-reverse
    (error "Table for reverse production-numbers is undefined!"))
  (gethash production-number parser-generator--table-productions-number-reverse))

(defun parser-generator--get-grammar-productions (&optional G)
  "Return productions of grammar G."
  (unless G
    (if parser-generator--grammar
        (setq G parser-generator--grammar)
      (error "No grammar G defined!")))
  (nth 2 G))

(defun parser-generator--get-grammar-rhs (lhs)
  "Return right hand sides of LHS if there is any."
  (unless parser-generator--table-productions-rhs
    (error "Table for productions RHS indexed by LHS is undefined!"))
  (gethash lhs parser-generator--table-productions-rhs))

(defun parser-generator--get-grammar-start (&optional G)
  "Return start of grammar G."
  (unless G
    (if parser-generator--grammar
        (setq G parser-generator--grammar)
      (error "No grammar G defined!")))
  (nth 3 G))

(defun parser-generator--get-grammar-terminals (&optional G)
  "Return terminals of grammar G."
  (unless G
    (if parser-generator--grammar
        (setq G parser-generator--grammar)
      (error "No grammar G defined!")))
  (nth 1 G))

(defun parser-generator--hash-to-list (hash-table &optional un-sorted)
  "Return a list that represent the HASH-TABLE.  Each element is a list: (list key value), optionally UN-SORTED."
  (let (result)
    (if (hash-table-p hash-table)
        (progn
          (maphash
           (lambda (k v) (push (list k v) result))
           hash-table)
          (if un-sorted
              (nreverse result)
            (sort (nreverse result) (lambda (a b) (< (car a) (car b))))))
      nil)))

(defun parser-generator--hash-values-to-list (hash-table &optional un-sorted)
  "Return a list that represent the HASH-TABLE.  Each element is a list: (list key value), optionally UN-SORTED."
  (let (result)
    (if (hash-table-p hash-table)
        (progn
          (maphash
           (lambda (_k v) (push v result))
           hash-table)
          (if un-sorted
              (nreverse result)
            (sort (nreverse result) (lambda (a b) (< (car a) (car b))))))
      nil)))

(defun parser-generator--load-symbols ()
  "Load terminals and non-terminals in grammar."
  (let ((terminals (parser-generator--get-grammar-terminals)))
    (setq parser-generator--table-terminal-p (make-hash-table :test 'equal))
    (dolist (terminal terminals)
      (puthash terminal t parser-generator--table-terminal-p)))

  (let ((non-terminals (parser-generator--get-grammar-non-terminals)))
    (setq parser-generator--table-non-terminal-p (make-hash-table :test 'equal))
    (dolist (non-terminal non-terminals)
      (puthash non-terminal t parser-generator--table-non-terminal-p)))

  (let ((productions (parser-generator--get-grammar-productions)))
    (setq parser-generator--table-productions-rhs (make-hash-table :test 'equal))
    (dolist (p productions)
      (let ((lhs (car p))
            (rhs (cdr p)))
        (let ((new-value (gethash lhs parser-generator--table-productions-rhs)))
          (dolist (rhs-element rhs)
            (unless (listp rhs-element)
              (setq rhs-element (list rhs-element)))
            (push rhs-element new-value))
          (puthash lhs (nreverse new-value) parser-generator--table-productions-rhs))))

    (setq parser-generator--table-productions-number (make-hash-table :test 'equal))
    (setq parser-generator--table-productions-number-reverse (make-hash-table :test 'equal))
    (let ((production-index 0))
      (dolist (p productions)
        (let ((lhs (car p))
              (rhs (cdr p))
              (production))
          (dolist (rhs-element rhs)
            (unless (listp rhs-element)
              (setq rhs-element (list rhs-element)))
            (setq production (list lhs rhs-element))
            (parser-generator--debug
             (message "Production %s: %s" production-index production))
            (puthash production production-index parser-generator--table-productions-number)
            (puthash production-index production parser-generator--table-productions-number-reverse)
            (setq production-index (1+ production-index)))))))

  (let ((look-aheads (parser-generator--get-grammar-look-aheads)))
    (setq parser-generator--table-look-aheads-p (make-hash-table :test 'equal))
    (dolist (look-ahead look-aheads)
      (puthash look-ahead t parser-generator--table-look-aheads-p))))

(defun parser-generator--set-look-ahead-number (k)
  "Set look-ahead number K."
  (unless (parser-generator--valid-look-ahead-number-p k)
    (error "Invalid look-ahead number k!"))
  (setq parser-generator--look-ahead-number k))

(defun parser-generator--set-allow-e-productions (flag)
  "Set FLAG whether e-productions is allowed or not."
  (setq parser-generator--allow-e-productions flag))

(defun parser-generator--set-grammar (G)
  "Set grammar G.."
  (unless (parser-generator--valid-grammar-p G)
    (error "Invalid grammar G!"))
  (setq parser-generator--grammar G))

(defun parser-generator--process-grammar ()
  "Process grammar."
  (parser-generator--clear-cache)
  (parser-generator--load-symbols))

(defun parser-generator--sort-list (a b)
  "Return non-nil if a element in A is greater than a element in B in lexicographic order."
  (let ((length (min (length a) (length b)))
        (index 0)
        (continue t)
        (response nil))
    (while (and
            continue
            (< index length))
      (let ((a-element (nth index a))
            (b-element (nth index b)))
        (while (and
                a-element
                (listp a-element))
          (setq a-element (car a-element)))
        (while (and
                b-element
                (listp b-element))
          (setq b-element (car b-element)))
        (when (and
               (or
                (stringp a-element)
                (symbolp a-element))
               (or
                (stringp b-element)
                (symbolp b-element)))
          (if (string-greaterp a-element b-element)
              (setq continue nil)
            (when (string-greaterp b-element a-element)
              (setq response t)
              (setq continue nil))))
        (when (and
               (numberp a-element)
               (numberp b-element))
          (if (> a-element b-element)
              (setq continue nil)
            (when (> b-element a-element)
              (setq response t)
              (setq continue nil)))))
      (setq index (1+ index)))
    response))

(defun parser-generator--valid-e-p (symbol)
  "Return whether SYMBOL is the e identifier or not."
  (eq symbol parser-generator--e-identifier))

(defun parser-generator--valid-grammar-p (G)
  "Return if grammar G is valid or not.  Grammar should contain list with 4 elements: non-terminals (N), terminals (T), productions (P), start (S) where N, T and P are lists containing symbols and/or strings and S is a symbol or string."
  (let ((valid-p t))
    (unless (listp G)
      (setq valid-p nil))
    (when (and
           valid-p
           (not (= (length G) 4)))
      (setq valid-p nil))
    (when (and
           valid-p
           (or
            (not (listp (nth 0 G)))
            (not (listp (nth 1 G)))
            (not (listp (nth 2 G)))
            (not (or
                  (stringp (nth 3 G))
                  (symbolp (nth 3 G))))))
      (setq valid-p nil))
    (when valid-p

      ;; Check every non-terminal
      (let ((non-terminals (nth 0 G)))
        (let ((non-terminal-count (length non-terminals))
              (non-terminal-index 0))
          (while (and
                  valid-p
                  (< non-terminal-index non-terminal-count))
            (let ((non-terminal (nth non-terminal-index non-terminals)))
              (unless (or
                       (symbolp non-terminal)
                       (stringp non-terminal))
                (setq valid-p nil)))
            (setq non-terminal-index (1+ non-terminal-index)))))

      ;; Check every terminal
      (let ((terminals (nth 1 G)))
        (let ((terminal-count (length terminals))
              (terminal-index 0))
          (while (and
                  valid-p
                  (< terminal-index terminal-count))
            (let ((terminal (nth terminal-index terminals)))
              (unless (or
                       (symbolp terminal)
                       (stringp terminal))
                (setq valid-p nil)))
            (setq terminal-index (1+ terminal-index)))))

      ;; Check every production
      (let ((productions (nth 2 G)))
        (let ((production-count (length productions))
              (production-index 0))
          (while (and
                  valid-p
                  (< production-index production-count))
            (let ((production (nth production-index productions)))
              (unless (parser-generator--valid-production-p production)
                (setq valid-p nil)))
            (setq production-index (1+ production-index)))))

      ;; Check start
      (let ((start (nth 3 G)))
        (when (and
               valid-p
               (not (or (stringp start) (symbolp start))))
          (setq valid-p nil))))
    valid-p))

(defun parser-generator--valid-look-ahead-p (symbol)
  "Return whether SYMBOL is a look-ahead in grammar or not."
  (unless parser-generator--table-look-aheads-p
    (error "Table for look-aheads is undefined!"))
  (unless (listp symbol)
    (setq symbol (list symbol)))
  (gethash symbol parser-generator--table-look-aheads-p))

(defun parser-generator--valid-look-ahead-number-p (k)
  "Return if look-ahead number K is valid or not."
  (and
   (integerp k)
   (>= k 0)))

(defun parser-generator--valid-non-terminal-p (symbol)
  "Return whether SYMBOL is a non-terminal in grammar or not."
  (unless parser-generator--table-non-terminal-p
    (error "Table for non-terminals is undefined!"))
  (gethash symbol parser-generator--table-non-terminal-p))

(defun parser-generator--valid-production-p (production)
  "Return whether PRODUCTION is valid or not."
  (let ((is-valid t))
    (unless (listp production)
      (setq is-valid nil))
    (when (and is-valid
               (not (> (length production) 1)))
      (setq is-valid nil))
    (when (and is-valid
               (not (or
                     (stringp (car production))
                     (symbolp (car production))
                     (listp (car production)))))
      (setq is-valid nil))

    ;; Validate left-hand-side (LHS) of production
    (when (and is-valid
               (listp (car production)))
      (let ((lhs (car production)))
        (let ((lhs-index 0)
              (lhs-length (length lhs)))
          (while (and is-valid
                      (< lhs-index lhs-length))
            (let ((p (nth lhs-index lhs)))
              (unless (or
                       (stringp p)
                       (symbolp p))
                (setq is-valid nil)))
            (setq lhs-index (1+ lhs-index))))))

    ;; Validate that RHS is a list or symbol or a string
    (when (and is-valid
               (not (or
                     (listp (car (cdr production)))
                     (symbolp (car (cdr production)))
                     (stringp (car (cdr production))))))
      (message "RHS is invalid")
      (setq is-valid nil))

    ;; Validate right-hand-side (RHS) of production
    (when is-valid
      (let ((rhs (cdr production)))
        (let ((rhs-index 0)
              (rhs-length (length rhs)))
          (while (and is-valid
                      (< rhs-index rhs-length))
            (let ((rhs-element (nth rhs-index rhs)))
              (cond
               ((stringp rhs-element))
               ((symbolp rhs-element))
               ((listp rhs-element)
                (dolist (rhs-sub-element rhs-element)
                  (unless (or
                           (stringp rhs-sub-element)
                           (symbolp rhs-sub-element))
                    (setq is-valid nil))))
               (t (setq is-valid nil)))
              (setq rhs-index (1+ rhs-index)))))))
    is-valid))

(defun parser-generator--valid-sentential-form-p (symbols)
  "Return whether SYMBOLS is a valid sentential form in grammar or not."
  (let ((is-valid t))
    (let ((symbols-length (length symbols))
          (symbol-index 0))
      (while (and
              is-valid
              (< symbol-index symbols-length))
        (let ((symbol (nth symbol-index symbols)))
          (unless (parser-generator--valid-symbol-p symbol)
            (setq is-valid nil)))
        (setq symbol-index (1+ symbol-index))))
    is-valid))

(defun parser-generator--valid-symbol-p (symbol)
  "Return whether SYMBOL is valid or not."
  (let ((is-valid t))
    (unless (or
             (parser-generator--valid-e-p symbol)
             (parser-generator--valid-non-terminal-p symbol)
             (parser-generator--valid-terminal-p symbol))
      (setq is-valid nil))
    is-valid))

(defun parser-generator--valid-terminal-p (symbol)
  "Return whether SYMBOL is a terminal in grammar or not."
  (unless parser-generator--table-terminal-p
    (error "Table for terminals is undefined!"))
  (gethash symbol parser-generator--table-terminal-p))


;; Main Algorithms


;; p. 381
(defun parser-generator--e-free-first (α)
  "For sentential string Α, Calculate e-free-first k terminals in grammar."
  (parser-generator--first α t))

;; p. 358
(defun parser-generator--f-set (input-tape state stack)
  "A deterministic push-down transducer (DPDT) for building F-sets from INPUT-TAPE, STATE and STACK."
  (unless (listp input-tape)
    (setq input-tape (list input-tape)))
  (parser-generator--debug
   (message "(parser-generator--f-set)")
   (message "input-tape: %s" input-tape)
   (message "state: %s" state)
   (message "stack: %s" stack))

  (let ((f-set)
        (input-tape-length (length input-tape))
        (k (nth 0 state))
        (i (nth 1 state))
        (f-sets (nth 2 state))
        (disallow-e-first (nth 3 state)))
    (parser-generator--debug
     (message "disallow-e-first: %s" disallow-e-first)
     (message "input-tape-length: %s" input-tape-length)
     (message "k: %s" k)
     (message "i: %s" i))
    (while stack
      (let ((stack-symbol (pop stack)))
        (parser-generator--debug
         (message "Stack-symbol: %s" stack-symbol))
        (let ((leading-terminals (nth 0 stack-symbol))
              (all-leading-terminals-p (nth 1 stack-symbol))
              (input-tape-index (nth 2 stack-symbol))
              (e-first-p))
          (parser-generator--debug
           (message "leading-terminals: %s" leading-terminals)
           (message "all-leading-terminals-p: %s" all-leading-terminals-p)
           (message "input-tape-index: %s" input-tape-index))

          ;; Flag whether leading-terminal is empty or not
          (when (parser-generator--valid-e-p leading-terminals)
            (setq e-first-p t))

          (parser-generator--debug (message "e-first-p: %s" e-first-p))

          ;; If leading terminal is empty and we have input-tape left, disregard it
          (when (and
                 (not disallow-e-first)
                 e-first-p
                 (< input-tape-index input-tape-length))
            (parser-generator--debug (message "Disregarding empty first terminal"))
            (setq leading-terminals nil))

          (let ((leading-terminals-count (length leading-terminals)))
            (parser-generator--debug (message "leading-terminals-count: %s" leading-terminals-count))
            (while (and
                    (< input-tape-index input-tape-length)
                    (< leading-terminals-count k)
                    all-leading-terminals-p)
              (let ((rhs-element (nth input-tape-index input-tape))
                    (rhs-type))
                (parser-generator--debug (message "rhs-element: %s" rhs-element))

                ;; Determine symbol type
                (cond
                 ((parser-generator--valid-non-terminal-p rhs-element)
                  (setq rhs-type 'NON-TERMINAL))
                 ((parser-generator--valid-e-p rhs-element)
                  (setq rhs-type 'EMPTY))
                 ((parser-generator--valid-terminal-p rhs-element)
                  (setq rhs-type 'TERMINAL))
                 (t (error (format "Invalid symbol %s" rhs-element))))
                (parser-generator--debug (message "rhs-type: %s" rhs-type))

                (cond

                 ((equal rhs-type 'NON-TERMINAL)
                  (if (> i 0)
                      (let ((sub-terminal-sets (gethash rhs-element (gethash (1- i) f-sets))))
                        (if sub-terminal-sets
                            (progn
                              (parser-generator--debug
                               (message "Sub-terminal-sets F_%s_%s(%s) = %s (%d)" (1- i) k rhs-element sub-terminal-sets (length sub-terminal-sets)))
                              (let ((sub-terminal-set (car sub-terminal-sets)))

                                (unless (= (length sub-terminal-sets) 1)
                                  ;; Should branch off here, each unique permutation should be included in set
                                  ;; Follow first alternative in this scope but follow the rest in separate scopes
                                  (let ((sub-terminal-index 0))
                                    (dolist (sub-terminal-alternative-set sub-terminal-sets)
                                      (unless (= sub-terminal-index 0)
                                        (let ((alternative-all-leading-terminals-p all-leading-terminals-p))
                                          (parser-generator--debug (message "Sub-terminal-alternative-set: %s" sub-terminal-alternative-set))

                                          ;; When sub-set only contains the e symbol
                                          (when (parser-generator--valid-e-p (car sub-terminal-alternative-set))
                                            (parser-generator--debug (message "alternative-set is e symbol"))
                                            (if disallow-e-first
                                                (when (= leading-terminals-count 0)
                                                  (setq alternative-all-leading-terminals-p nil))
                                              (when (or
                                                     (> leading-terminals-count 0)
                                                     (< input-tape-index (1- input-tape-length)))
                                                (setq sub-terminal-alternative-set nil)
                                                (parser-generator--debug (message "Cleared sub-terminal-alternative-set")))))

                                          (let ((sub-rhs-leading-terminals (append leading-terminals sub-terminal-alternative-set)))
                                            (parser-generator--debug (message "sub-rhs-leading-terminals: %s" sub-rhs-leading-terminals))
                                            (when (> (length sub-rhs-leading-terminals) k)
                                              (setq sub-rhs-leading-terminals (butlast sub-rhs-leading-terminals (- (length sub-rhs-leading-terminals) k))))
                                            (push `(,sub-rhs-leading-terminals ,alternative-all-leading-terminals-p ,(1+ input-tape-index)) stack))))
                                      (setq sub-terminal-index (1+ sub-terminal-index)))))

                                (parser-generator--debug (message "Sub-terminal-set: %s" sub-terminal-set))
                                (when (or
                                       (not (parser-generator--valid-e-p (car sub-terminal-set)))
                                       (= input-tape-index (1- input-tape-length)))
                                  (setq leading-terminals (append leading-terminals sub-terminal-set))
                                  (setq leading-terminals-count (+ leading-terminals-count (length sub-terminal-set)))
                                  (when (> leading-terminals-count k)
                                    (setq leading-terminals (butlast leading-terminals (- leading-terminals-count k)))
                                    (setq leading-terminals-count k)))))
                          (parser-generator--debug
                           (message "Found no subsets for %s %s" rhs-element (1- i)))
                          (setq all-leading-terminals-p nil)))
                    (setq all-leading-terminals-p nil)))

                 ((equal rhs-type 'EMPTY)
                  (if disallow-e-first
                      (when (= leading-terminals-count 0)
                        (setq all-leading-terminals-p nil))
                    (when (and
                           (= leading-terminals-count 0)
                           (= input-tape-index (1- input-tape-length)))
                      (setq leading-terminals (append leading-terminals rhs-element))
                      (setq leading-terminals-count (1+ leading-terminals-count)))))

                 ((equal rhs-type 'TERMINAL)
                  (when all-leading-terminals-p
                    (setq leading-terminals (append leading-terminals (list rhs-element)))
                    (setq leading-terminals-count (1+ leading-terminals-count))))))
              (setq input-tape-index (1+ input-tape-index)))
            (when (> leading-terminals-count 0)
              (unless (listp leading-terminals)
                (setq leading-terminals (list leading-terminals)))
              (push leading-terminals f-set))))))
    f-set))

;; Algorithm 5.5, p. 357
(defun parser-generator--first (β &optional disallow-e-first)
  "For sentential-form Β, calculate first terminals, optionally DISALLOW-E-FIRST."
  (unless (listp β)
    (setq β (list β)))
  (unless (parser-generator--valid-sentential-form-p β)
    (error "Invalid sentential form β!"))
  (let ((productions (parser-generator--get-grammar-productions))
        (k parser-generator--look-ahead-number))
    (let ((i-max (length productions)))

      ;; Generate F-sets only once per grammar
      (when (or
             (and
              (not disallow-e-first)
              (not parser-generator--f-sets))
             (and
              disallow-e-first
              (not parser-generator--f-free-sets)))
        (let ((f-sets (make-hash-table :test 'equal))
              (i 0))
          (while (< i i-max)
            (parser-generator--debug (message "i = %s" i))
            (let ((f-set (make-hash-table :test 'equal)))

              ;; Iterate all productions, set F_i
              (dolist (p productions)
                (let ((production-lhs (car p))
                      (production-rhs (cdr p)))
                  (parser-generator--debug
                   (message "Production: %s -> %s" production-lhs production-rhs))

                  ;; Iterate all blocks in RHS
                  (let ((f-p-set))
                    (dolist (rhs-p production-rhs)
                      (let ((rhs-string rhs-p))
                        (let ((rhs-leading-terminals
                               (parser-generator--f-set rhs-string `(,k ,i ,f-sets ,disallow-e-first) '(("" t 0)))))
                          (parser-generator--debug
                           (message "Leading %d terminals at index %s (%s) -> %s = %s" k i production-lhs rhs-string rhs-leading-terminals))
                          (when rhs-leading-terminals
                            (when (and
                                   (listp rhs-leading-terminals)
                                   (> (length rhs-leading-terminals) 0))
                              (dolist (rhs-leading-terminals-element rhs-leading-terminals)
                                (push rhs-leading-terminals-element f-p-set)))))))

                    ;; Make set distinct
                    (setq f-p-set (parser-generator--distinct f-p-set))
                    (parser-generator--debug
                     (message "F_%s_%s(%s) = %s" i k production-lhs f-p-set))
                    (puthash production-lhs (nreverse f-p-set) f-set))))
              (puthash i f-set f-sets)
              (setq i (+ i 1))))
          (if disallow-e-first
              (setq parser-generator--f-free-sets f-sets)
            (setq parser-generator--f-sets f-sets))))

      (parser-generator--debug
       (message "Generated F-sets"))

      (let ((first-list nil))
        ;; Iterate each symbol in β using a PDA algorithm
        (let ((input-tape β)
              (input-tape-length (length β))
              (stack '((0 0 nil))))
          (while stack
            (let ((stack-topmost (pop stack)))
              (parser-generator--debug
               (message "stack-topmost: %s" stack-topmost))
              (let ((input-tape-index (car stack-topmost))
                    (first-length (car (cdr stack-topmost)))
                    (first (car (cdr (cdr stack-topmost))))
                    (keep-looking t))
                (while (and
                        keep-looking
                        (< input-tape-index input-tape-length)
                        (< first-length k))
                  (let ((symbol (nth input-tape-index input-tape)))
                    (parser-generator--debug
                     (message "symbol index: %s from %s is: %s" input-tape-index input-tape symbol))
                    (cond
                     ((parser-generator--valid-terminal-p symbol)
                      (setq first (append first (list symbol)))
                      (setq first-length (1+ first-length)))

                     ((parser-generator--valid-non-terminal-p symbol)
                      (parser-generator--debug
                       (message "non-terminal symbol: %s" symbol))
                      (let ((symbol-f-set))
                        (if disallow-e-first
                            (setq symbol-f-set (gethash symbol (gethash (1- i-max) parser-generator--f-free-sets)))
                          (setq symbol-f-set (gethash symbol (gethash (1- i-max) parser-generator--f-sets))))
                        (parser-generator--debug
                         (message "symbol-f-set: %s" symbol-f-set))
                        (if (not symbol-f-set)
                            (progn
                              (parser-generator--debug
                               (message "empty symbol-f-set, so stop looking"))
                              (setq keep-looking nil))

                          ;; Handle this scenario here were a non-terminal can result in different FIRST sets
                          (when (> (length symbol-f-set) 1)
                            (let ((symbol-f-set-index 1)
                                  (symbol-f-set-length (length symbol-f-set)))
                              (while (< symbol-f-set-index symbol-f-set-length)
                                (let ((symbol-f-set-element (nth symbol-f-set-index symbol-f-set)))
                                  (let ((alternative-first-length (+ first-length (length symbol-f-set-element)))
                                        (alternative-first (append first symbol-f-set-element))
                                        (alternative-tape-index (1+ input-tape-index)))
                                    (parser-generator--debug
                                     (message "alternative-first: %s" alternative-first))
                                    (push `(,alternative-tape-index ,alternative-first-length ,alternative-first) stack)))
                                (setq symbol-f-set-index (1+ symbol-f-set-index)))))

                          (parser-generator--debug
                           (message "main-symbol-f-set: %s" (car symbol-f-set)))
                          (setq first-length (+ first-length (length (car symbol-f-set))))
                          (setq first (append first (car symbol-f-set))))))))
                  (setq input-tape-index (1+ input-tape-index)))
                (when (> first-length 0)
                  (parser-generator--debug
                   (message "push to first-list: %s to %s" first first-list))
                  (push first first-list))))))

        (setq first-list (sort first-list 'parser-generator--sort-list))
        first-list))))

;; Definition at p. 343
(defun parser-generator--follow (β)
  "Calculate follow-set of Β.  FOLLOW(β) = w, w is the set {w | S =>* αβγ and w is in FIRST(γ)}."
  ;; Make sure argument is a list
  (unless (listp β)
    (setq β (list β)))
  (let ((follow-set nil)
        (match-length (length β)))
    ;; Iterate all productions in grammar
    (let ((productions (parser-generator--get-grammar-productions)))
      (dolist (p productions)
        ;; Iterate all RHS of every production
        (let ((production-rhs (cdr p))
              (match-index 0))
          (dolist (rhs production-rhs)

            ;; Make sure RHS is a list
            (unless (listp rhs)
              (setq rhs (list rhs)))

            ;; Iterate every symbol in RHS
            (let ((rhs-count (length rhs))
                  (rhs-index 0))
              (while (< rhs-index rhs-count)
                (let ((rhs-element (nth rhs-index rhs)))

                  ;; Search for all symbols β in RHS
                  (if (eq rhs-element (nth match-index β))
                      ;; Is symbols exists in RHS
                      (progn
                        (setq match-index (1+ match-index))
                        (when (= match-index match-length)
                          (if (= rhs-index (1- rhs-count))
                              ;; If rest of RHS is empty add e in follow-set
                              (push `(,parser-generator--e-identifier) follow-set)
                            ;; Otherwise add FOLLOW(rest) to follow-set
                            (let ((rest (nthcdr (1+ rhs-index) rhs)))
                              (let ((first-set (parser-generator--first rest)))
                                (setq follow-set (append first-set follow-set)))))
                          (setq match-index 0)))
                    (when (> match-index 0)
                      (setq match-index 0))))
                (setq rhs-index (1+ rhs-index))))))))
    (when (> (length follow-set) 0)
      (setq follow-set (parser-generator--distinct follow-set)))
    follow-set))


(provide 'parser-generator)

;;; parser-generator.el ends here