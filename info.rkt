#lang info

(define deps '("base"
               "gui-lib"
               "unix-socket-lib"
               "xdg"))
(define build-deps '("scribble-lib"
                     "racket-doc"))
(define scribblings '(("the-unicoder.scrbl" () (tool))))
(define racket-launcher-names '("the-unicoder"))
(define racket-launcher-libraries '("main.rkt"))

