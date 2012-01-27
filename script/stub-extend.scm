(add-load-path ".")


(load "gauche/cgen/stub.scm")
(select-module gauche.cgen.stub)

(load "cise-extend.scm")
(use gauche.cgen.cise)

(define-class <cclass> (<stub>)
  ((cpa        :init-keyword :cpa       :init-value '())
   (c-type     :init-keyword :c-type)
   (qualifiers :init-keyword :qualifiers)
   (allocator  :init-keyword :allocator :init-value #f)
   (printer    :init-keyword :printer   :init-value #f)
   (compare    :init-keyword :compare   :init-value #f)
   (slot-spec  :init-keyword :slot-spec :init-value '())
   (direct-supers :init-keyword :direct-supers :init-value '())
   ))

(instance-pool-remove! <form-parser>
                       (lambda (p) (eq? 'define-cclass (~ p 'name))))
(define-form-parser define-cclass (scm-name . args)
  (check-arg symbol? scm-name)
  (receive (quals rest) (span keyword? args)
    (cond
     [(lset-difference eqv? quals '(:built-in :base :private :struct)) pair?
      => (cut error <cgen-stub-error> "unknown define-cclass qualifier(s)" <>)])
    (match rest
      [(c-type c-name cpa slot-spec . more) 
       (check-arg string? c-name)
       (check-arg list? cpa)
       (check-arg list? slot-spec)
       (let* ((allocator (cond ((assq 'allocator more) => cadr) (else #f)))
              (printer   (cond ((assq 'printer more) => cadr) (else #f)))
              (compare   (cond ((assq 'compare more) => cadr) (else #f)))
              (dsupers   (cond ((assq 'direct-supers more) => cdr) (else '())))
              (cclass (make <cclass>
                        :scheme-name scm-name :c-type c-type :c-name c-name
                        :qualifiers quals
                        :cpa cpa :direct-supers dsupers
                        :allocator allocator :printer printer :compare compare)))
         (set! (~ cclass'slot-spec) (process-cclass-slots cclass slot-spec))
         (cgen-add! cclass))])))


(define-method c-compare-name ((self <cclass>))
  (let1 compare (~ self'compare)
    (cond [(c-literal-expr compare)]
      [(not compare) "NULL"]
      [else #`",(~ self'c-name)_P"])))


(define-method cgen-emit-body ((self <cclass>))
  (when (memv :private (~ self'qualifiers))
    (cclass-emit-standard-decls self))
  (unless ((any-pred not c-literal?) (~ self'allocator))
    (p "static ScmObj "(c-allocator-name self)"(ScmClass *klass, ScmObj initargs)")
    (p "{")
    (p (c-code (~ self'allocator)))
    (p "}")
    (p ""))
  (unless ((any-pred not c-literal?) (~ self'printer))
    (emit-printer self))
  (unless ((any-pred not c-literal?) (~ self'compare))
    (emit-compare self))
  (emit-cpa self)
  (if (memv :base (~ self'qualifiers))
    (let1 c-type (string-trim-right (~ self'c-type))
      (unless (string-suffix? "*" c-type)
        (errorf <cgen-stub-error> "can't use C-type ~s as a base class; C-type must be a pointer type" c-type))
      (let1 c-instance-type (string-drop-right c-type 1)
        (p "SCM_DEFINE_BASE_CLASS("(~ self'c-name)", "c-instance-type", "(c-printer-name self)", NULL, NULL, "(c-allocator-name self)", "(cpa-name self)");")))
    (p "SCM_DEFINE_BUILTIN_CLASS("(~ self'c-name)", "(c-printer-name self)", "(c-compare-name self) ", NULL, "(c-allocator-name self)", "(cpa-name self)");"))
  (p "")
  (when (pair? (~ self'slot-spec))
    (for-each emit-getter-n-setter (~ self'slot-spec))
    (p "static ScmClassStaticSlotSpec "(c-slot-spec-name self)"[] = {")
    (for-each emit-spec-definition (~ self'slot-spec))
    (p "  SCM_CLASS_SLOT_SPEC_END()")
    (p "};")
    (p))
  )

(define-method cgen-emit-init ((self <cclass>))
  ;;modification
  ;(p "  Scm_InitBuiltinClass(&"(~ self'c-name)", \""(~ self'scheme-name)"\", "(c-slot-spec-name self)", TRUE, mod);")
  (p "  Scm_InitBuiltinClass(&"(~ self'c-name)", \""(~ self'scheme-name)"\", "(c-slot-spec-name self)", FALSE, mod);")
  ;; adjust direct-supers if necessary
  (let1 ds (~ self'direct-supers)
    (when (not (null? ds))
      (p "  "(~ self'c-name)".directSupers = Scm_List(")
      (for-each (lambda (s) (p "SCM_OBJ(&"s"), ")) ds)
      (p " NULL);")
      (p))))


;; printer ----------
;;  
(define-method emit-printer ((self <cclass>))
  (p "static void "(c-printer-name self)"(ScmObj obj, ScmPort *port, ScmWriteContext *ctx)")
  (p "{")
  (if (eq? (~ self'printer) #t)
    (let* ([scheme-name (~ self'scheme-name)]
           [class-type (name->type scheme-name)]
           [slot (~ self'slot-spec)]
           [text (string-append "#{"
                                (x->string scheme-name)
                                (fold (lambda (s acc) #`",acc ,(~ s'scheme-name):%S") "" slot)
                                "}")]
           [obj-unbox #`",(cgen-unbox-expr class-type \"obj\"),(if (memv :struct (~ self'qualifiers)) \".\" \"->\")"]
           [slot-values (fold (lambda (s acc)
                                #`",acc,\",\" ,(cgen-box-expr (~ s'type)
                                                              (if (string? (~ s'c-spec))
                                                                (~ s'c-spec)
                                                                (string-append obj-unbox (~ s'c-name))))")
                              ""
                              slot)])
                                (p "Scm_Printf(port, \"" text "\"" slot-values ");"))
    (p (c-code (~ self'printer))))
           (p "}")
           (p ""))

;; compare ----------
;;  
(define-method emit-compare ((self <cclass>))
  (p "static int "(c-compare-name self)"(ScmObj x, ScmObj y, int equalp)")
  (p "{")
  (if (eq? (~ self'compare) #t)
    (let* ([scheme-name (~ self'scheme-name)]
           [class-type (name->type scheme-name)]
           [obj-unbox (lambda (obj)
                        #`",(cgen-unbox-expr class-type obj),(if (memv :struct (~ self'qualifiers)) \".\" \"->\")")]
           [x-unboxed (obj-unbox "x")]
           [y-unboxed (obj-unbox "y")])
      (define (slot-value unboxed s) (cgen-box-expr (~ s'type) (if (string? (~ s'c-spec))
                                                                 (~ s'c-spec)
                                                                 (string-append unboxed (~ s'c-name)))))
      (p "if(!equalp) Scm_Error(\"cannot compare " scheme-name ":%S and :%S\", x, y);")
      (p "return !("
         (string-join (map
                        (lambda (s) #`"Scm_EqualP(,(slot-value x-unboxed s) ,\",\" ,(slot-value y-unboxed s))")
                        (~ self'slot-spec))
                      " && ")
         ");"))
    (p (c-code (~ self'compare))))
  (p "}")
  (p ""))


(define-method emit-getter ((slot <cslot>))
  (let* ([type  (~ slot'type)]
         [class (~ slot'cclass)]
         [class-type (name->type (~ class'scheme-name))])
    (p "static ScmObj "(slot-getter-name slot)"(ScmObj OBJARG)")
    (p "{")
    (let1 is-struct (memv :struct (slot-ref (~ slot'cclass) 'qualifiers))
      (unless is-struct
        (p "  "(~ class-type'c-type)" obj = "(cgen-unbox-expr class-type "OBJARG")";"))
      (cond [(string? (~ slot'getter)) (p (~ slot'getter))]
        [(string? (~ slot'c-spec))
         (f "  return ~a;" (cgen-box-expr type (~ slot'c-spec)))]
        [else
          (f "  return ~a;" (cgen-box-expr type 
                                           (string-append (if is-struct 
                                                            (string-append 
                                                              (cgen-unbox-expr class-type "OBJARG") ".") 
                                                            "obj->")
                                                          (~ slot'c-name))))])

      (p "}")
      (p ""))))


(define-method emit-setter ((slot <cslot>))
  (let* ([type (~ slot'type)]
         [class (~ slot'cclass)]
         [class-type (name->type (~ class'scheme-name))])
    (p "static void "(slot-setter-name slot)"(ScmObj OBJARG, ScmObj value)")
    (p "{")
    (let1 is-struct (memv :struct (slot-ref (~ slot'cclass) 'qualifiers))
      (unless is-struct
        (p "  "(~ class-type'c-type)" obj = "(cgen-unbox-expr class-type "OBJARG")";"))
      (if (string? (~ slot'setter))
        (p (~ slot'setter))
        (begin
          (unless (eq? type *scm-type*)
            (f "  if (!~a(value)) Scm_Error(\"~a required, but got %S\", value);"
               (~ type'c-predicate) (~ type'c-type)))
          (if (~ slot'c-spec)
            (f "  ~a = ~a;" (~ slot'c-spec) (cgen-unbox-expr type "value"))
            (f "  ~a~a = ~a;" 
               (if is-struct
                 (string-append (cgen-unbox-expr class-type "OBJARG") ".")
                 "obj->") 
               (~ slot'c-name)
               (cgen-unbox-expr type "value")))))
      (p "}")
      (p ""))))


(define-form-parser eval-in-current-module exprs
  (let ([m (current-module)])
    (for-each (lambda (f) (eval f m)) exprs)))

