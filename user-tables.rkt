#lang racket/base

(require basedir)

(provide get-user-config-tables)
(define (get-user-config-tables)
  ;; This is a little awkwark.  There's probably a better way to read a file
  ;; and make sure it's closed properly.
  (filter
   hash?
   (for/list ([file (list-config-files "unicoder-table")])
       (with-handlers ([(λ _ #t) (λ _ #f)])
         (let ([port (open-input-file file)])
           (with-handlers ([(λ _ #t) (λ (e)
                                       (close-input-port port)
                                       (eprintf "error with config file: ~a\n~a"
                                                file
                                                e)
                                       #f)])
             (begin0 (read port) (close-input-port port))))))))

