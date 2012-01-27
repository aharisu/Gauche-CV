;;
;;test section for <cv-rect>

(test-section "cv.core#<cv-rect>")

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


