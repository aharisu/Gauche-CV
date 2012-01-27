
;;
;;test section for <cv-box-2d>

(test-section "cv.core#<cv-box-2d>")

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
