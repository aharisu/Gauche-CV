(define-module ginfo
  (use srfi-1)  ;;filter
  (use srfi-11) ;;let-values
  (use srfi-13) ;;string util
  (use util.list)
  (use util.match)
  (use file.util)
  (use text.parse)
  (use gauche.parameter)
  #;(export <doc> <geninfo-warning> <convert-context>
    <unit-top> <unit-proc> <unit-var> <unit-class>
    unit-bottom-initializer-add! slot-update!
    output geninfo)
  (export-all)
  )

(select-module ginfo)

(define ignore-geninfo-warning? (make-parameter #f))

(define (guarded-read :optional (port (current-input-port)))
  (guard (exc [(<read-error> exc) (guarded-read)])
    (read port)))


;-------***************-----------
;data structure
;-------***************-----------

;;解析中に遭遇した例外を表すコンディションタイプ
(define-condition-type <geninfo-warning> <message-condition> #f)

;;;;;
;;documentのunitを変換するためのトップクラス
(define-class <convert-context> ()
  (
   (port :init-keyword :port)
   ))

;;;;;
;;一つのドキュメントを表すクラス
(define-class <doc> ()
  (
   (units :init-keyword :units :init-value '())
   (name :init-keyword :name)
   (extend :init-keyword :extend :init-value '())
   ))

(define (add-unit doc unit)
  (when unit
    (slot-set! doc 'units (cons unit (slot-ref doc 'units))))
  unit)

(define (add-extend! doc module)
  (slot-set! doc 'extend (cons module (slot-ref doc 'extend))))

(define (commit-doc doc)
  (slot-set! doc 'units (reverse (slot-ref doc 'units)))
  (slot-set! doc 'extend (reverse (slot-ref doc 'extend)))
  doc)


