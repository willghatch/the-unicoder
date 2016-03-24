#lang racket/base

(require racket/system)
(require racket/gui/base)
(require racket/class)
(require racket/string)
(require racket/list)
(require racket/runtime-path)
(require "parse-nameslist.rkt")

;; well this is awkward
(require "stolen-entity-names.rkt")
(define latex-y-table
  (for/hash ([key (hash-keys drracket-entity-table)])
    (values (symbol->string key)
            (string (integer->char (hash-ref drracket-entity-table key))))))

#;(define unicode-desc-map
  (hash
   "lambda" "λ"
   "alpha" "α"
   "unicorn" "🦄"
   "money" "💰"
   "smiley" "😀"
   ))
(define-runtime-path nameslist-file "NamesList.txt")
(define unicode-name-list-map (nameslist->hash nameslist-file))
(define unicode-desc-map (foldl (λ (key-pair h)
                                  (hash-set h (car key-pair) (cdr key-pair)))
                                latex-y-table
                                (hash->list unicode-name-list-map)))
(define unicode-desc-keys (hash-keys unicode-desc-map))
;; TODO - I need to allow custom name->character pairs
;; TODO - sort by: most frecent, custom, latex-style, largest % of matches (IE match the smaller description -- sometimes a long description will include all the words of a smaller one), character order
(define (desc->charstr desc)
  (hash-ref unicode-desc-map desc))

(define (get-possible-unicode-descs desc)
  (define parts (string-split desc))
  (filter (λ (key) (for/and ([part parts])
                       (string-contains? key part)))
            unicode-desc-keys))

(define num-options 10)

(define (get-closest-unicode-descs desc)
  (let* ([options+ (get-possible-unicode-descs desc)]
         [len (length options+)]
         [options+sort (sort options+ < #:cache-keys? #t
                             #:key (λ (d) (string-length d)))])
    (take options+sort (min num-options len))))

(define (get-closest-unicode-char-str desc)
  (hash-ref unicode-desc-map (car (get-closest-unicode-descs desc))))

(define (send-text t)
  ;; It might be nice to load up libxdo and do this in the same process
  (system* (find-executable-path "xdotool") "type" t))


(define (prompt-for-unicode)
  ;; Make a window, get a unicode selection, close the window, then send the text

  (define dialog (instantiate dialog% ("unicoder")))

  ; Add a text field to the dialog
  (define tf
    (new text-field% [parent dialog]
         [label "desired character"]
         [callback
          (λ (self event)
            (define (get-text)
              (send (send self get-editor) get-text))
            (if (equal? (send event get-event-type) 'text-field-enter)
                ;; do enter...
                (send-unicode (car (get-closest-unicode-descs (get-text))))
                (set-options (get-closest-unicode-descs (get-text)))))]))

  (define (send-unicode desc)
    (send dialog show #f)
    ;; sleep so that the window is gone before the text is sent
    ;; This is long enough that it should always work, but short enough
    ;; that it shouldn't be much of a bother to humans.
    (sleep 0.07)
    (send-text (desc->charstr desc))
    )

  (define options-list
    (new vertical-pane% [parent dialog]))

  (define (set-options desc-list)
    (for ([child (send options-list get-children)])
      (send options-list delete-child child))
    (for ([desc desc-list])
      (new message%
           [parent options-list]
           [label (format "~s ~a"
                          (desc->charstr desc)
                          desc)]
           )))

  (send tf focus)
  (send dialog show #t)
  )

(module+ main
  (prompt-for-unicode)
  )

