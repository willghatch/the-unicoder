#lang racket/base

(require racket/tcp)

(define port 54321)
(define-values (in-port out-port) (tcp-connect "localhost" port))

(exit 0)

