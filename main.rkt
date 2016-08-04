#lang racket/base

(module+ main
  (require racket/cmdline)
  (require racket/runtime-path)
  (require basedir)

  (define-runtime-path prompter.rkt "prompter.rkt")
  (define-runtime-path server.rkt "server.rkt")
  (define-runtime-path client.rkt "client.rkt")

  (define path-or-port (make-parameter #f))
  (define daemon (make-parameter #f))
  (define client (make-parameter #f))
  (define command (make-parameter 'prompt))

  (command-line
     #:program "the-unicoder"
     #:once-any
     [("--path") path "path to unix socket"
      (path-or-port path)]
     [("--port") port "TCP port number (discouraged)"
      (path-or-port (string->number port))]

     #:once-any
     [("--server") "run server"
      (daemon #t)]
     [("--client") "connect to server"
      (client #t)]
     #:once-each
     [("--command") cmd "command to send to the server"
      (command (string->symbol cmd))]
     )

  (when (and (not (path-or-port)) (or (daemon) (client)))
    (path-or-port (writable-runtime-file "the-unicoder-socket"
                                         #:program "the-unicoder")))

  (cond [(daemon) (let ([serve (dynamic-require server.rkt 'serve)])
                    (serve (path-or-port)))]
        [(client) (let ([send-command (dynamic-require client.rkt 'send-command)])
                    (send-command (path-or-port) (command)))]
        [else (let ([prompt-once (dynamic-require prompter.rkt 'prompt-once)])
                (prompt-once))])

  )

