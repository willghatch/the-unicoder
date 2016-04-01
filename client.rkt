#lang racket/base

(require racket/tcp)
(require racket/unix-socket)

(provide send-command)

(define (send-command path-or-port command)
  (let* ([tcp? (number? path-or-port)]
         [connect (if tcp?
                      (λ (port) (tcp-connect "localhost" port))
                      unix-socket-connect)])
    (define-values (in-port out-port) (connect path-or-port))
    (write command out-port)
    (flush-output out-port)
    (close-input-port in-port)
    (close-output-port out-port)))

