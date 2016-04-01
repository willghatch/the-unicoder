#lang racket/base

(provide unicode-prompter%)

(require racket/system)
(require racket/gui/base)
(require racket/class)
(require racket/string)
(require racket/list)
(require racket/runtime-path)

(require "parse-nameslist.rkt")
(require "user-tables.rkt")

;; well this is awkward
(require "stolen-entity-names.rkt")

(define latex-y-table
  (for/hash ([key (hash-keys drracket-entity-table)])
    (values (symbol->string key)
            (string (integer->char (hash-ref drracket-entity-table key))))))


(define-runtime-path nameslist-file "NamesList.txt")

(define (hash-append ht . hts)
  (define (append-1 l r)
    (foldl (λ (pair carry) (hash-set carry (car pair) (cdr pair)))
           l
           (hash->list r)))
  (if (empty? hts)
      ht
      (apply hash-append (cons (append-1 ht (first hts)) (rest hts)))))

(define (get-unicode-name-list-map) (nameslist->hash nameslist-file))
(define (get-unicode-desc-map)
  (hash-append (get-unicode-name-list-map)
               latex-y-table
               (hash "" "")
               (apply hash-append (cons (hash) (get-user-config-tables)))))

(define (send-text t)
  ;; It might be nice to load up libxdo and do this in the same process
  (system* (find-executable-path "xdotool") "type" t))

(define unicode-prompter%
  (class object%
    (field [desc-map (get-unicode-desc-map)])
    (field [desc-keys (hash-keys desc-map)])
    (init-field [num-options 10])

    (define (desc->charstr desc)
      (hash-ref desc-map desc))
    (define (get-possible-unicode-descs desc)
      (define parts (string-split desc))
      (filter (λ (key) (for/and ([part parts])
                         (string-contains? key part)))
              desc-keys))
    (define (get-closest-unicode-descs desc)
      (let* ([options+ (get-possible-unicode-descs desc)]
             [len (length options+)]
             [options+sort (sort options+ < #:cache-keys? #t
                                 #:key (λ (d) (string-length d)))])
        (take options+sort (min num-options len))))
    (define (get-closest-unicode-char-str desc)
      (with-handlers ([(λ _ #t) (λ _ "")])
        (hash-ref desc-map (car (get-closest-unicode-descs desc)))))


    (public prompt)
    (define (prompt)
      ;; Make a window, get a unicode selection, close the window, then send the text

      (define dialog (instantiate dialog% ("the-unicoder")))
      (define tf
        (new text-field% [parent dialog]
             [label "desired character"]
             [callback
              (λ (self event)
                (define (get-text)
                  (send (send self get-editor) get-text))
                (if (equal? (send event get-event-type) 'text-field-enter)
                    ;; do enter...
                    (send-text/close (get-closest-unicode-char-str (get-text)))
                    (set-options (get-closest-unicode-descs (get-text)))))]))

      (define (send-text/close text)
        (send dialog show #f)
        ;; sleep so that the window is gone before the text is sent
        ;; This is long enough that it should always work, but short enough
        ;; that it shouldn't be much of a bother to humans.
        (sleep 0.07)
        (send-text text))

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
                              desc)])))
      (send tf focus)
      (send dialog show #t))
    (super-new)
    ))

