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
;;; The above copyright notice and this permission notice shall be included in all ;;; copies or substantial portions of the Software.
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
              (cgen-extern "#include <opencv2/objdetect/objdetect.hpp>")
              (cgen-extern "")
              )
              (lambda () ;;epilogue
                ))
            0)

;;sym-name sym-scm-type pointer? finalize-name finalize-ref
(define structs 
  '(
    (CvHaarClassifierCascade <cv-haar-classifier-cascade> #t "cvReleaseHaarClassifierCascade" "&")
    (CvAvgComp <cv-avg-comp> #f #f "")
    (CvLSVMFilterPosition <cv-lsvm-filter-position> #f #f "")
    (CvLatentSvmDetector <cv-latent-svm-detector> #t "cvReleaseLatentSvmDetector" "&")
    (CvObjectDetection <cv-object-detection> #f #f "")
    ))

;;sym-name sym-scm-type ponter? finalize finalize-ref
(define foreign-pointer 
  '(
    ))
