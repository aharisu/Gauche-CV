(add-load-path ".")
(load "unit-extend")


(use srfi-13)
(use file.util)
(use gauche.cgen)
(use gauche.parameter)


(define (main args)
	(parameterize ([cgen-current-unit 
									 (make <cgen-unit-stub>
												 :name (path-sans-extension (car args))
												 :c-file (path-swap-extension (car args) "gen.c")
												 :h-file (path-swap-extension (car args) "gen.h")
												 :stub-file (path-swap-extension (car args) "gen.stub.header")
												 :init-prologue "void Scm_Init_cv_struct(ScmModule* mod) {"
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
				(cgen-extern (format "#define SCM_CLASS_~a (&Scm_~aClass)" up-name name))
				(cgen-extern (format "#define SCM_~a(obj) ((~a*)(obj))" up-name scm-name))
				(cgen-extern (format "#define SCM_~a_P(obj) SCM_XTYPEP(obj, SCM_CLASS_~a)" up-name up-name))
				(cgen-extern (format "#define SCM_~a_DATA(obj) (SCM_~a(obj)->data)" up-name up-name))
				(cgen-extern (format "#define SCM_MAKE_~a(data) (Scm_Make~a(data))" up-name name))
				(cgen-extern (format "extern ScmObj Scm_Make~a(~a~a data);" name name ster))
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

				(cgen-body (format "ScmObj Scm_Make~a(~a~a data) {" name name ster))
				(cgen-body (format "	~a* obj = SCM_NEW(~a);" scm-name scm-name))
				(cgen-body (format "	SCM_SET_CLASS(obj, SCM_CLASS_~a);" up-name))
				(if (string? finalize)
					(cgen-body (format "	Scm_RegisterFinalizer(SCM_OBJ(obj), Scm_finalize_~a, NULL);" name)))
				(cgen-body "	obj->data = data;")
				(cgen-body "	SCM_RETURN(SCM_OBJ(obj));")
				(cgen-body "}")
				(cgen-body "")

			))

		(define (gen-foreign-pointer sym-name sym-scm-type finalize finalize-ref)
			(let* ([name (symbol->string sym-name)]
						 [scm-type (symbol->string sym-scm-type)]
						 [scm-name (string-append "Scm" name)]
						 [up-name (string-upcase name)])

				;;stub file
				(gen-stub-type name #t scm-type up-name)

				;;h file
				(cgen-extern "//---------------")
				(cgen-extern (format "//~a" name))
				(cgen-extern "//---------------")
				(cgen-extern (format "extern ScmClass* Scm_~aClass;" name))
				(cgen-extern (format "#define SCM_~a_P(obj) SCM_XTYPEP(obj, Scm_~aClass)" up-name name))
				(cgen-extern (format "#define SCM_~a_DATA(obj) SCM_FOREIGN_POINTER_REF(~a*, obj)" up-name name))
				(cgen-extern (format "#define SCM_MAKE_~a(data) Scm_MakeForeignPointer(Scm_~aClass, data)" up-name name))
				(cgen-body "")

				;;c file
				(cgen-body "//---------------")
				(cgen-body (format "//~a" name))
				(cgen-body "//---------------")
				(when (string? finalize)
					(cgen-body (format "static void Scm_cleanup_~a(ScmObj obj){" name))
					(cgen-body (format "	~a* o = SCM_~a_DATA(obj);" name up-name))
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
		(cgen-extern "#ifndef GAUCHE_STRUCT_CV_H")
		(cgen-extern "#define GAUCHE_STRUCT_CV_H")
		(cgen-extern "SCM_DECL_BEGIN")
		(cgen-extern "")

		(cgen-extern "#include<gauche.h>")
		(cgen-extern "#include<gauche/extend.h>")
		(cgen-extern "#include<gauche/class.h>")
		(cgen-extern "//opencv2 header")
		(cgen-extern "#include<opencv2/core/core_c.h>")
		(cgen-extern "//pre defined header")
		(cgen-extern "#include\"cv_struct_pre_include.h\"")
		(cgen-extern "")

		;;c file header
		(cgen-decl "#include\"cv_struct.gen.h\"")
		(cgen-decl "")

		
		(for-each
			(lambda (s) (gen-struct (car s) (cadr s) (caddr s) (cadddr s) (car (cddddr s))))
			structs)

		(for-each
			(lambda (s) (gen-foreign-pointer (car s) (cadr s) (caddr s) (cadddr s)))
			foreign-pointer)



		(cgen-extern "

typedef struct ScmCvArrRec {
	SCM_HEADER;
	CvArr* data;
}ScmCvArr;

#define SCM_CVARR(obj) ((ScmCvArr*)obj)
#define SCM_CVARR_P(obj) \
				(SCM_XTYPEP(obj, SCM_CLASS_IPLIMAGE) ||	\
				SCM_XTYPEP(obj, SCM_CLASS_CVMAT) ||	\
				SCM_XTYPEP(obj, SCM_CLASS_CVMATND) ||	\
				SCM_XTYPEP(obj, SCM_CLASS_CVSPARSEMAT))

#define SCM_CVARR_DATA(obj) \
				((SCM_CVARR(obj)->data) ? \
						(SCM_CVARR(obj)->data) :	\
						(Scm_Error(\"already been released. object is invalied.\"), NULL))

")

		(cgen-body "

//---------------
//CvArr
//---------------
SCM_DEFINE_BUILTIN_CLASS(Scm_CvArrClass,
							 	NULL, NULL, NULL, NULL, SCM_CLASS_DEFAULT_CPL);
")
		(cgen-init "
			Scm_InitBuiltinClass(&Scm_CvArrClass,
										 	\"<cv-arr>\", NULL, FALSE, mod);
")

		;;generate OpenCv condition type
		(cgen-extern "
typedef struct ScmOpenCvErrorRec {
	ScmError common;
}ScmOpenCvError;
SCM_CLASS_DECL(Scm_OpenCvErrorClass);
#define SCM_CLASS_OPENCV_ERROR (&Scm_OpenCvErrorClass)
")

		(cgen-body "

static void condition_print(ScmObj obj, ScmPort* port, ScmWriteContext* ctx)
{
	ScmClass* k = Scm_ClassOf(obj);
	Scm_Printf(port, \"#<%A \\\"%30.1A\\\">\",
				Scm__InternalClassName(k),
				SCM_ERROR_MESSAGE(obj));
}

static ScmObj condition_allocate(ScmClass* klass, ScmObj initargs)
{
	ScmOpenCvError* e = SCM_ALLOCATE(ScmOpenCvError, klass);
	SCM_SET_CLASS(e, klass);
	SCM_ERROR_MESSAGE(e) = SCM_FALSE;
	return SCM_OBJ(e);
}

static ScmClass* condition_cpl[] = {
	SCM_CLASS_STATIC_PTR(Scm_ErrorClass),
	SCM_CLASS_STATIC_PTR(Scm_MessageConditionClass),
	SCM_CLASS_STATIC_PTR(Scm_SeriousConditionClass),
	SCM_CLASS_STATIC_PTR(Scm_ConditionClass),
	SCM_CLASS_STATIC_PTR(Scm_TopClass),
	NULL
};

SCM_DEFINE_BASE_CLASS(Scm_OpenCvErrorClass, ScmOpenCvError,
				condition_print, NULL, NULL,
				condition_allocate, condition_cpl);
")

		(cgen-init "
	Scm_InitStaticClassWithMeta(SCM_CLASS_OPENCV_ERROR,
					\"<opencv-error>\",
					mod,
					Scm_ClassOf(SCM_OBJ(SCM_CLASS_CONDITION)),
					SCM_FALSE,
					NULL, 0);
")

		(cgen-extern "")
		(cgen-extern "SCM_DECL_END")
		(cgen-extern "#endif")

		(cgen-emit-h (cgen-current-unit))
		(cgen-emit-c (cgen-current-unit))
		(cgen-emit-stub (cgen-current-unit))
		0))



(define structs 
	'(
		(IplImage <iplimage> #t "cvReleaseImage" "&")
		(CvMat <cv-mat> #t "cvReleaseMat" "&")
		(CvMatND <cv-matnd> #t "cvReleaseMatND" "&")
		(CvSparseMat <cv-sparse-mat> #t "cvReleaseSparseMat" "&")
		(CvRect <cv-rect> #f #f "")
		(CvTermCriteria <cv-term-criteria> #f #f "")
		(CvPoint <cv-point> #f #f "")
		(CvPoint2D32f <cv-point-2d32f> #f #f "")
		(CvPoint3D32f <cv-point-3d32f> #f #f "")
		(CvPoint2D64f <cv-point-2d64f> #f #f "")
		(CvPoint3D64f <cv-point-3d64f> #f #f "")
		(CvSize <cv-size> #f #f "")
		(CvSize2D32f <cv-size-2d32f> #f #f "")
		(CvBox2D <cv-box-2d> #f #f "")
		(CvSlice <cv-slice> #f #f "")
		(CvScalar <cv-scalar> #f #f "")
		(CvRNG <cv-rng> #t #f "")

		(CvSeqBlock <cv-seq-block> #t #f "")
		(CvTreeNode <cv-tree-node> #t #f "")
		(CvSeq <cv-seq> #t #f "")
		(CvSet <cv-set> #t #f "")
		(CvGraph <cv-graph> #t #f "")
		(CvChain <cv-chain> #t #f "")
		(CvContour <cv-contour> #t #f "")

		))

(define foreign-pointer 
	'(
		(CvSparseNode <cv-sparse-node> #f "")
		(CvSparseMatIterator <cv-sparse-mat-iterator> #f "")
		(CvMemBlock <cv-mem-block> #f "")
		(CvMemStorage <cv-mem-storage> "cvReleaseMemStorage" "&")
		(CvMemStoragePos <cv-mem-storage-pos> #f "")
		(CvSeqWriter <cv-seq-writer> #f "")
		(CvSeqReader <cv-seq-reader> #f "")
		(CvLineIterator <cv-line-iterator> #f "")
		(CvFont <cv-font> #f "")

		))
