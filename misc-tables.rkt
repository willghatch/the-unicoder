#lang racket/base

(provide (all-defined-out))

(define flag-table
  ;; TODO
  (hash))

(define sundry-table
  (hash
   ;; While Prince's name symbol isn't in unicode, a close approximation
   ;; for TAFKAP is capital letter t with hook, combining ring above,
   ;; combining short stroke overlay, and combining caron below.
   "the artist formerly known as prince" "\u01AC\u030A\u0335\u032C"
   ))
