(add-load-path ".")
(load "cv_struct_generator")

(use file.util)

(define (main args)
  (gen-type (simplify-path (path-sans-extension (car args)))
            structs foreign-pointer
            (lambda () ;;prologue
              (cgen-extern "//opencv2 header")
              (cgen-extern "#include<opencv2/core/core_c.h>")
              (cgen-extern "#include<opencv2/highgui/highgui_c.h>")
              (cgen-extern "#include<opencv2/imgproc/imgproc_c.h>")
              (cgen-extern "//pre defined header")
              (cgen-extern "#include\"cv_struct_pre_include.h\"")
              (cgen-extern "
                           //original type
                           typedef struct CvLineSegmentPolarRec {
                           float rho;
                           float theta;
                           }CvLineSegmentPolar;

                           //original type
                           typedef struct CvLineSegmentPointRec {
                           CvPoint p1;
                           CvPoint p2;
                           }CvLineSegmentPoint;
                           ")
              (cgen-extern ""))
            (lambda () ;;epilogue
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
                                                                SCM_XTYPEP(obj, SCM_CLASS_CVSPARSEMAT) || \
                                                                SCM_ISA(obj, SCM_CLASS_CVTREENODE))

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
                                      ")))

                           0)


;;sym-name sym-scm-type pointer? finalize-name finalize-ref
(define structs 
  '(
    (IplImage <iplimage> #t "cvReleaseImage" "&")
    (CvMat <cv-mat> #t "cvReleaseMat" "&")
    (CvMatND <cv-matnd> #t "cvReleaseMatND" "&")
    (CvSparseMat <cv-sparse-mat> #t "cvReleaseSparseMat" "&")
    (CvRect <cv-rect> #f #f "")
    (CvHistogram <cv-histogram> #t "cvReleaseHist" "&")
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

    (CvLineSegmentPolar <cv-line-segment-polar> #f #f "")
    (CvLineSegmentPoint <cv-line-segment-point> #f #f "")
    ))

;;sym-name sym-scm-type pointer? finalize finalize-ref 
(define foreign-pointer 
  '(
    (CvSparseNode <cv-sparse-node> #t #f "")
    (CvSparseMatIterator <cv-sparse-mat-iterator> #t #f "")
    (CvMemBlock <cv-mem-block> #t #f "")
    (CvMemStorage <cv-mem-storage> #t "cvReleaseMemStorage" "&")
    (CvMemStoragePos <cv-mem-storage-pos> #t #f "")
    (CvSeqWriter <cv-seq-writer> #t #f "")
    (CvSeqReader <cv-seq-reader> #t #f "")
    (CvLineIterator <cv-line-iterator> #t #f "")
    (CvFont <cv-font> #t #f "")
    (CvCapture <cv-capture> #t "cvReleaseCapture" "&")
    ))
