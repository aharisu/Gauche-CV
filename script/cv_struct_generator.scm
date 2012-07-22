(add-load-path ".")
(load "unit-extend")


(use srfi-13)
(use file.util)
(use gauche.cgen)
(use gauche.parameter)

(define (scm-class-name name) (string-append "SCM_CLASS_" (string-upcase (x->string name))))
(define (scm-allocator-name name) (string-append "Scm_Make" (x->string name)))

(define (gen-type filename 
                  struct-name-list forign-struct-name-list
                  prologue epilogue)
  (parameterize ([cgen-current-unit 
                   (make <cgen-unit-stub>
                         :name filename
                         :c-file (string-append filename ".gen.c")
                         :h-file (string-append filename ".gen.h")
                         :stub-file (string-append filename ".gen.stub.header")
                         :init-prologue (format "void Scm_Init_~a(ScmModule* mod) {" filename)
                         :init-epilogue "}"
                         )])

    (define (gen-stub-type c-name pointer? scm-name up-name)
      (cgen-stub "(define-type")
      (cgen-stub (format "	~a" scm-name))
      (cgen-stub (format "	\"~a~a\"" c-name 
                         (if pointer? "*" "")))
      (cgen-stub (format "	\"~a\"" c-name))
      (cgen-stub (format "	\"SCM_~a_P\"" up-name))
      (cgen-stub (format "	\"SCM_~a_DATA\"" up-name))
      (cgen-stub (format "	\"SCM_MAKE_~a\")\n" up-name)))

    (define (gen-struct sym-name sym-scm-type pointer? finalize finalize-ref)
      (let* ([name (symbol->string sym-name)]
             [scm-name (string-append "Scm" name)]
             [scm-type (symbol->string sym-scm-type)]
             [ster (if pointer? "*" "")]
             [up-name (string-upcase name)])

        ;;stub file
        (gen-stub-type name pointer? scm-type up-name)

        ;;h file
        (cgen-extern "//---------------")
        (cgen-extern (format "//~a" name))
        (cgen-extern "//---------------")
        (cgen-extern (format "typedef struct Scm~aRec {" name))
        (cgen-extern "	SCM_HEADER;")
        (cgen-extern (format "	~a~a data;" name ster))
        (cgen-extern (format "}~a;" scm-name))

        (cgen-extern (format "SCM_CLASS_DECL(Scm_~aClass);" name))
        (cgen-extern (format "#define ~a (&Scm_~aClass)" (scm-class-name name) name))
        (cgen-extern (format "#define SCM_~a(obj) ((~a*)(obj))" up-name scm-name))
        (cgen-extern (format "#define SCM_~a_P(obj) SCM_ISA(obj, SCM_CLASS_~a)" up-name up-name))
        (cgen-extern (format "#define SCM_~a_DATA(obj) (SCM_~a(obj)->data)" up-name up-name))
        (cgen-extern (format "#define SCM_MAKE_~a(data) (~a(data))" up-name (scm-allocator-name name)))
        (cgen-extern (format "extern ScmObj ~a(~a~a data);" (scm-allocator-name name) name ster))
        (cgen-extern "")

        ;;c file
        (cgen-body "//---------------")
        (cgen-body (format "//~a" name))
        (cgen-body "//---------------")
        (when (string? finalize)
          (cgen-body (format "static void Scm_finalize_~a(ScmObj obj, void* data){" name))
          (cgen-body (format "	~a* o = SCM_~a(obj);" scm-name up-name))
          (cgen-body "	if(o->data) {")
          (cgen-body (format "		~a(~ao->data);" finalize finalize-ref))	
          (cgen-body "		o->data = NULL;")
          (cgen-body "	}")
          (cgen-body "}"))

        (cgen-body (format "ScmObj ~a(~a~a data) {" (scm-allocator-name name) name ster))
        (cgen-body (format "	~a* obj = SCM_NEW(~a);" scm-name scm-name))
        (cgen-body (format "	SCM_SET_CLASS(obj, SCM_CLASS_~a);" up-name))
        (if (string? finalize)
          (cgen-body (format "	Scm_RegisterFinalizer(SCM_OBJ(obj), Scm_finalize_~a, NULL);" name)))
        (cgen-body "	obj->data = data;")
        (cgen-body "	SCM_RETURN(SCM_OBJ(obj));")
        (cgen-body "}")
        (cgen-body "")

        ))

    (define (gen-foreign-pointer sym-name sym-scm-type pointer? finalize finalize-ref)
      (let* ([name (symbol->string sym-name)]
             [scm-type (symbol->string sym-scm-type)]
             [scm-name (string-append "Scm" name)]
             [ster (if pointer? "*" "")]
             [up-name (string-upcase name)])

        ;;stub file
        (gen-stub-type name pointer? scm-type up-name)

        ;;h file
        (cgen-extern "//---------------")
        (cgen-extern (format "//~a" name))
        (cgen-extern "//---------------")
        (cgen-extern (format "extern ScmClass* Scm_~aClass;" name))
        (cgen-extern (format "#define SCM_~a_P(obj) SCM_XTYPEP(obj, Scm_~aClass)" up-name name))
        (cgen-extern (format "#define SCM_~a_DATA(obj) SCM_FOREIGN_POINTER_REF(~a~a, obj)" up-name name ster))
        (cgen-extern (format "#define SCM_MAKE_~a(data) Scm_MakeForeignPointer(Scm_~aClass, data)" up-name name))
        (cgen-body "")

        ;;c file
        (cgen-body "//---------------")
        (cgen-body (format "//~a" name))
        (cgen-body "//---------------")
        (when (string? finalize)
          (cgen-body (format "static void Scm_cleanup_~a(ScmObj obj){" name))
          (cgen-body (format "	~a~a o = SCM_~a_DATA(obj);" name ster up-name))
          (cgen-body "	if(o) {")
          (cgen-body (format "		~a(~ao);" finalize finalize-ref))
          (cgen-body "		SCM_FOREIGN_POINTER(obj)->ptr = NULL;")
          (cgen-body "	}")
          (cgen-body "}")
          (cgen-body ""))

        (cgen-decl (format "ScmClass* Scm_~aClass;" name))
        (cgen-init (format "Scm_~aClass = 
                           Scm_MakeForeignPointerClass(mod, \"~a\",
                                                            NULL,
                                                            ~a,
                                                            SCM_FOREIGN_POINTER_KEEP_IDENTITY|SCM_FOREIGN_POINTER_MAP_NULL);"
                           name scm-type (if (string? finalize)
                                           (string-append "Scm_cleanup_" name)
                                           "NULL")))
        ))

    ;;h file header
    (cgen-extern (format "#ifndef GAUCHE_~a_H" (string-upcase filename)))
    (cgen-extern (format "#define GAUCHE_~a_H" (string-upcase filename)))

    (cgen-extern "#include<gauche.h>")
    (cgen-extern "#include<gauche/extend.h>")
    (cgen-extern "#include<gauche/class.h>")

    (cgen-extern "SCM_DECL_BEGIN")
    (cgen-extern "")

    ;;c file header
    (cgen-decl (format "#include\"~a.gen.h\"" filename))
    (cgen-decl "")


    ;;call prologue
    (prologue)

    (for-each
      (lambda (s) (gen-struct (car s) (cadr s) (caddr s) (cadddr s) (car (cddddr s))))
      struct-name-list)

    (for-each
      (lambda (s) (gen-foreign-pointer (car s) (cadr s) (caddr s) (cadddr s) (car (cddddr s))))
      forign-struct-name-list)


    ;;call epilogue
    (epilogue)

    (cgen-extern "")
    (cgen-extern "SCM_DECL_END")
    (cgen-extern "#endif")

    (cgen-emit-h (cgen-current-unit))
    (cgen-emit-c (cgen-current-unit))
    (cgen-emit-stub (cgen-current-unit))
    ))


