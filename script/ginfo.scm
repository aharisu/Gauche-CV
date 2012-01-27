(define-module ginfo
  (use srfi-1)  ;;filter
  (use srfi-11) ;;let-values
  (use srfi-13) ;;string util
  (use util.list)
  (use util.match)
  (use file.util)
  (use text.parse)
  (use gauche.interactive)
  #;(export <doc> <geninfo-warning> <convert-context>
    <unit-top> <unit-proc> <unit-var> <unit-class>
    unit-bottom-initializer-add! slot-update!
    api geninfo)
  (export-all)
  )

(select-module ginfo)

(define e->e (lambda (e) e))

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
   ))

(define (add-unit doc config unit)
  (when unit
    (slot-set! doc 'units (cons unit (slot-ref doc 'units))))
  unit)

(define (commit-doc doc)
  (slot-set! doc 'units (reverse (slot-ref doc 'units)))
  doc)

;;;;;
;;全てのドキュメントユニットの上位クラス
;; @slot name slot name
;; @slot type type name
(define-class <unit-top> ()
  (
   (cur-tag :init-value 'description)

   (name :init-value #f)
   (type :init-value #f)

   (description :init-value '())
   ))

;;<unit-bottom>の各スロットから値をコピーする
;;これ以降unitを編集することはない
(define-method commit ((unit <unit-top>) original)
  (slot-set! unit 'name (slot-ref original 'name))
  (slot-set! unit 'type (slot-ref original 'type))
  (slot-set! unit 'description (reverse (slot-ref original 'description)))
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
      [(hash-table-get (slot-ref obj '%slots) slot #f) => e->e]
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


;;;;;
;;functionやmethodタイプ用のunit
(define-class <unit-proc> (<unit-top>)
  (
   (param :init-value '())
   (return :init-value '())
   ))

(define-method commit ((unit <unit-proc>) original)
  (next-method)
  (slot-set! unit 'description (reverse (slot-ref original 'description)))
  (slot-set! unit 'return (reverse (slot-ref original 'return)))
  ;;この時点で(hidden new (text1 text2 ...))のリスト構造から(new (text1 text2 ...))のリスト構造に修正する
  ;;hiddenとnewは自動解析結果の引数名を手動で修正するためにある
  (slot-set! unit 'param (map 
                           (lambda (p)(list (cadr p) (reverse (caddr p))))
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


;;;;;
;;classタイプ用のunit
(define-class <unit-class> (<unit-top>)
  (
   (supers :init-value '())
   (slots :init-value '())
   )
  )

(define-method commit ((unit <unit-class>) original)
  (next-method)
  (slot-set! unit 'supers (reverse (slot-ref original 'supers)))
  (slot-set! unit 'slots (map
                           (lambda (s) (list (car s) (reverse (cadr s))))
                           (slot-ref original 'slots)))
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
            [(or-equal? type type-fn type-method) (make <unit-proc> unit)]
            [(or-equal? type type-var type-const type-parameter) (make <unit-var> unit)]
            [(or-equal? type type-class) (make <unit-class> unit)]
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
    [x (x->string x)]))

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
  (let ([port (open-input-string line)])
    (if (zero? (string-length (string-trim (next-token-of '(#\space #\tab #\.) port))))
      (let ([first (read port)])
        (if (eof-object? first)
          #f
          (append (match first
                    [(hidden '>> new) (list (x->writable-string hidden) (x->writable-string new))]
                    [sym (list (x->writable-string sym) (x->writable-string sym))])
                  (cons (string-trim (port->string port)) '()))))
      ;;param name is "."
      (list "." "." (string-trim (port->string port))))))

;;define @description tag
(define-tag description
            tag-allow-multiple-ret-true
            tag-init
            (tag-append-text 'description))

;;define @param tag
(define-tag param
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (cond
                [(split-first-token first-line) 
                 => (lambda (tokens)
                      (slot-update! unit 'param (lambda (v)
                                                  (cons 
                                                      (list (car tokens) (cadr tokens) '())
                                                      v)))
                      (caddr tokens))]
                [else (raise (condition (<geninfo-warning> (message "param name is required"))))]))
            (lambda (text config unit)
              (slot-update! unit 'param 
                            (lambda (value)
                              (set-car! (cddr (car value)) (cons text (caddr (car value))))
                              value))))

;;define @return tag
(define-tag return
            (lambda (config unit) (null? (slot-ref unit 'return)))
            tag-init
            (tag-append-text 'return))


;;define @slot tag
(define-tag slot
            tag-allow-multiple-ret-true
            (lambda (first-line config unit)
              (cond
                [(split-first-token first-line)
                 => (lambda (tokens)
                      (slot-update! unit 'slots (lambda (v) (cons (list (car tokens) '()) v)))
                      (caddr tokens))]
                [else (raise (condition (<geninfo-warning> (message "slot name is required"))))]))
            (lambda (text config unit)
              (slot-update! unit 'slots
                            (lambda (v)
                              (set-car! (cdr (car v)) (cons text (cadr (car v))))
                              v))))

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
              (let ([name (read (open-input-string first-line))])
                (if (eof-object? name)
                  (raise (condition (<geninfo-warning> (message "@name tag required document unit name"))))
                  (slot-set! unit 'name (x->string name)))
                ""))
            (lambda (text config unit) (slot-set! unit 'name text)))


;;define @type tag
(define-constant type-fn "Function")
(define-constant type-var "var")
(define-constant type-method "Method")
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
    ,type-const
    ,type-parameter
    ,type-class
    ,type-cmd
    ))
(define-tag type
            (lambda (config unit) (not (slot-ref unit 'type)))
            (lambda (first-line config unit)
              (let ([type (read (open-input-string first-line))])
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
              (let ([parse? (read (open-input-string first-line))])
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
  (if (null? args)
    args
    (c->l args '())))


;;仮引数部をマッチングしながら再帰的に解析する
(define (parse-each-arg args func-get-var config)
  (let ([unit (make <unit-proc>)]
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
          [else (print "analyze-args warning. " (car p))])) ;TODO warging
      org-param)
    (slot-set! unit 'param gen-param)))


;;define, define-constantの解析を行う
(define (analyze-normal-define l config unit)
  (let ([constant? (eq? (car l) 'define-constant)])
    (match l
      [(_ (symbol args ...) _ ...) ;; lambda -> function
       (set-unit-name (symbol->string symbol) config unit)
       (set-unit-type type-fn config unit) 
       (analyze-args args e->e config unit)]

      [(_ symbol exp) 
       (if (pair? symbol)
         (begin
           (set-unit-name (symbol->string (car symbol)) config unit)
           (set-unit-type type-fn config unit)
           (analyze-args (cdr symbol) e->e config unit))
         (begin 
           (set-unit-name (symbol->string symbol) config unit)
           (match exp 
             [(or ('lambda (args ...) _ ...) ;; lambda -> function
                ('^ (args ...) _ ...))
              (set-unit-type type-fn config unit)
              (analyze-args args e->e config unit)]
             [(or ('lambda arg _ ...) ;; lambda -> function
                ('^ arg _ ...))
              (set-unit-type type-fn config unit)
              (analyze-args (list :rest arg) e->e config unit)]
             [else (set-unit-type (if constant? type-const type-var) config unit)])))];; other -> var or constant

      [(_ symbol) ;; other -> var or constant
       (set-unit-name (symbol->string symbol) config unit)
       (set-unit-type (if constant? type-const type-var) config unit)]

      [(_) #f])))

;;define-methodの解析を行う
;;TODO エラー処理
(define (analyze-method-define l config unit)
  (if (null? (cdr l))
    #f);TODO warning
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-method config unit)
  (if (null? (caddr l))
    #f);TODO warning
  (analyze-args (caddr l) e->e config unit))


(define (convert-type type)
  (let ([conv '(
                (<void> . "#<undefined>")
                )])
    (cond
      [(assq-ref conv type #f) => e->e]
      [else (symbol->string type)])))


;;stub用 define-cprocの解析を行う
;;TODO エラー処理
(define (analyze-stub-proc-define l config unit)
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
                             '()))
                     slots)])
    (for-each
      (lambda (s)
        (cond
          [(assoc (car s) gen-slots)
           => (lambda (slot) (set-car! (cdr slot) (cadr s)))]
          [else (print "analyze-slots warning. " (car s))]))
      org-slots)
    gen-slots))


;;defime-classの解析を行う
(define (analyze-class-define l config unit)
  (set-unit-name (symbol->string (cadr l)) config unit)
  (set-unit-type type-class config unit)
  (slot-set! unit 'supers (map x->string (reverse (caddr l))))
  (slot-set! unit 'slots (analyze-slots (cadddr l) unit)))

;;stub用 define-cclassの解析を行う
(define (analyze-stub-class-define l config unit)
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
                                  [(to-class classes x) => e->e]
                                  [else (raise (condition
                                                 (<geninfo-warning> (message "super class is not found"))))]))
                              (reverse supers)))
    (slot-set! unit 'slots (analyze-slots slots unit))))



;;解析可能な式のリスト
(define-constant analyzable-symbols 
  `(
    (define . ,analyze-normal-define)
    (define-constant . ,analyze-normal-define)
    (define-method . ,analyze-method-define)
    (define-class . ,analyze-class-define)
    (define-cproc . ,analyze-stub-proc-define)
    (define-cclass . ,analyze-stub-class-define)
    ))

;;解析可能な式か?
(define (analyzable? exp)
  (if (list? exp)
    (boolean (assq (car exp) analyzable-symbols))
    #f))

;;ドキュメントの直下にある式が定義であれば
;;ドキュメントと関連するものとして解析を行う
(define (parse-expression config unit)
  (let ([exp (read)])
    (unless (get-config config 'skip-relative) 
      (if (analyzable? exp)
        ((assq-ref  analyzable-symbols (car exp)) exp config unit))))
  unit)

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
      read)
    (port-seek (current-input-port) 0)
    (set-config config 'stub-class classes)))


;-------***************-----------
;;read file
;-------***************-----------

;;ドキュメントの開始マーカーがあるか?
(define (doc-start-line? line)
  (boolean (rxmatch #/^\s*\;\;\;\;\;(?!;)/ line)))

(define (exp-start-line? line)
  (not (or (zero? (string-length (string-trim line)))
         (rxmatch #/^\s*(?:\|#)?\s*(?:;|#\||#;).*/ line))))

;;ドキュメント解析時の各種設定を設定
(define (set-config config slot v)
  (hash-table-put! config slot v))

;;ドキュメント解析時の各種設定を取得
(define (get-config config slot)
  (hash-table-get config slot #f))

(define-constant newline-size (string-size "\n"))
(define (restore-fp-with-line line)
  (port-seek (current-input-port) (- (+ (string-size line) 
                                        newline-size)) SEEK_CUR))

(define (cmd-type-unit? unit)
  (if (and (slot-ref unit 'type) (equal? (slot-ref unit 'type) type-cmd))
    #f
    unit))



(define (read-all-doc filename)
  (let ([doc (make <doc>)]
        [config (make-hash-table)]
        [cur-unit (make <unit-bottom>)])
    (with-input-from-file
      filename
      (lambda ()
        (when (string=? (path-extension filename) "stub")
          (pre-parse-stub config))
        (port-for-each
          (lambda (line)
            (cond
              [(exp-start-line? line) 
               (restore-fp-with-line line)
               (let ([u (parse-expression config cur-unit)])
                 (unless (initial-state? u)
                   (add-unit doc config (commit-unit config u))
                   (set! cur-unit (make <unit-bottom>))))]
              [(doc-start-line? line) 
               (restore-fp-with-line line)
               (unless (initial-state? cur-unit)
                 (add-unit doc config (commit-unit config cur-unit))
                 (set! cur-unit (make <unit-bottom>)))
               (cond
                 [(cmd-type-unit? (parse-doc config cur-unit))
                  => (cut set! cur-unit <>)]
                 [else (set! cur-unit (make <unit-bottom>))])]
            ))
          read-line)))
    (commit-doc doc)))


;-------***************-----------
;;Entry point
;-------***************-----------

;;一度解析したファイルのドキュメントをキャッシュしておく
(define-constant docs (make-hash-table 'string=?))

(define (to-abs-path path)
  (if (absolute-path? path)
    path
    (build-path (current-directory) path)))

(define (geninfo-from-file path no-cache)
  (let ([abs-path (to-abs-path path)])
    (cond
      [(and (not no-cache) (hash-table-get docs abs-path #f)) => e->e]
      [else (let ([doc (read-all-doc abs-path)])
              (if (not no-cache)
                (hash-table-put! docs abs-path doc))
              doc)])))

(define (get-module-exports module)
  (eval `(require ,(module-name->path module)) 'gauche)
  (module-exports (find-module module)))

(define (geninfo-from-module symbol no-cache)
  (let ([path (library-fold symbol (lambda (l p acc) (cons p acc)) '())])
    (if (null? path)
      (raise (condition
               (<geninfo-warning> (message "module not found"))))
      (let ([doc (geninfo-from-file (car path) no-cache)]
            [exports (get-module-exports symbol)])
        (if (boolean? exports)
          doc
          (make <doc> :units (filter
                               (lambda (u) 
                                 (let ([n (string->symbol (slot-ref u 'name))]) 
                                   (find (cut eq? <> n) exports)))
                               (slot-ref doc 'units))))))))

;;;;;
;;ファイルを解析しドキュメントユニットを生成する
;; @param from シンボルであれば、モジュール名として扱われ現在のロードパスからファイルを検索して解析する
;;文字列であれば、ファイルへのパス名として扱われそのパスに存在するファイルを解析する
(define (geninfo from :optional (no-cache #f))
  (cond
    [(symbol? from) (geninfo-from-module from no-cache)]
    [(string? from) (geninfo-from-file from no-cache)]
    [else #f])); TODO warging


;-------***************-----------
;Output 
;-------***************-----------

(define-method output-for-each ((out <convert-context>) doc)
  (with-output-to-port (slot-ref out 'port)
                       (lambda ()
                         (for-each
                           (lambda (unit) (output out unit))
                           (slot-ref doc 'units)))))


;-------***************-----------
;API Out
;-------***************-----------

;;;;;
;;ユニットのapi情報を標準出力に出力する
;;api関数で検索したユニットを出力するために利用する
(define-class <api-context> (<convert-context>) ())

(define-method output ((context <api-context>) (unit <unit-top>))
  (format #t "API are\n")
  (format #t "  type        : ~a\n" (ref unit 'type))
  (format #t "  name        : ~a\n" (ref unit 'name))
  (unless (null? (ref unit 'description))
    (format #t "  description : ~a\n" (string-join (ref unit 'description) "\n                ")))
  )

(define-method output ((context <api-context>) (unit <unit-proc>))
  (next-method)
  (unless (null? (ref unit 'param))
    (begin
      (format #t "  param       : ~a\n" (fold-right
                                          (lambda (p acc) (string-append (car p) " " acc))
                                          ""
                                          (slot-ref unit 'param)))
      (for-each
        (lambda (p) 
          (unless (null? (cadr p))
            (format #t "- param##~a :\n    ~a\n" (car p) (string-join (cadr p) "\n    " ))))
        (slot-ref unit 'param))))
  (unless (null? (ref unit 'return))
    (format #t "  return      : ~a\n" (string-join (ref unit 'return) "\n                ")))
  )

(define-method output ((context <api-context>) (unit <unit-class>))
  (next-method)
  (unless (null? (slot-ref unit 'supers))
    (format #t "  supers      : ~a\n" (string-join (ref unit 'supers) " ")))
  (for-each
    (lambda (s)
      (format #t "  slot        : ~a\n" (car s))
      (unless (null? (cadr s))
        (format #t "    ~a\n" (string-join (cadr s) "\n    "))))
    (slot-ref unit 'slots))
  )


;;ドキュメントの中からnameがsymbolのユニットを探す
(define (find-unit str-symbol doc)
  (find (lambda (unit) (string=? str-symbol (ref unit 'name))) (ref doc 'units)))

;;fromが指定してある場合はそのドキュメントの中から
;;fromが指定していない場合は読み込み済みの全てのドキュメントの中から
;;symbolと同じ名前を持つユニットを探す
(define (find-doc-unit symbol from)
  (if from
    (find-unit symbol (geninfo from #f))
    (call/cc (lambda (c)
               (hash-table-for-each docs (lambda (name doc) (cond [(find-unit symbol doc) => c])))
               #f))))

;;現在読み込んでいるモジュールから調べたいシンボルを探し、
;;見つかったモジュールのドキュメントを生成してユニットを返す
(define (find-doc-unit-in-modules symbol)
  (cond
    [(call/cc (lambda (c)
                (for-each 
                  (lambda (m)
                    (if (find 
                          (lambda (s) (eq? s symbol))
                          (hash-table-keys (module-table m)))
                      (c m)))
                  (all-modules))
                #f))
     => (lambda (m) (find-unit (x->string symbol) (geninfo-from-module (module-name m) #f)))]
    [else #f]))

(define (show-api unit)
  (let ([context (make <api-context> :port (standard-output-port))])
    (with-output-to-port (slot-ref context 'port)
                         (lambda ()
                           (output context unit)))))

;;;;;
;;symbolのドキュメントユニットを探し、api情報を出力する
(define (api symbol :key from)
  (guard (e
           ;;TODO もうちょっとましな警告表示
           [(<geninfo-warning> e) (format #t "~s\n" (slot-ref e 'message))])
    (cond
      [(find-doc-unit (x->string symbol) (if (undefined? from) #f from)) => show-api]
      [(find-doc-unit-in-modules symbol) => show-api]
      [else #f]))
  (values))