(define (keyword-replace keyword-list keyword replacer
                         :optional add-value)
  (guard (e [else (if (undefined? add-value)
                    keyword-list
                    (append keyword-list (list keyword add-value)))])
    (let1 value (get-keyword keyword keyword-list)
      (if replacer
        (let loop ([l keyword-list]
                   [acc '()])
          (if (eq? (car l) keyword)
            (append acc 
                    (list (car l) (replacer value))
                    (cddr l))
            (loop (cddr l) (append acc
                                   (list (car l) (cadr l))))))

        keyword-list))))

(define (description-constract description)
  (if (string-null? description)
    '()
    (map
      escape-special-character
      (string-split description "\n"))))

;;;;;
;;全てのドキュメントユニットの上位クラス
;; @slot name slot name
;; @slot type type name
(define-class <unit-top> ()
  (
   ;; Do you need to have <unit-top>?
   (cur-tag :init-value 'description)

   (name :init-keyword :name :init-value #f)
   (type :init-keyword :type :init-value #f)

   (description :init-keyword :description :init-value '())
   ))

(define-method initialize ((c <unit-top>) initargs)
  (let* ([initargs (keyword-replace initargs :name escape-special-character)]
         [initargs (keyword-replace initargs :description description-constract)])
    (next-method c initargs)))

(define (set-unit-name! unit name)
  (slot-set! unit 'name (escape-special-character name)))

(define (set-unit-description! unit description)
  (slot-set! unit 'description (description-constract description)))

(define (reverse-and-escape-character l)
  (let loop ([t l]
             [acc '()])
    (if (null? t)
      acc
      (loop (cdr t) (cons (escape-special-character (car t))
                          acc)))))

(define-macro (define-special-initialize class type . body)
  `(define-method initialize ((c ,class) initargs)
     (let ([initargs (keyword-replace initargs :type #f ,type)])
       ,@body
       (next-method c initargs))))

;;<unit-bottom>の各スロットから値をコピーする
;;これ以降unitを編集することはない
(define-method commit ((unit <unit-top>) original)
  (slot-set! unit 'name (escape-special-character (slot-ref original 'name)))
  (slot-set! unit 'type (escape-special-character (slot-ref original 'type)))
  (slot-set! unit 'description (reverse-and-escape-character (slot-ref original 'description)))
  unit)

(define-method show ((unit <unit-top>))
  (format #t "type: ~S\n" (slot-ref unit 'type))
  (format #t "name: ~S\n" (slot-ref unit 'name))
  (format #t "description: ~S\n" (slot-ref unit 'description)))


;;unit-bottomクラスのためのメタクラス
;;全てのユニットクラスの下位クラスとして扱えるようにする
(define-class <unit-bottom-meta> (<class>) ())

;;スロットが見つからなかった場合はハッシュテーブル内からget or setする
(define-method slot-missing ((class <unit-bottom-meta>) obj slot . value)
  (if (null? value)
    (cond ;get
      [(hash-table-exists? (slot-ref obj '%slots) slot)
       (hash-table-get (slot-ref obj '%slots) slot)]
      [else (next-method)])
    (begin  ;set
      (hash-table-put! (slot-ref obj '%slots) slot (car value))
      (slot-set! obj 'initial-state? #f)
      (undefined))))

;;;;;
;;スロットに対する更新関数
;;ユニットオブジェクトのスロットに対する更新はこの関数を利用する
(define (slot-update! obj slot f)
  (cond
    [(find (lambda (s) (eq? (car s) slot)) (class-slots (class-of obj)))
     (slot-set! obj slot (f (slot-ref obj slot)))]
    [else (hash-table-update! (slot-ref obj '%slots) slot f)
      (slot-set! obj 'initial-state? #f)]))

;;全てのドキュメントユニットの下位クラス
;;存在しないスロットもハッシュテーブルとして持つことで疑似的に下位クラスのように扱う
;;method not support
(define-class <unit-bottom> (<unit-top>)
  (
   (%slots :init-value (make-hash-table))
   (initial-state?)
   )
  :metaclass <unit-bottom-meta>)

;;;;;
;;unit-bottom初期化用関数
;;unit-bottomの疑似スロットに対してmake時に初期化する必要があるものはこのタイミングで行う
(define unit-bottom-initializer '())
(define (unit-bottom-initializer-add! proc)
  (set! unit-bottom-initializer (cons proc unit-bottom-initializer)))

(define-method initialize ((class <unit-bottom>) initargs)
  (let1 ret (next-method)
    (for-each
      (lambda (proc) (proc ret initargs))
      unit-bottom-initializer)
    (slot-set! ret 'initial-state? #t)
    ret))

(define (initial-state? unit)
  (if (is-a? unit <unit-bottom>)
    (not (or (slot-ref unit 'name)
           (slot-ref unit 'type)
           (not (zero? (length (slot-ref unit 'description))))
           (not (slot-ref unit 'initial-state?))))
    #f))

(define-method show ((unit <unit-bottom>))
  (next-method)
  (hash-table-for-each
    (slot-ref unit '%slots)
    (lambda (key value)
      (print key ":" value))))

;;;;;
;;functionやmethodタイプ用のunit
(define-class <unit-proc> (<unit-top>)
  (
   (param :init-value '())
   (return :init-value '())
   ))

(define-special-initialize <unit-proc> type-fn)

(define-method add-unit-param! ((unit <unit-bottom>) 
                                name :key (acceptable '())
                                (description ""))
  (slot-set! unit 'param
             (append
               (slot-ref unit 'param)
               (cons
                 (list
                   (escape-special-character name)
                   (escape-special-character name)
                   (map escape-special-character acceptable)
                   (description-constract description))
                 '()))))

(define-method add-unit-param! ((unit <unit-proc>) 
                                name :key (acceptable '())
                                (description ""))
  (slot-set! unit 'param
             (append
               (slot-ref unit 'param)
               (cons
                 (list
                   (escape-special-character name)
                   (map escape-special-character acceptable)
                   (description-constract description))
                 '()))))

(define (set-unit-return! unit description)
  (slot-set! unit 'return (description-constract description)))

(define (param-name param)
  (car param))
(define (param-acceptable param)
  (cadr param))
(define (param-description param)
  (caddr param))

(define-method commit ((unit <unit-proc>) original)
  (next-method)
  ;(slot-set! unit 'description (reverse (slot-ref original 'description)))
  (slot-set! unit 'return (reverse-and-escape-character (slot-ref original 'return)))
  ;;この時点で(hidden new (accept1 accept2 ...) (text1 text2 ...))のリスト構造から
  ;;(new (accept1 accept2 ...) (text1 text2 ...))のリスト構造に修正する
  ;;hiddenとnewは自動解析結果の引数名を手動で修正するためにある
  (slot-set! unit 'param (map 
                           (lambda (p)(list (escape-special-character (cadr p))
                                            (reverse-and-escape-character (caddr p))
                                            (reverse-and-escape-character (cadddr p))))
                           (reverse (slot-ref original 'param))))
  unit)

(unit-bottom-initializer-add! 
  (lambda (unit initargs)
    (slot-set! unit 'param '())
    (slot-set! unit 'return '())))

(define-method show ((unit <unit-proc>))
  (next-method)
  (format #t "param: ~S\n" (slot-ref unit 'param))
  (format #t "return: ~S\n" (slot-ref unit 'return)))


;;;;;
;;var、constant、parameterタイプ用のunit
(define-class <unit-var> (<unit-top>) () )

(define-special-initialize <unit-var> type-var)

;;;;;
;;classタイプ用のunit
(define-class <unit-class> (<unit-top>)
  (
   (supers :init-value '())
   (slots :init-value '())
   )
  )

(define-special-initialize <unit-class> type-class)

(define-method add-unit-slot! ((unit <unit-bottom>)
                               name :key (acceptable '())
                               (description ""))
  (slot-set! unit 'slots
             (append
               (slot-ref unit 'slots)
               (cons
                 (list
                   (escape-special-character name)
                   (escape-special-character name)
                   (map escape-special-character acceptable)
                   (description-constract description))
                 '()))))


(define-method add-unit-slot! ((unit <unit-class>)
                        name :key (acceptable '())
                        (description ""))
  (slot-set! unit 'slots
             (append
               (slot-ref unit 'slots)
               (cons
                 (list
                   (escape-special-character name)
                   (map escape-special-character acceptable)
                   (description-constract description))
                 '()))))

(define (set-unit-supers! unit supers)
  (slot-set! unit 'supers (map escape-special-character supers)))

(define-method commit ((unit <unit-class>) original)
  (next-method)
  (slot-set! unit 'supers (reverse-and-escape-character (slot-ref original 'supers)))
  (slot-set! unit 'slots (map
                           (lambda (s) (list (escape-special-character (car s))
                                             (reverse-and-escape-character (caddr s))
                                             (reverse-and-escape-character (cadddr s))))
                           (reverse (slot-ref original 'slots))))
  unit)

(unit-bottom-initializer-add!
  (lambda (unit initargs)
    (slot-set! unit 'supers '())
    (slot-set! unit 'slots '())))

(define-method show ((unit <unit-class>))
  (next-method)
  (format #t "supers: ~S\n" (slot-ref unit 'supers))
  (format #t "slots: ~S\n" (slot-ref unit 'slots)))



(define-macro (or-equal? x . any)
  `(or ,@(map (lambda (y) `(equal? ,x ,y)) any)))
;;unit-bottomからtypeにあったunitクラスに変換する
;;TODO この関数を外側からも拡張可能にする
(define (spcify-unit type unit)
  (commit (cond
            [(or-equal? type type-fn type-method type-macro) (make <unit-proc>)]
            [(or-equal? type type-var type-const type-parameter) (make <unit-var>)]
            [(or-equal? type type-class) (make <unit-class>)]
            [else (raise (condition (<geninfo-warning> (message "unkown document unit type"))))]) ;TODO warning
          unit))


;;unitのプロパティへのアクセサ関数群
(define (get-tag unit) (slot-ref unit 'cur-tag))
(define (set-tag tag unit) (slot-set! unit 'cur-tag tag))

(define (set-unit-name name config unit)
  (if ((get-allow-multiple "name") config unit)
    ((get-init 'name) name config unit))
  unit)

(define (set-unit-type type config unit)
  (if ((get-allow-multiple "type") config unit)
    ((get-init 'type) type config unit))
  unit)

(define (append-text text config unit)
  ((get-appender (get-tag unit)) text config unit)
  unit)

(define (valid-unit? unit)
  (and (slot-ref unit 'name) (slot-ref unit 'type)))

(define (get-invalid-unit-reason unit)
  (string-append "invalid reason"
                 (if (slot-ref unit 'name) "" " [no specification of a name]")
                 (if (slot-ref unit 'type) "" " [no specification of a type]")))

(define (commit-unit config unit)
  (cond
    [(and (slot-ref unit 'type) (equal? (slot-ref unit 'type) type-cmd)) #f]
    [(valid-unit? unit) (spcify-unit (slot-ref unit 'type) unit)]
    [else (raise (condition
                   (<geninfo-warning> (message (get-invalid-unit-reason unit)))))]))


;-------***************-----------
;;parse document
;-------***************-----------
(define (x->writable-string x)
  (if (and (pair? x) (not (list? x)))
    (x->string (cell->list x)) ; dotted pair
    (match x 
      [(? string? x) (string-append "\"" x "\"")]
      ;[(symbol? x) (string-append "'" (symbol->string x))]
      [(? keyword? x) (string-append ":" (keyword->string x))]
      [('quote x) (string-append "'" (x->writable-string x))]
      [(? list? x) (string-append "(" 
                                  (string-trim-right
                                    (fold-right
                                      (lambda (x acc) (string-append (x->writable-string x) " " acc))
                                      ""
                                      x))
                                  ")")]
      [_ (x->string x)])))

(define tags '())

(define-macro (define-tag name allow-multiple? init appender)
  `(set! tags (acons (symbol->string (quote ,name)) 
                     (cons ,allow-multiple? (cons ,init ,appender))
                     tags)))

(define (get-allow-multiple tag)
  (cond 
    [(assoc-ref tags (x->string tag)) => car]
    [else #f]))
(define (get-init tag)
  (cond 
    [(assoc-ref tags (x->string tag)) => cadr]
    [else #f]))
(define (get-appender tag)
  (cond
    [(assoc-ref tags (x->string tag)) => cddr]
    [else #f]))

(define (tag-allow-multiple-ret-true config unit) #t)

(define (tag-init first-line config unit) first-line)

(define (tag-append-text tag) 
  (lambda (text config unit)
    (slot-update! unit tag (lambda (value) (cons text value)))))

(define (split-first-token line)
  (let1 m (rxmatch #/^\s*\.(?!\.)(.*)$/ line)
    (if m
      ;;param name is "."
      (list "." "." (string-trim (m 1)))
      (let ([port (open-input-string line)])
        (let ([first (guard (e
                              [(<read-error> e) 
                               (raise (condition
                                        (<geninfo-warning> (message (format #f "name syntax error. [~s]" line)))))])
                       (read port))])
          (if (eof-object? first)
            #f
            (append (match first
                      [(hidden '>> new) (list (x->writable-string hidden) (x->writable-string new))]
                      [sym (list (x->writable-string sym) (x->writable-string sym))])
                    (cons (string-trim (port->string port)) '()))))))))


;;define @description tag
(define-tag description
            tag-allow-multiple-ret-true
            tag-init
            (tag-append-text 'description))

(define (process-acceptable-input text slot config unit)
  (case (slot-ref unit 'state)
    [(0) 
     (let1 text (string-trim text)
       (if (string-null? text)
         #f
         (if (and (<= 2 (string-length text))
               (string=? "{@" (substring text 0 2)))
           (begin
             (slot-set! unit 'state 1)
             (process-acceptable-input (substring text 2 (string-length text)) slot config unit))
           (begin
             (slot-set! unit 'state 2)
             (process-acceptable-input text slot config unit)))))]
    [(1) 
     (let1 texts (string-split (string-trim-both text) #[\s])
       (let loop ([texts texts])
         (let* ([token (car texts)]
                [found (string-scan token #\})])
           (if found
             ;;finish
             (let1 before (substring token 0 found)
               (unless (string-null? before)
                 (slot-update! unit slot
                               (lambda (value)
                                 (set-car! (cddr (car value))
                                           (cons before (caddr (car value))))
                                 value)))
               (slot-set! unit 'state 2)
               (let1 text (string-trim (string-scan text #\} 'after))
                 (process-acceptable-input (and (not (string-null? text)) text)
                                           slot config unit)))
             ;;add acceptable
             (let1 token (string-trim-both token)
               (unless (string-null? token)
                 (slot-update! unit slot
                               (lambda (value)
                                 (set-car! (cddr (car value))
                                           (cons token (caddr (car value))))
                                 value)))
               (if (null? (cdr texts))
                 #f
                 (loop (cdr texts))))))))]
    [(2)  text]))

;;define @param tag
(define-tag param
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (slot-set! unit 'state 0)
              (cond
                [(split-first-token first-line) 
                 => (lambda (tokens)
                      (slot-update! unit 'param 
                                    (lambda (v)
                                      (cons 
                                        (list (car tokens) (cadr tokens) '() '())
                                        v)))
                      (caddr tokens))]
                [else (raise (condition (<geninfo-warning> (message "param name is required"))))]))
            (lambda (text config unit)
              (cond
                [(process-acceptable-input text 'param config unit) 
                 => (lambda (text)
                      (slot-update! unit 'param 
                                    (lambda (value)
                                      (set-car! (cdddr (car value)) (cons text (cadddr (car value))))
                                      value)))])))

;;define @return tag
(define-tag return
            (lambda (config unit) (null? (slot-ref unit 'return)))
            tag-init
            (tag-append-text 'return))


;;define @slot tag
(define-tag slot
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (slot-set! unit 'state 0)
              (cond
                [(split-first-token first-line)
                 => (lambda (tokens)
                      (slot-update! unit 'slots (lambda (v) (cons (list (car tokens) #f '() '()) v)))
                      (caddr tokens))]
                [else (raise (condition (<geninfo-warning> (message "slot name is required"))))]))
            (lambda (text config unit)
              (cond 
                [(process-acceptable-input text 'slots config unit)
                 => (lambda (text) 
                      (slot-update! unit 'slots
                                    (lambda (v)
                                      (set-car! (cdddr (car v)) (cons text (cadddr (car v))))
                                      v)))])))

;;define @supers tag
(define-tag supers
            (lambda (config unit) (null? (slot-ref unit 'return)))
            tag-init
            (lambda (text config unit)
              (slot-update! unit 'supers
                            (lambda (value)
                            (fold
                              (lambda (t acc)
                                (if (string-null? t)
                                  acc
                                  (cons t acc)))
                              value
                            (string-split text #[\s]))))))


;;define @name tag
(define-tag name
            (lambda (config unit) (not (slot-ref unit 'name)))
            (lambda (first-line config unit)
              (let ([name (guard (e [(<read-error> e) 
                                     (raise (condition 
                                              (<geninfo-warning> (message #`"could not parse name [,first-line]"))))])
                            (read (open-input-string first-line)))])
                (if (eof-object? name)
                  (raise (condition (<geninfo-warning> (message "@name tag required document unit name"))))
                  (slot-set! unit 'name (x->string name)))
                ""))
            (lambda (text config unit) (slot-set! unit 'name text)))


;;define @type tag
(define-constant type-fn "Function")
(define-constant type-var "var")
(define-constant type-method "Method")
(define-constant type-macro "Macro")
(define-constant type-const "Constant")
;Parameterは自動解析無理なので指定したいのなら自分で書いてね
(define-constant type-parameter "Parameter")
(define-constant type-class "Class")

;;cmdをtypeに手動設定するとそのユニットはドキュメントに追加されない
;;@@で始まるタグのみのユニットなどに設定する
(define-constant type-cmd "cmd")

(define-constant allow-types 
  `(
    ,type-fn
    ,type-var
    ,type-method
    ,type-macro
    ,type-const
    ,type-parameter
    ,type-class
    ,type-cmd
    ))
(define-tag type
            (lambda (config unit) (not (slot-ref unit 'type)))
            (lambda (first-line config unit)
              (let ([type (guard (e [(<read-error> e) 
                                     (raise (condition 
                                              (<geninfo-warning> (message #`"could not parse type name [,first-line]"))))])
                            (read (open-input-string first-line)))])
                (if (eof-object? type)
                  (raise (condition (<geninfo-warning> (message "@type tag required type name"))))
                  (let ([type (x->string type)])
                    (if (find (lambda (x) (string=? type x)) allow-types)
                      (slot-set! unit 'type type))))
                ""))
            (lambda (text config unit) (undefined)))


;;------------
;;@@で始まるタグはドキュメント解析動作にかかわるプロパティ設定を行うためのタグ
;;------------

;;define @@parse-relative tag
;;@@parse-relative #fに設定すると関連定義式の自動解析が行われない
;;default: #t
(define-tag @parse-relative
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (let ([parse? (guard (e [(<read-error> e) #t])
                              (read (open-input-string first-line)))])
                (if (or (eof-object? parse?) (not (boolean? parse?)))
                  (raise (condition (<geninfo-warning> (message "@parse-relative tag value selection is #t or #f"))))
                  (set-config config 'skip-relative (not parse?)))
                ""))
            (lambda (text config unit) (undefined)))

;;define @@class-c->scm
;;@@class-c->scm stubファイル用.Cレベルのクラス名とGaucheレベルのクラス名を関連付ける
;;format: c-class-name scm-class-name
(define-tag @class-c->scm
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (let ([c-scm (string-split first-line #[\s])])
                (unless (eq? (length c-scm) 2)
                  (raise (condition (<geninfo-warning>
                                      (message "@@class-c->scm tag format is ''c-class-name scm-class-name''.")))))
                (put-class-c->scm config (car c-scm) (cadr c-scm)))
              "")
            (lambda (text config unit) (undefined)))

;;次の有効なドキュメントテキストを取得する
;;有効なドキュメントテキストがなければ#fを返す
(define (next-doc-text)
  (if (not (zero? (string-length (string-trim (next-token-of '(#\space #\tab #\;))))))
    (let ([line (read-line)])
      (if (zero? (string-length line))
        (next-doc-text) ;; read next line
        line))
    #f))

;;ドキュメントタグと本文を分解する
;;example: "@return hoge piyo" -> {"return" "hoge piyo"}
(define (split-tag-and-text token)
  (cond [(string-scan token #\space)
         => (lambda (index)
              (values
                (substring token 1 index)
                (substring token (+ index 1) (string-length token))))]
    [else (values
            (substring token 1 (string-length token))
            "")]))

;;次のタグかドキュメントの終わりまで本文のテキストをスキップする
(define (skip-current-tag)
  (let ([org-fp (port-seek (current-input-port) 0 SEEK_CUR)])
    (if (not (zero? (string-length (string-trim (next-token-of '(#\space #\tab #\;))))))
      (let ([line (read-line)])
        (if (zero? (string-length line))
          skip-current-tag) ; read next line
        (if (eq? #\@ (string-ref line 0))
          ;;return to origin point file pointer
          (port-seek (current-input-port) 
                     (- org-fp (port-seek (current-input-port) 0 SEEK_CUR))
                     SEEK_CUR)
          (skip-current-tag)))))) ; read next line

;;テキスト内にタグがあれば処理を行う
(define (process-tag text config unit)
  (if (eq? #\@ (string-ref text 0))
    (let-values ([(tag text) (split-tag-and-text text)])
      (cond 
        [(get-allow-multiple tag) 
         => (lambda (pred) 
              (if (pred config unit)
                (begin
                  (set-tag (string->symbol tag) unit)
                  ((get-init tag) text config unit))
                #f))]
        [else (raise (condition
                       (<geninfo-warning> (message #`"unkwon tag name [,tag]."))))]))
    text))

(define (escape-special-character text)
  (regexp-replace-all #/"/ text "\\\\\""))
;;テキストを現在のタグ内に追加する
(define (process-text text config unit)
  (if (not (string-null? text))
    (append-text text config unit))
  unit)

;;一つのドキュメントを最後までパースする
(define (parse-doc config unit)
  (cond 
    [(next-doc-text)
     => (lambda (text) 
          (parse-doc config (cond 
                              [(process-tag text config unit)
                               => (lambda (text) (process-text text config unit))]
                              ;;TODO Warning
                              [else (skip-current-tag) unit])))];skip tag text
    [else unit]))


;;------***************-----------
;;analyze define expression
;-------***************-----------

(define (cell->list args)
  (define (c->l args c)
    (cond 
      [(pair? (cdr args))
       (c->l (cdr args) (cons (car args) c))]
      [(null? (cdr args))
       (reverse (cons (car args) c))]
      [else (reverse (append
                       (list (cdr args) (string->symbol ".") (car args))
                       c))]))
  (cond
    [(null? args) args]
    [(symbol? args) (list '|.| args)]
    [else (c->l args  '())]))


;;仮引数部をマッチングしながら再帰的に解析する
(define (parse-each-arg args func-get-var config)
  (let ([unit (make <unit-bottom>)]
        [init (get-init 'param)])
    (let loop ([args (cell->list args)])
      (match args
        [(:optional spec ...) 
         (init ":optional" config unit)
         (loop spec)]
        [(:key spec ...) 
         (init ":key" config unit)
         (loop spec)]
        [(:allow-other-keys spec ...)
         (init ":allow-other-keys" config unit)
         (loop spec)]
        [(:rest var spec ...)
         (init ":rest" config unit)
         (init (symbol->string (func-get-var var)) config unit)
         (loop spec)]
        [(((keyword var) init-exp) spec ...) 
         (init 
           #`"((,(x->writable-string keyword) ,(x->writable-string (func-get-var var))) ,(x->writable-string init-exp))"
           config unit)
         (loop spec)]
        [((var init-exp) spec ...) 
         (init #`"(,(symbol->string (func-get-var var)) ,(x->writable-string init-exp))" config unit)
         (loop spec)]
        [(var args ...) 
         (init (symbol->string (func-get-var var)) config unit)
         (loop args)]
        [() (slot-ref unit 'param)]))))


;;lambda式の仮引数部を解析する
;;さらに手書きparamのドキュメントとマージする
(define (analyze-args args func-get-var config unit)
  (let ([org-param (slot-ref unit 'param)]
        [gen-param (parse-each-arg args func-get-var config)])
    (for-each
      (lambda (p) 
        (cond
          [(assoc (car p) gen-param)
           => (lambda (param) (set-cdr! param (cdr p)))]
          [else (print "analyze-args warning. " (ref unit 'name) ":" (car p))])) ;TODO warging
      org-param)
    (slot-set! unit 'param gen-param)))


;;define, define-constantの解析を行う
(define (analyze-normal-define l config unit doc)
  (let ([constant? (eq? (car l) 'define-constant)]
        [type (if (eq? (car l) 'define-macro) type-macro type-fn)])
    (match l
      [(_ (symbol args ...) _ ...) ;; lambda -> function
       (set-unit-name (symbol->string symbol) config unit)
       (set-unit-type type config unit) 
       (analyze-args args identity config unit)]

      [(_ symbol first-exp exp ...) 
       (if (pair? symbol)
         (begin
           (set-unit-name (symbol->string (car symbol)) config unit)
           (set-unit-type type config unit)
           (analyze-args (cdr symbol) identity config unit))
         (begin
           (set-unit-name (symbol->string symbol) config unit)
           (match first-exp
             [(or ('lambda (args ...) _ ...) ;; lambda -> function
                ('^ (args ...) _ ...))
              (set-unit-type type config unit)
              (analyze-args args identity config unit)]
             [(or ('lambda arg _ ...) ;; lambda -> function
                ('^ arg _ ...))
              (set-unit-type type config unit)
              (analyze-args (list :rest arg) identity config unit)]
             [_ (set-unit-type (cond
                                 [(eq? type type-macro) type-macro]
                                 [constant? type-const]
                                 [else type-var]) 
                               config unit)])))];; other -> var or constant
      [(_) #f])))

;;stub用 parseing for define-enum
(define (analyze-stub-define-enum l config unit doc)
  (when (null? (cdr l))
    #f) ;TODO warning
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-const config unit))


;;define-methodの解析を行う
;;TODO エラー処理
(define (analyze-method-define l config unit doc)
  (if (null? (cdr l))
    #f);TODO warning
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-method config unit)
  (if (null? (caddr l))
    #f);TODO warning
  (analyze-args (caddr l) identity config unit))


(define (convert-type type)
  (let ([conv '(
                (<void> . "#<undefined>")
                )])
    (cond
      [(assq-ref conv type #f) => identity]
      [else (symbol->string type)])))


;;stub用 define-cprocの解析を行う
;;TODO エラー処理
(define (analyze-stub-proc-define l config unit doc)
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-fn config unit)
  (analyze-args (caddr l) 
                (lambda (var)(string->symbol (car (string-split (symbol->string var) "::"))))
                config unit)
  (let ([ret (if (string=? (x->string (cadddr l)) ":")
               (car (cddddr l))
               (string->symbol (string-drop (x->string (cadddr l)) 1)))])
    (slot-update! unit 'return
                  (lambda (v)
                    (append v (cons (if (list? ret)
                                      (string-append (fold
                                                       (lambda (type acc)
                                                         (string-append acc 
                                                                        " "
                                                                        (convert-type type)))
                                                       "(values"
                                                       ret)
                                                     ")")
                                      (convert-type ret))
                                    '()))))))

;;クラスのslot定義部分を解析
;;さらに手書きのslotドキュメントとマージする
(define (analyze-slots slots unit)
  (let ([org-slots (slot-ref unit 'slots)]
        [gen-slots (map 
                     (lambda (s)
                       (list (symbol->string (car s))
                             #f
                             '()
                             '()))
                     slots)])
    (for-each
      (lambda (s)
        (cond
          [(assoc (car s) gen-slots)
           => (lambda (slot) 
                (set-car! (cdr slot) (cadr s))
                (set-car! (cddr slot) (caddr s))
                (set-car! (cdddr slot) (cadddr s)))]
          [else (print "analyze-slots warning. " (car s))]))
      org-slots)
    gen-slots))


;;defime-classの解析を行う
(define (analyze-class-define l config unit doc)
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-class config unit)
  (slot-set! unit 'supers (map x->string (reverse (caddr l))))
  (slot-set! unit 'slots (analyze-slots (cadddr l) unit)))

;;stub用 define-cclassの解析を行う
(define (analyze-stub-class-define l config unit doc)
  (define (to-class hash class)
    (if hash 
      (hash-table-get hash class #f)
      #f))
  (let-values ([(supers slots) (let loop ([e l])
                                 (if (list? (car e))
                                   (values (car e) (cadr e))
                                   (loop (cdr e))))]
               [(classes) (get-config config 'stub-class)])
    (set-unit-name (symbol->string (cadr l)) config unit)
    (set-unit-type type-class config unit)
    (slot-set! unit 'supers (map
                              (lambda (x)
                                (cond
                                  [(to-class classes x) => identity]
                                  [else (raise (condition
                                                 (<geninfo-warning> (message "super class is not found"))))]))
                              (reverse supers)))
    (slot-set! unit 'slots (analyze-slots slots unit))))


(define (analyze-condition-class-define l config unit doc)
  (match l
    [(_ (? symbol? name) (? symbol? super) pred field ...)
     (let1 name (symbol->string name) 
       (set-unit-name name config unit)
       (set-unit-type type-class config unit)
       (slot-set! unit 'supers (cons (symbol->string super) '()))
       (when (symbol? pred)
         (let1 pred-unit (make <unit-proc> 
                               :name (symbol->string pred)
                               :description (string-append "type predicate for " name))
           (add-unit-param! pred-unit "e")
           (set-unit-return! pred-unit 
                             (string-append
                               "#t if an instance of " name
                               ", otherwise #f."))
           (add-unit doc pred-unit)))
       (for-each
         (lambda (spec)
           (match spec
             [((? symbol? slot)) 
              (add-unit-slot! unit (symbol->string slot))]
             [((? symbol? slot) (? symbol? accessor))
              (add-unit-slot! unit (symbol->string slot))
              (let1 unit (make <unit-proc>
                               :name (symbol->string accessor)
                               :description (string-append "slot accessoor for " name))
                (add-unit-param! unit "e")
                (add-unit doc unit))]
           [_ #f]))
         field))]
    [(_) #f]))

(define (analyze-module-define l config unit doc)
  (match l
    [(_ (? (lambda (exp) 
             (and (symbol? exp) (eq? exp (get-config config 'name))))
           m) spec ...)
     (for-each
       (lambda (exp)
         (match exp
           [('extend module-name ...)
            (for-each
              (lambda (module)
                (when (symbol? module)
                  (add-extend! doc module)))
              module-name)]
           [_ #f]))
       spec)]
    [_ #f]))

(define (analyze-extend l config unit doc)
  (unless (null? (cdr l))
    (for-each
      (lambda (module)
        (when (symbol? module)
          (add-extend! doc module)))
      (cdr l))))

;;解析可能な式のリスト
(define-constant analyzable-symbols 
  `(
    (define . ,analyze-normal-define)
    (define-constant . ,analyze-normal-define)
    (define-method . ,analyze-method-define)
    (define-macro . ,analyze-normal-define)
    (define-class . ,analyze-class-define)
    (define-condition-type . ,analyze-condition-class-define)
    (define-module . ,analyze-module-define)
    (extend . ,analyze-extend)
    (define-cproc . ,analyze-stub-proc-define)
    (define-cclass . ,analyze-stub-class-define)
    (define-enum . ,analyze-stub-define-enum)
    ))

;;解析可能な式か?
(define (analyzable? exp)
  (if (and (pair? exp) (list? exp))
    (boolean (assq (car exp) analyzable-symbols))
    #f))

(define (return-from-read-exception org-fp)
  (port-seek (current-input-port) org-fp SEEK_SET)
  ;;skip the first-line of the problem
  (read-line)
  (let loop ([line (read-line)])
    (unless (eof-object? line) 
      (if (or (exp-start-line? line) (doc-start-line? line))
        (restore-fp-with-line line)
        (loop (read-line))))))


;;ドキュメントの直下にある式が定義であれば
;;ドキュメントと関連するものとして解析を行う
(define (parse-expression config unit doc)
  (let1 org-fp (port-seek (current-input-port) 0 SEEK_CUR)
    (guard (exc ([<read-error> exc] (return-from-read-exception org-fp)))
      (let ([exp (read)])
        (unless (get-config config 'skip-relative) 
          (if (analyzable? exp)
            (guard (e [else #f]) ;error of automated analysis is ignored
              ((assq-ref  analyzable-symbols (car exp)) exp config unit doc))))))
    unit))

(define (put-class-c->scm config c-name scm-name)
  (let-values ([(classes new-create?) (cond
                                        [(get-config config 'stub-class) 
                                         => (cut values <> #f)]
                                        [else (values (make-hash-table 'string=?) #t)])])
    (hash-table-put! classes c-name scm-name)
    (if new-create?
      (set-config config 'stub-class classes))))


;;解析しようとしているファイルが.stubであれば事前解析を行う
;;Cレベルのクラス名とGaucheレベルのクラス名の対応を取っておく
(define (pre-parse-stub config)
  (let ([classes (make-hash-table 'string=?)])
    (port-for-each
      (lambda (e)
        (when (and (list? e) (eq? (car e) 'define-cclass))
          (let* ([first? #t]
                 [class (find 
                          (lambda (e)
                            (if (string? e)
                              (if first?
                                (begin (set! first? #f) #f)
                                #t)
                              #f))
                          e)])
            (if class
              (hash-table-put! classes class (symbol->string (cadr e)))))))
      guarded-read)
    (port-seek (current-input-port) 0)
    (set-config config 'stub-class classes)))


;-------***************-----------
;;read file
;-------***************-----------

(define (block-comment-start-line? line)
  (boolean (rxmatch #/^\s*#\|.*/ line)))

(define (exp-comment-start-line? line)
  (boolean (rxmatch #/^\s*#;.*/ line)))

;;ドキュメントの開始マーカーがあるか?
(define (doc-start-line? line)
  (boolean (rxmatch #/^\s*\;\;\;\;\;(?!;)/ line)))

(define (exp-start-line? line)
  (not (or (zero? (string-length (string-trim line)))
         (rxmatch #/^\s*;.*/ line))))

;;ドキュメント解析時の各種設定を設定
(define (set-config config slot v)
  (hash-table-put! config slot v))

;;ドキュメント解析時の各種設定を取得
(define (get-config config slot)
  (hash-table-get config slot #f))

(define newline-size 0)
(define (init-newline-size)
  (let loop ([c (read-char)])
    (cond
      [(eq? #\lf c) (set! newline-size 1)]
      [(eq? #\cr c) 
       (if (eq? (read-char) #\lf)
         (set! newline-size 2)
         (set! newline-size 1))]
      [(eof-object? c) (set! newline-size 1)]
      [else (loop (read-char))]))
  (port-seek (current-input-port) 0))

(define (restore-fp-with-line line)
  (port-seek (current-input-port) -1 SEEK_CUR)
  (let1 ch (read-byte)
    (port-seek (current-input-port) 
             (- (+ (string-size line) 
                   (if (or (eq? 10 ch) ;0x0a #\lf
                         (eq? 13 ch)) ;0x0d #\cr
                     newline-size 0)))
             SEEK_CUR)))

(define (skip-block-comment)
  (skip-while #[\s])
  (read-char) ;;skip # char
  (read-char) ;;skip | char
  (let loop ([ch (read-char)]
             [level 1])
    (cond
      [(and (eq? ch #\#) (eq? (peek-char) #\|))
       (read-char) ;skip | char
       (loop (read-char) (+ level 1))]
      [(and (eq? ch #\|) (eq? (peek-char) #\#))
       (read-char) ;skip # char
       (if (zero? (- level 1))
         #f;finish
         (loop (read-char) (- level 1)))]
      [else (loop (read-char) level)])))

(define (skip-exp-comment)
  (skip-while #[\s])
  (read-char) ;;skip # char
  (read-char) ;;skip ; char
  (guard (e [else #f])
    (read)))

(define (cmd-type-unit? unit)
  (if (and (slot-ref unit 'type) (equal? (slot-ref unit 'type) type-cmd))
    #f
    unit))

(define (read-all-doc-from-port port name ignore-warning? :optional (stub? #f))
  (let ([doc (make <doc>)]
        [config (make-hash-table)]
        [cur-unit (make <unit-bottom>)])
    (set-config config 'name name)
    (parameterize ([ignore-geninfo-warning? ignore-warning?])
      (with-input-from-port
        port
        (lambda ()
          (init-newline-size)
          (when stub?
            (pre-parse-stub config))
          (port-for-each
            (lambda (line)
              (guard (e [(<geninfo-warning> e)
                         (if (ignore-geninfo-warning?)
                           ;initialize the unit
                           (set! cur-unit (make <unit-bottom>))
                           ;raise geninfo-warning
                           (raise e))])
                (cond
                  [(string-null? line) ]
                  [(block-comment-start-line? line)
                   (restore-fp-with-line line)
                   (skip-block-comment)]
                  [(exp-comment-start-line? line)
                   (restore-fp-with-line line)
                   (skip-exp-comment)]
                  [(exp-start-line? line) 
                   (restore-fp-with-line line)
                   (let ([u (parse-expression config cur-unit doc)])
                     (unless (initial-state? u)
                       (add-unit doc (commit-unit config u))
                       (set! cur-unit (make <unit-bottom>))))]
                  [(doc-start-line? line) 
                   (restore-fp-with-line line)
                   (unless (initial-state? cur-unit)
                     (add-unit doc (commit-unit config cur-unit))
                     (set! cur-unit (make <unit-bottom>)))
                   (cond
                     [(cmd-type-unit? (parse-doc config cur-unit))
                      => (cut set! cur-unit <>)]
                     [else (set! cur-unit (make <unit-bottom>))])]
                  )))
            read-line)
          (unless (initial-state? cur-unit)
            (guard (e [(<geninfo-warning> e)
                       (unless (ignore-geninfo-warning?) (raise e))])
              (add-unit doc (commit-unit config cur-unit)))))))
    (commit-doc doc)))


(define (read-all-doc-from-file filename name ignore-warning?)
  (let1 port (open-input-file filename)
    (unwind-protect
      (read-all-doc-from-port 
        port 
        name
        ignore-warning?
        (let1 ext (path-extension filename)
          (and ext (string=? ext "stub"))))
      (close-input-port port))))

;-------***************-----------
;;Entry point
;-------***************-----------

;;一度解析したファイルのドキュメントをキャッシュしておく
(define-constant docs (make-hash-table 'string=?))

(define (to-abs-path path)
  (if (absolute-path? path)
    path
    (build-path (current-directory) path)))

(define (geninfo-from-file path name no-cache ignore-warning?)
  (let ([abs-path (to-abs-path path)])
    (cond
      [(and (not no-cache) (hash-table-get docs abs-path #f)) => identity]
      [else (let ([doc (read-all-doc-from-file abs-path name ignore-warning?)])
              (if (not no-cache)
                (hash-table-put! docs abs-path doc))
              doc)])))

(define (get-module-exports module)
  (eval `(require ,(module-name->path module)) 'gauche)
  (module-exports (find-module module)))

(define (geninfo-from-module symbol no-cache ignore-warning?)
  (let ([path (library-fold symbol (lambda (l p acc) (cons p acc)) '())])
    (if (null? path)
      (raise (condition
               (<geninfo-warning> (message "module not found"))))
      (let ([doc (geninfo-from-file (car path) symbol no-cache ignore-warning?)]
            [exports (get-module-exports symbol)])
        (if (boolean? exports)
          doc
          (make <doc> :units (filter
                               (lambda (u) 
                                 (let ([n (string->symbol (slot-ref u 'name))]) 
                                   (find (cut eq? <> n) exports)))
                               (slot-ref doc 'units))
                :extend (slot-ref doc 'extend)))))))

;;;;;
;;ファイルを解析しドキュメントユニットを生成する
;; @param from シンボルであれば、モジュール名として扱われ現在のロードパスからファイルを検索して解析する
;;文字列であれば、ファイルへのパス名として扱われそのパスに存在するファイルを解析する
(define (geninfo from :key (no-cache #t) (ignore-warning? (ignore-geninfo-warning?)))
  (let1 doc (cond
              [(symbol? from) (geninfo-from-module from no-cache ignore-warning?)]
              [(string? from) (geninfo-from-file from from no-cache ignore-warning?)]
              [else #f]); TODO warging
    (when doc
      (slot-set! doc 'name from))
    doc))

(define (geninfo-from-text text name :key (ignore-warning? (ignore-geninfo-warning?)))
  (let1 doc (read-all-doc-from-port (open-input-string text) name ignore-warning?)
    (when doc
      (slot-set! doc 'name name))
    doc))


;-------***************-----------
;Output 
;-------***************-----------

(define-method output-for-each ((out <convert-context>) doc)
  (with-output-to-port (slot-ref out 'port)
                       (lambda ()
                         (for-each
                           (lambda (unit) (output out unit))
                           (slot-ref doc 'units)))))

(define-generic output)

