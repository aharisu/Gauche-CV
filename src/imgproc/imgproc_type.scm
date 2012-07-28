;;;
;;; imgproc_type.scm
;;;
;;; MIT License
;;; Copyright 2011-2012 aharisu
;;; All rights reserved.
;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy
;;; of this software and associated documentation files (the "Software"), to deal
;;; in the Software without restriction, including without limitation the rights
;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;;; copies of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in all
;;; copies or substantial portions of the Software.
;;;
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;;; SOFTWARE.
;;;
;;;
;;; aharisu
;;; foo.yobina@gmail.com
;;;

(add-load-path ".")
(load "cv_struct_generator")

(use file.util)

(define (main args)
  (gen-type (simplify-path (path-sans-extension (car args)))
            structs foreign-pointer
            (lambda () ;;prologue
              (cgen-extern "#include \"../core_type.gen.h\"")
              (cgen-extern "#include \"../gauche_cv_core.h\"")
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

    (CvQuadEdge2D <cv-quad-edge-2d> #t #f "")

    (CvSubdiv2D <cv-subdiv-2d> #t #f "")
    (CvSubdiv2DPoint <cv-subdiv-2d-point> #t #f "")
    (CvConnectedComp <cv-connected-comp> #f #f "")

    (CvSubdiv2DEdge <cv-subdiv-2d-edge> #f #f "")
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
