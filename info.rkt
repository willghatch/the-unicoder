#lang info

(define deps '("base"
               "gui-lib"
               "unix-socket-lib"
               "xdg"))
(define build-deps '("scribble-lib"
                     "racket-doc"))
(define scribblings '(("doc.scrbl" () (tool))))

