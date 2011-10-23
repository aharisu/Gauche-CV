(add-load-path ".")
(load "cv_struct_generator")

(use file.util)

(define (main args)
  (gen-type (simplify-path (path-sans-extension (car args)))
            structs foreign-pointer
            (lambda () ;;prologue
              (cgen-extern "//opencv2 header")
              (cgen-extern "#include<opencv2/imgproc/imgproc_c.h>")
              (cgen-extern "")
              
              (cgen-extern "
typedef struct CvFeatureTree CvFeatureTree;
typedef struct CvLSH CvLSH;
")
              )
            (lambda () ;;epilogue
              ))
  0)

;;sym-name sym-scm-type pointer? finalize-name finalize-ref
(define structs 
  '(
    ;;imgproc types_c.h
    (CvMoments <cv-moments> #f #f "")
    (CvHuMoments <cv-hu-moments> #f #f "")
    (CvSubdiv2D <cv-subdiv-2d> #t #f "")
    (CvSubdiv2DPoint <cv-subdiv-2d-point> #t #f "")
    (CvConnectedComp <cv-connected-comp> #f #f "")
    ))

;;sym-name sym-scm-type ponter? finalize finalize-ref
(define foreign-pointer 
  '(
    (IplConvKernel <iplconv-kernel> #t "cvReleaseStructuringElement" "&")
    (CvContourScanner <cv-contour-scanner> #f #f "")
    (CvChainPtReader <cv-chain-pt-reader> #t #f "&")
    (CvFeatureTree <cv-feature-tree> #t "cvReleaseFeatureTree" "")
    (CvLSH <cv-lsh> #t "cvReleaseLSH" "&")

    ))
