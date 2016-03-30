#lang racket/base

(require racket/tcp)
(require racket/unix-socket)

(define path (vector-ref (current-command-line-arguments) 0))
(define port (string->number path))
(define p-or-p (or port path))
(define tcp? port)
(define connect (if tcp?
                    (λ (port) (tcp-connect "localhost" port))
                    unix-socket-connect))
(define-values (in-port out-port) (connect p-or-p))
(write 'prompt out-port)
(flush-output out-port)
(close-input-port in-port)
(close-output-port out-port)

(exit 0)

