
;;
;;test section for <cv-mat>

(test-section "cv.core#<cv-mat>")

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

