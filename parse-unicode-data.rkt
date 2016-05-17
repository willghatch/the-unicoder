#lang racket/base

(provide
 (struct-out unicode-data)
 unicodedata.txt->data-structs
 unicode-data-url
 )

(require
 racket/string
 racket/file
 )

;;; Info on what the fields are is here:
;;; http://www.unicode.org/Public//3.0-Update1/UnicodeData-3.0.1.html

(define unicode-data-url "http://www.unicode.org/Public/UNIDATA/UnicodeData.txt")

(struct unicode-data
  (char name unicode-1-name)
  #:transparent)

(define (hex->char hs)
  (integer->char (string->number hs 16)))
(define (hex->char/maybe hs)
  (with-handlers ([(λ _ #t) (λ _ #f)])
    (hex->char hs)))

(define (data-line-list->unicode-data-struct dls)
  (unicode-data (hex->char/maybe (list-ref dls 0))
                  (string-downcase (list-ref dls 1))
                  (string-downcase (list-ref dls 10))))

(define (split-data-line line)
  (string-split line ";"))

(define (unicodedata.txt->data-structs filepath)
  ;; Filter out the characters that are "start/end of private range"
  ;; because Racket doesn't accept them.
  (filter (λ (ud) (unicode-data-char ud))
          (for/list ([line (file->lines filepath)])
            (data-line-list->unicode-data-struct
             (split-data-line line)))))

