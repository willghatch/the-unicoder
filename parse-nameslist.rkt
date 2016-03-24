#lang racket/base

(require racket/file)
(require racket/string)

(define (getlines nl-file)
  (let ([all-lines (file->lines nl-file)])
    (filter (λ (line)
              (regexp-match #rx"^[0123456789ABCDEF]" line))
            all-lines)))


(define (lines-to-hash lines)
  (for/hash ([line lines])
    (let ([split (string-split line "\t")])
      (values (string-downcase (cadr split))
              (string (integer->char (string->number (car split) 16)))))))

(provide nameslist->hash)
(define (nameslist->hash filename)
  (lines-to-hash (getlines (expand-user-path filename))))


