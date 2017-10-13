#lang racket/base

(provide unicode-prompter%)
(provide prompt-once)

(require racket/system)
(require racket/gui/base)
(require racket/class)
(require racket/string)
(require racket/list)
(require racket/port)
(require racket/file)
(require mrlib/tex-table)
(require net/url)

(require "parse-unicode-data.rkt")
(require "user-tables.rkt")
(require "misc-tables.rkt")
(require "config.rkt")

(require basedir)
(current-basedir-program-name "the-unicoder")

(define latex-y-table
  (for/hash ([kv tex-shortcut-table])
    (values (first kv) (second kv))))

(define (hash-append ht . hts)
  (define (append-1 l r)
    (foldl (λ (pair carry) (hash-set carry (car pair) (cdr pair)))
           l
           (hash->list r)))
  (if (empty? hts)
      ht
      (apply hash-append (cons (append-1 ht (first hts)) (rest hts)))))

(define (unicode-data-path)
  (writable-data-file "UnicodeData.txt"))

(define (download-and-use-unicode-data)
  (eprintf "UnicodeData.txt not found, attempting download...\n")
  (let ([unicodedata-str (port->string
                          (get-pure-port
                           (string->url unicode-data-url)))])
    (if (good-download? unicodedata-str)
        (begin
          (make-directory* (writable-data-dir))
          (display-to-file unicodedata-str (unicode-data-path))
          (get-unicode-data))
        (error 'get-unicode-data-hash "Couldn't download UnicodeData.txt"))))

(define (good-download? data-string)
  ;; TODO - how should I check that this is good?
  ;; For now I'll just assume that if it's big it's the right file...
  (> (string-length data-string) 100000))

(define (get-unicode-data)
  (let ([filepath (unicode-data-path)])
    (if (file-exists? filepath)
        (unicodedata.txt->data-structs filepath)
        (download-and-use-unicode-data))))

(define (left-pad desired-length pad-char str)
  ;; Did somebody say "killer micro-library"?
  (let* ([len (string-length str)]
         [padding (make-string (max 0 (- desired-length len)) pad-char)])
    (string-append padding str)))

(define (get-unicode-desc-map)
  (let* ([data (get-unicode-data)]
         [name-table (for/hash ([ud data])
                       (values (unicode-data-name ud) ud))]
         [old-name-table
          (for/hash ([ud (filter
                          (λ (d) (< 0 (string-length
                                       (unicode-data-unicode-1-name d))))
                          data)])
            (values (unicode-data-unicode-1-name ud) ud))]
         [hex-table (for/hash ([ud data])
                      (values (left-pad 4 #\0
                                        (number->string
                                         (char->integer (unicode-data-char ud))
                                         16))
                              ud))])
    (hash-append hex-table
                 old-name-table
                 name-table
                 latex-y-table
                 flag-table
                 sundry-table
                 (hash "" "")
                 (apply hash-append (cons (hash) (get-user-config-tables))))))

(define (send-text t)
  ;; It might be nice to load up libxdo and do this in the same process
  (system* (or (find-executable-path "xdotool") (error 'the-unicoder "can't find executable `xdotool`.")) "type" t))

(define (stringify str-ish)
  (cond
    [(string? str-ish) str-ish]
    [(char? str-ish) (string str-ish)]
    [(unicode-data? str-ish) (string (unicode-data-char str-ish))]))


(define unicode-prompter%
  (class object%
    (field [desc-map (get-unicode-desc-map)])
    (field [desc-keys (hash-keys desc-map)])
    (init-field [num-options 10])

    (define (desc->charstr desc)
      (stringify (hash-ref desc-map desc)))
    (define (get-possible-unicode-descs desc)
      (define parts (string-split desc))
      (filter (λ (key) (for/and ([part parts])
                         (string-contains? key part)))
              desc-keys))
    (define (get-closest-unicode-descs desc)
      (let* ([options+ (get-possible-unicode-descs desc)]
             [len (length options+)]
             [options+sort (sort options+ < #:cache-keys? #t
                                 #:key (λ (d) (if (string-contains? d desc)
                                                  ;; I still want to prioritize shorter
                                                  ;; strings, among those that include
                                                  ;; the whole literal input.
                                                  (- (/ 1 (+ 1 (string-length d))))
                                                  (string-length d))))])
        (take options+sort (min num-options len))))
    (define (get-closest-unicode-char-str desc)
      (with-handlers ([(λ _ #t) (λ _ "")])
        (stringify (hash-ref desc-map (car (get-closest-unicode-descs desc))))))

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
        (sleep (send-delay))
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

(define (prompt-once)
  (send (new unicode-prompter%) prompt))

(module+ main
  (prompt-once))
