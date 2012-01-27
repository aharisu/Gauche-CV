;;;
;;; Test gauche-cv
;;;

(use gauche.test)

(test-start "cv.core")
(use cv.core)
(test-module 'cv.core)


;;test for <cv-rect>
(load "test/rect.scm")


;;test for <cv-scalar>
(load "test/scalar.scm")


;;test for <cv-mat>
(load "test/mat.scm")


;;test for <iplimage>
(load "test/iplimage.scm")


;;test for <cv-seq>
(load "test/seq.scm")


;;test for <cv-box-2d>
(load "test/box-2d.scm")

;;test for <cvarr>
(load "test/cvarr.scm")

;; epilogue
(test-end)



