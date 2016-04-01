#lang racket/base

(require racket/class)
(require racket/tcp)
(require racket/unix-socket)

(require "prompter.rkt")




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
    (define (loop prompter)
      (let-values ([(in-port out-port) (accept listener)])
        ;; I should probably check for commands...
        (define command (read in-port))
        (close-input-port in-port)
        (close-output-port out-port)
        (case command
          [(prompt) (send prompter prompt)]
          [else (void)])
        (loop prompter)
        ))
    (with-handlers ([(λ _ #t) (λ (e)
                                (close listener)
                                ((error-display-handler) "Error:" e))])
      (loop (new unicode-prompter%)))))

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

;  (send-command (vector-ref (current-command-line-arguments) 0) 'prompt)
;  (exit 0)

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
        [else (send (new unicode-prompter%) prompt)])

  )

