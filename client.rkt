#lang racket/base

(require racket/tcp)
(require racket/unix-socket)

(when (< (vector-length (current-command-line-arguments)) 2)
  (eprintf "Usage: <program-name> <socket path or port> <command>")
  (exit 1))
(define cmd (string->symbol (vector-ref (current-command-line-arguments) 1)))
(unless (member cmd '(prompt))
  (eprintf "bad command: ~a~n" cmd)
  (exit 1))
(define path (vector-ref (current-command-line-arguments) 0))
(define port (string->number path))
(define p-or-p (or port path))
(define tcp? port)
(define connect (if tcp?
                    (λ (port) (tcp-connect "localhost" port))
                    unix-socket-connect))
(define-values (in-port out-port) (connect p-or-p))
(write cmd out-port)
(flush-output out-port)
(close-input-port in-port)
(close-output-port out-port)

(exit 0)

