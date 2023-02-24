#lang info

(define deps '("base"
               "gui-lib"
               ("unix-socket-lib" #:version "1.1")
               "tex-table"
               "basedir"))
(define build-deps '("scribble-lib"
                     "racket-doc"))
(define scribblings '(("the-unicoder.scrbl" () (tool))))
(define racket-launcher-names '("the-unicoder"))
(define racket-launcher-libraries '("main.rkt"))
(define license '(Apache-2.0 OR MIT))

