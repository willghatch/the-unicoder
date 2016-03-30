#lang racket/base

(require racket/system)
(require racket/gui/base)
(require racket/class)
(require racket/string)
(require racket/list)
(require racket/runtime-path)
(require racket/tcp)
(require racket/unix-socket)
(require "parse-nameslist.rkt")

;; well this is awkward
(require "stolen-entity-names.rkt")
(define latex-y-table
  (for/hash ([key (hash-keys drracket-entity-table)])
    (values (symbol->string key)
            (string (integer->char (hash-ref drracket-entity-table key))))))

#;(define unicode-desc-map
  (hash
   "lambda" "λ"
   "alpha" "α"
   "unicorn" "🦄"
   "money" "💰"
   "smiley" "😀"
   ))
(define-runtime-path nameslist-file "NamesList.txt")
(define unicode-name-list-map (nameslist->hash nameslist-file))
(define unicode-desc-map (foldl (λ (key-pair h)
                                  (hash-set h (car key-pair) (cdr key-pair)))
                                latex-y-table
                                (hash->list unicode-name-list-map)))
(define unicode-desc-keys (hash-keys unicode-desc-map))
;; TODO - I need to allow custom name->character pairs
;; TODO - sort by: most frecent, custom, latex-style, largest % of matches (IE match the smaller description -- sometimes a long description will include all the words of a smaller one), character order
(define (desc->charstr desc)
  (hash-ref unicode-desc-map desc))

(define (get-possible-unicode-descs desc)
  (define parts (string-split desc))
  (filter (λ (key) (for/and ([part parts])
                       (string-contains? key part)))
            unicode-desc-keys))

(define num-options 10)

(define (get-closest-unicode-descs desc)
  (let* ([options+ (get-possible-unicode-descs desc)]
         [len (length options+)]
         [options+sort (sort options+ < #:cache-keys? #t
                             #:key (λ (d) (string-length d)))])
    (take options+sort (min num-options len))))

(define (get-closest-unicode-char-str desc)
  (hash-ref unicode-desc-map (car (get-closest-unicode-descs desc))))

(define (send-text t)
  ;; It might be nice to load up libxdo and do this in the same process
  (system* (find-executable-path "xdotool") "type" t))


(define (prompt-for-unicode)
  ;; Make a window, get a unicode selection, close the window, then send the text

  (define dialog (instantiate dialog% ("the-unicoder")))

  ; Add a text field to the dialog
  (define tf
    (new text-field% [parent dialog]
         [label "desired character"]
         [callback
          (λ (self event)
            (define (get-text)
              (send (send self get-editor) get-text))
            (if (equal? (send event get-event-type) 'text-field-enter)
                ;; do enter...
                (send-unicode (car (get-closest-unicode-descs (get-text))))
                (set-options (get-closest-unicode-descs (get-text)))))]))

  (define (send-unicode desc)
    (send dialog show #f)
    ;; sleep so that the window is gone before the text is sent
    ;; This is long enough that it should always work, but short enough
    ;; that it shouldn't be much of a bother to humans.
    (sleep 0.07)
    (send-text (desc->charstr desc))
    )

  (define options-list
    (new vertical-pane% [parent dialog]))

  (define (set-options desc-list)
    (for ([child (send options-list get-children)])
      (send options-list delete-child child))
    (for ([desc desc-list])
      (new message%
           [parent options-list]
           [label (format "~s ~a"
                          (desc->charstr desc)
                          desc)]
           )))

  (send tf focus)
  (send dialog show #t)
  )


(define (serve port-or-path)
  (let* ([listener (if (number? port-or-path)
                       (tcp-listen port-or-path 4 #f "127.0.0.1")
                       (unix-socket-listen port-or-path))]
         [tcp? (tcp-listener? listener)]
         [accept (if tcp?
                     tcp-accept
                     unix-socket-accept)]
         [close (if tcp?
                    tcp-close
                    (λ (listener)
                      (unix-socket-close-listener listener)
                      (when (path-string? port-or-path)
                        (delete-file port-or-path))))])
    (define (loop)
      (let-values ([(in-port out-port) (accept listener)])
        ;; I should probably check for commands...
        (define command (read in-port))
        (close-input-port in-port)
        (close-output-port out-port)
        (case command
          [(prompt) (prompt-for-unicode)]
          [else (void)])
        (loop)
        ))
    (with-handlers ([exn:break? (λ (e) (close listener))])
      (loop))))

(define (send-command path-or-port command)
  (let* ([tcp? (number? path-or-port)]
         [connect (if tcp?
                      (λ (port) (tcp-connect "localhost" port))
                      unix-socket-connect)])
    (define-values (in-port out-port) (connect path-or-port))
    (write 'prompt out-port)
    (flush-output out-port)
    (close-input-port in-port)
    (close-output-port out-port)))

(module+ main
  (require racket/cmdline)

  (define path-or-port (make-parameter #f))
  (define daemon (make-parameter #f))
  (define client (make-parameter #f))

  (define command
    (command-line
     #:program "the-unicoder"
     #:once-any
     [("--path") path "path to unix socket"
      (path-or-port path)]
     [("--port") port "TCP port number (discouraged)"
      (path-or-port (string->number port))]

     #:once-each
     [("--server") "run server"
      (daemon #t)]
     [("--client") "connect to server"
      (client #t)]
     #:args ([cmd 'prompt])
     cmd
     ))

  (when (and (not (path-or-port)) (or (daemon) (client)))
    (eprintf "Error: specify a path or port for clients and servers~n")
    (exit 1))

  (cond [(daemon) (serve (path-or-port))]
        [(client) (send-command (path-or-port) command)]
        [else (prompt-for-unicode)])

  )

