#lang racket/base

(require racket/tcp)

(define port 54321)
(define-values (in-port out-port) (tcp-connect "localhost" port))
(writeln 'prompt out-port)
(flush-output out-port)
(close-input-port in-port)
(close-output-port out-port)

(exit 0)

