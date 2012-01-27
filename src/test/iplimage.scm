
;;
;;test section for <iplimage>

(test-section "cv.core#<iplimage>")

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

(image 0 0 (make-cv-scalar-all 0))
(test* "(image x y)" (make-cv-scalar-all 0)
  (image 0 0))

