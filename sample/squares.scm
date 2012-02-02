(use cv)

(define-constant thresh 50)

(define (angle pt1 pt2 pt0)
  (let ([dx1 (- (ref pt1 'x) (ref pt0 'x))]
        [dy1 (- (ref pt1 'y) (ref pt0 'y))]
        [dx2 (- (ref pt2 'x) (ref pt0 'x))]
        [dy2 (- (ref pt2 'y) (ref pt0 'y))])
    (/. (+ (* dx1 dx2) (* dy1 dy2))
        (sqrt (+ (* (+ (* dx1 dx1) (* dy1 dy1))
                    (+ (* dx2 dx2) (* dy2 dy2)))
                 1e-10)))))

(define-constant n 11)
(define (find-squares4 img storage)
  (let* ([width (logand (ref img 'width) -2)]
         [height (logand (ref img 'height) -2)]
         [timg (cv-clone-image img)]
         [gray (make-image width height IPL_DEPTH_8U 1)]
         [tgray (make-image width height IPL_DEPTH_8U 1)]
         [pyr (make-image (quotient width 2) (quotient height 2) IPL_DEPTH_8U 3)]
         [squares (make-cv-seq storage CV_SEQ_ELTYPE_POINT)])
    (slot-set! timg 'roi (make-cv-rect 0 0 width height))
    (cv-pyr-down timg pyr CV_GAUSSIAN_5x5)
    (cv-pyr-up pyr timg CV_GAUSSIAN_5x5)
    (dotimes [c 3]
      (slot-set! timg 'coi (+ c 1))
      (cv-copy timg tgray)
      (dotimes [l n]
        (if (zero? l)
          (begin
            (cv-canny tgray gray 0 thresh 5)
            (cv-dilate gray gray))
          (cv-threshold tgray gray 
                        (/. (* (+ l 1) 255) n)
                        255 CV_THRESH_BINARY))
        (let loop ([contours (cv-find-contours gray storage CV_RETR_LIST CV_CHAIN_APPROX_SIMPLE)])
          (when contours
            (let1 result (cv-approx-poly contours storage 0 
                                         (* (cv-contour-perimeter contours) 0.02))
              (when (and (eq? (ref result 'total) 4)
                      (> (abs (cv-contour-area result CV_WHOLE_SEQ)) 1000)
                      (cv-check-contour-convexity result))
                (let1 s 0
                  (dotimes [i 5]
                    (when (>= i 2)
                      (let1 t (abs (angle
                                     (cv-get-seq-elem result i)
                                     (cv-get-seq-elem result (- i 2))
                                     (cv-get-seq-elem result (- i 1))))
                        (set! s (if (> s t) s t)))))
                  (when (< s 0.3)
                    (dotimes [i 4]
                      (cv-seq-push squares (cv-get-seq-elem result i)))))))
            (loop (ref contours 'h-next))))))
    (cv-release-image gray)
    (cv-release-image pyr)
    (cv-release-image tgray)
    (cv-release-image timg)
    (cv-seq-pop-multi squares (ref squares 'total) #t)))

(define (draw-squares dst squares)
  (do ([limit (vector-length squares)]
       [i 0 (+ i 4)])
    ([>= i limit] (undefined))
    (cv-poly-line dst
                  (vector (vector
                            (vector-ref squares i)
                            (vector-ref squares (+ i 1))
                            (vector-ref squares (+ i 2))
                            (vector-ref squares (+ i 3))))
                  #t (cv-rgb 0 255 0) 2 16)))


(let* ([img (cv-load-image "data/image/squares.png")]
       [dst (cv-clone-image img)]
       [storage (make-cv-mem-storage)])
  (draw-squares dst (find-squares4 img storage))
  (cv-show-image "Squares" dst)
  (cv-wait-key 0))

