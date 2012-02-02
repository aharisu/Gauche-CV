(use cv)
(use gauche.collection)
(use gauche.uvector)

(define-macro (to-int val)
  `(truncate->exact (round ,val)))

(define (calc-lut contrast brightness)
  (let* ([delta (/ (* (if (> contrast 0) 127 -128) contrast) 100)]
         [a (if (> contrast 0) (/ 255 (- 255 (* delta 2))) (/ (- 256 (* delta 2)) 255))]
         [b (if (> contrast 0) (* a (- brightness delta)) (+ (* a brightness) delta))])
    (with-builder (<u8vector> add! get :size 256)
      (dotimes [i 256]
        (add! (let1 v (to-int (+ (* a i) b))
                (cond
                  [(< v 0) 0]
                  [(> v 255) 255]
                  [else v]))))
      (get))))

(define (calc-hist img hist)
  (cv-calc-hist img hist)
  (receive (min max)
    (cv-get-minmax-hist-value hist)
    (cv-scale (ref hist 'bins) (ref hist 'bins) (/ (ref img 'height) max) 0)))

(define (draw-hist img hist hist-size)
  (cv-set img (cv-rgb 255 255 255))
  (let1 bin-w (to-int (/ (ref img 'width) hist-size))
    (dotimes [i hist-size]
      (cv-rectangle img
                    (make-cv-point (* i bin-w) (ref img 'height))
                    (make-cv-point (* (+ i 1) bin-w)
                                   (- (ref img 'height) 
                                      (to-int (cv-get-real1d (ref hist 'bins) i))))
                    (cv-rgb 0 0 0)
                    -1 16))))


(define-constant hist-size 64)

(let* ([src (cv-load-image "data/image/lenna.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [dst (cv-clone-image src)]
       [hist-image (make-image 400 400 IPL_DEPTH_8U 1)]
       [hist (cv-create-hist (s32vector hist-size) CV_HIST_ARRAY
                             (vector (f32vector 0 256))
                             #t)])
  (cv-named-window "image")
  (cv-named-window "histogram")
  (let1 callback (lambda (pos)
                   (let ([brightness (- (cv-get-trackbar-pos "brightness" "image") 100)]
                         [contrast (- (cv-get-trackbar-pos "contrast" "image") 100)])
                     ;;apply lut
                     (cv-lut src dst (calc-lut contrast brightness))
                     ;;draw histogram
                     (calc-hist dst hist)
                     (draw-hist hist-image hist hist-size)
                     ;;show
                     (cv-show-image "image" dst)
                     (cv-show-image "histogram" hist-image)
                     (cv-zero dst)
                     (cv-zero hist-image)
                     ))
    (cv-create-trackbar "brightness" "image" 100 200 callback)
    (cv-create-trackbar "contrast" "image" 100 200 callback)
    ;;first draw
    (callback 0)
    ;;wait
    (cv-wait-key 0)))


