(define-module ginfo.revert
  (extend ginfo)
  (export <revert-context> revert-doc))

(select-module ginfo.revert)

;;;;;
;;unitをテキスト文字列に戻すための変換コンテキスト
(define-class <revert-context> (<convert-context>) ())

(define (unescape-special-character text)
  (regexp-replace-all #/\\\"/ text "\""))

(define-method output ((context <revert-context>) (unit <unit-top>))
  (format #t ";;;;;\n")
  (format #t ";;@type ~a\n" (unescape-special-character (slot-ref unit 'type)))
  (format #t ";;@name ~a\n" (unescape-special-character (slot-ref unit 'name)))
  (unless (null? (slot-ref unit 'description))
    (format #t ";;@description ~a\n" (string-join (map unescape-special-character (slot-ref unit 'description)) "\n;;")))
  )

(define-method output ((context <revert-context>) (unit <unit-proc>))
  (next-method)
  (unless (null? (slot-ref unit 'param))
    (format #t "~a" (fold-right
                        (lambda (param acc)
                          (string-append ";;@param "
                                         (unescape-special-character (param-name param))
                                         " "
                                         (if (null? (param-acceptable param))
                                           ""
                                           (string-append "{@"
                                                          (string-join (map unescape-special-character (param-acceptable param)) " ")
                                                          "}"))
                                         (string-join (map unescape-special-character (param-description param)) "\n;;")
                                         "\n"
                                         acc))
                        ""
                        (slot-ref unit 'param))))
  (unless (null? (slot-ref unit 'return))
    (format #t ";;@return ~a\n" (string-join (map unescape-special-character (slot-ref unit 'return)) "\n;;")))
  (newline)
  )

(define-method output ((context <revert-context>) (unit <unit-var>))
  (next-method)
  (newline))

(define-method output ((context <revert-context>) (unit <unit-class>))
  (next-method)
  (unless (null? (slot-ref unit 'supers))
    (format #t ";;@supers ~a\n" (string-join (map unescape-special-character (slot-ref unit 'supers)) " ")))
  (unless (null? (slot-ref unit 'slots))
    (format #t "~a" (fold-right
                        (lambda (s acc)
                          (string-append ";;@slot "
                                         (unescape-special-character (param-name s))
                                         " "
                                         (if (null? (param-acceptable s))
                                           ""
                                           (string-append "{@"
                                                          (string-join (map unescape-special-character (param-acceptable s)) " ")
                                                          "}"))
                                         (string-join (map unescape-special-character (param-description s)) "\n;;")
                                         "\n"
                                         acc))
                        ""
                        (slot-ref unit 'slots))))
  (newline))

;;;;;
;;doc内のすべてのユニットを元のテキスト文字列に戻してポートに対して出力する
;;@param port 出力先のOutポート
(define (revert-doc doc port)
;;TODO argument check
  (output-for-each (make <revert-context> :port port) doc))

