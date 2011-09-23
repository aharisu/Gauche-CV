;;;
;;; Test gauche-cv
;;;

(use gauche.test)

(test-start "cv")
(use cv)
(test-module 'cv)


;;test for <cv-rect>
(define rect (make-cv-rect 0 0 100 200))
(define rect2 (make-cv-rect 0 0 100 200))
(test* "(equal? rect rect2)" #t
			 (equal? rect rect2))

(test* "(slot-ref rect 'x)" 0
			 (slot-ref rect 'x))
(test* "(slot-ref rect 'y)" 0
			 (slot-ref rect 'y))
(test* "(slot-ref rect 'width)" 100
			 (slot-ref rect 'width))
(test* "(slot-ref rect 'height)" 200
			 (slot-ref rect 'height))
(slot-set! rect 'x 20)
(slot-set! rect 'y 10)
(slot-set! rect 'width 50)
(slot-set! rect 'height 400)
(test* "(slot-ref rect 'x)" 20
			 (slot-ref rect 'x))
(test* "(slot-ref rect 'y)" 10
			 (slot-ref rect 'y))
(test* "(slot-ref rect 'width)" 50
			 (slot-ref rect 'width))
(test* "(slot-ref rect 'height)" 400
			 (slot-ref rect 'height))
(test* "(equal? rect rect2)" #f
			 (equal? rect rect2))


;;test for <cv-scalar>
(define scalar (make-cv-scalar 1 2 3 4))
(define scalar2 (make-cv-scalar 1 2 3 4))
(test* "(equal? scalar scalar2)" #t
			 (equal? scalar scalar2))

(test* "(slot-ref scalar 'val0)" 1.0
			 (slot-ref scalar 'val0))
(test* "(slot-ref scalar 'val1)" 2.0
			 (slot-ref scalar 'val1))
(test* "(slot-ref scalar 'val2)" 3.0
			 (slot-ref scalar 'val2))
(test* "(slot-ref scalar 'val3)" 4.0
			 (slot-ref scalar 'val3))
(slot-set! scalar 'val0 10)
(slot-set! scalar 'val1 20)
(slot-set! scalar 'val2 30)
(slot-set! scalar 'val3 40)
(test* "(slot-ref scalar 'val0)" 10.0
			 (slot-ref scalar 'val0))
(test* "(slot-ref scalar 'val1)" 20.0
			 (slot-ref scalar 'val1))
(test* "(slot-ref scalar 'val2)" 30.0
			 (slot-ref scalar 'val2))
(test* "(slot-ref scalar 'val3)" 40.0
			 (slot-ref scalar 'val3))
(test* "(equal? scalar scalar2)" #f
			 (equal? scalar scalar2))

(set! scalar (make-cv-real-scalar 1))
(test* "(slot-ref scalar 'val0)" 1.0
			 (slot-ref scalar 'val0))
(test* "(slot-ref scalar 'val1)" 0.0
			 (slot-ref scalar 'val1))
(test* "(slot-ref scalar 'val2)" 0.0
			 (slot-ref scalar 'val2))
(test* "(slot-ref scalar 'val3)" 0.0
			 (slot-ref scalar 'val3))
(set! scalar (make-cv-scalar-all 100))
(test* "(slot-ref scalar 'val0)" 100.0
			 (slot-ref scalar 'val0))
(test* "(slot-ref scalar 'val1)" 100.0
			 (slot-ref scalar 'val1))
(test* "(slot-ref scalar 'val2)" 100.0
			 (slot-ref scalar 'val2))
(test* "(slot-ref scalar 'val3)" 100.0
			 (slot-ref scalar 'val3))


;;test for <cv-mat>
(define mat (make-cv-mat 30 40 CV_8UC1))
(test* "(slot-ref mat 'type)" CV_8UC1
			 (slot-ref mat 'type))
(test* "(slot-ref mat 'step)" 40
			 (slot-ref mat 'step))
(test* "(slot-ref mat 'rows)" 30
			 (slot-ref mat 'rows))
(test* "(slot-ref mat 'cols)" 40
			 (slot-ref mat 'cols))
(define mat2 (cv-clone-mat mat))
(test* "(slot-ref mat3 'type)" CV_8UC1
			 (slot-ref mat2 'type))
(test* "(slot-ref mat2 'step)" 40
			 (slot-ref mat2 'step))
(test* "(slot-ref mat2 'rows)" 30
			 (slot-ref mat2 'rows))
(test* "(slot-ref mat2 'cols)" 40
			 (slot-ref mat2 'cols))

(define image (make-image 36 50 IPL_DEPTH_8U 1))
(test* "(slot-ref image 'nChannels)" 1
			 (slot-ref image 'nChannels))
(test* "(slot-ref image 'depth)" IPL_DEPTH_8U
			 (slot-ref image 'depth))
(test* "(slot-ref image 'width)" 36
			 (slot-ref image 'width))
(test* "(slot-ref image 'height)" 50
			 (slot-ref image 'height))
(test* "(slot-ref image 'image-size)" (* 36 50)
			 (slot-ref image 'image-size))
(test* "(slot-ref image 'width-step)" 36
			 (slot-ref image 'width-step))
(test* "(slot-ref image 'roi)" (make-cv-rect 0 0 36 50)
			 (slot-ref image 'roi))

(slot-set! image 'roi (make-cv-rect 5 5 20 20))
(test* "(slot-ref image 'roi)" (make-cv-rect 5 5 20 20)
			 (slot-ref image 'roi))
(cv-set-image-roi image (make-cv-rect 10 10 10 10))
(test* "(slot-ref image 'roi)" (make-cv-rect 10 10 10 10)
			 (slot-ref image 'roi))
(test* "(get-image-roi image)" (make-cv-rect 10 10 10 10)
			 (cv-get-image-roi image))
(cv-reset-image-roi image)
(test* "(get-image-roi image)" (make-cv-rect 0 0 36 50)
			 (cv-get-image-roi image))


(define box (make-cv-box-2d (make-cv-point-2d32f 15 8)
														(make-cv-size-2d32f 20 80)
														0))
(test* "(slot-ref box 'center)" (make-cv-point-2d32f 15 8)
			 (slot-ref box 'center))
(test* "(slot-ref box 'size)" (make-cv-size-2d32f 20 80)
			 (slot-ref box 'size))
(test* "(slot-ref box 'angle)" 0.0
			 (slot-ref box 'angle))
(slot-set! box 'center (make-cv-point-2d32f 8 15))
(slot-set! box 'size (make-cv-size-2d32f 18 35))
(slot-set! box 'angle 10)
(test* "(slot-ref box 'center)" (make-cv-point-2d32f 8 15)
			 (slot-ref box 'center))
(test* "(slot-ref box 'size)" (make-cv-size-2d32f 18 35)
			 (slot-ref box 'size))
(test* "(slot-ref box 'angle)" 10.0
			 (slot-ref box 'angle))
(test* "(equal? box box2)" #f
			 (equal? box (make-cv-box-2d (make-cv-point-2d32f 15 8)
                                   (make-cv-size-2d32f 20 80)
																	 0.0)))
;; epilogue
(test-end)





