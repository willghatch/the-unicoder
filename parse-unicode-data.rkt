#lang racket/base

(provide
 (struct-out unicode-data)
 unicodedata.txt->data-structs
 unicode-data-url
 )

(require
 racket/match
 racket/string
 racket/file
 )

;;; Info on what the fields are is here:
;;; http://www.unicode.org/Public//3.0-Update1/UnicodeData-3.0.1.html

(define unicode-data-url "http://www.unicode.org/Public/UNIDATA/UnicodeData.txt")

(struct unicode-data
  (char name general-category canonical-combining-classes
        bidirectional-category character-decomposition-mapping
        decimal-digit-value digit-value numeric-value
        mirrored unicode-1-name iso-comment-field
        uppercase-mapping lowercase-mapping titlecase-mapping
        )
  #:transparent)

(define (hex->char hs)
  (integer->char (string->number hs 16)))
(define (hex->char/maybe hs)
  (with-handlers ([(λ _ #t) (λ _ #f)])
    (hex->char hs)))

(define (data-line-list->unicode-data-struct dls)
  (match-let* ([(list-rest char name cat comb-class bidirect-cat
                           char-decomp-map decimal-digit-val digit-val
                           numeric-val mirrored old-name comment
                           uppercase lowercase titlecase-maybe)
                dls]
               [titlecase (if (null? titlecase-maybe)
                              #f
                              (hex->char (car titlecase-maybe)))]
               [(list char uppercase lowercase)
                (list (hex->char/maybe char)
                      (hex->char/maybe uppercase)
                      (hex->char/maybe lowercase))])
    (unicode-data char (string-downcase name) cat comb-class bidirect-cat
                  char-decomp-map decimal-digit-val digit-val
                  numeric-val mirrored (string-downcase old-name) comment
                  uppercase lowercase titlecase)))

(define (split-data-line line)
  (string-split line ";"))

(define (unicodedata.txt->data-structs filepath)
  ;; Filter out the characters that are "start/end of private range"
  ;; because Racket doesn't accept them.
  (filter (λ (ud) (unicode-data-char ud))
          (for/list ([line (file->lines filepath)])
            (data-line-list->unicode-data-struct
             (split-data-line line)))))

