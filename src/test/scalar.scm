
;;
;;test section for <cv-scalr>

(test-section "cv.core#<cv-scalar>")

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

