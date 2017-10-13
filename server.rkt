#lang racket/base

(provide serve)

(require racket/class)
(require racket/tcp)
(require racket/file)
(require racket/unix-socket)
(require "prompter.rkt")

(define (serve port-or-path)
  (let* ([listener (if (number? port-or-path)
                       (tcp-listen port-or-path 4 #f "127.0.0.1")
                       (begin
                         (make-parent-directory* port-or-path)
                         (unix-socket-listen port-or-path)))]
         [tcp? (tcp-listener? listener)]
         [accept (if tcp?
                     tcp-accept
                     unix-socket-accept)]
         [close (if tcp?
                    tcp-close
                    (λ (listener)
                      (unix-socket-close-listener listener)
                      (when (path-string? port-or-path)
                        (delete-file port-or-path))))])
    (define (loop prompter)
      (let-values ([(in-port out-port) (accept listener)])
        ;; I should probably check for commands...
        (define command (read in-port))
        (close-input-port in-port)
        (close-output-port out-port)
        (case command
          [(prompt) (send prompter prompt)]
          [(reload) (loop (new unicode-prompter%))]
          [else (eprintf "Unrecognized command: ~a\n" command)])
        (loop prompter)
        ))
    (with-handlers ([(λ _ #t) (λ (e)
                                (close listener)
                                ((error-display-handler) "Error:" e))])
      (loop (new unicode-prompter%)))))

