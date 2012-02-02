(use cv)

(let ([img (make-image 640 480 IPL_DEPTH_8U 3)]
      [storage (make-cv-mem-storage)]
      [rng (make-cv-rng)])
  (cv-zero img)
  (let ([points (make-vector 50)])
    (dotimes [i 50]
      (vector-set! points i (make-cv-point
                              (+ (remainder (cv-rand-int rng) (quotient (ref img 'width) 2))
                                 (quotient (ref img 'width) 4))
                              (+ (remainder (cv-rand-int rng) (quotient (ref img 'height) 2))
                                 (quotient (ref img 'height) 4))))
      (cv-circle img (vector-ref points i) 3 (make-cv-scalar 0 255 0) -1))
    ;;use vector
    (cv-rectangle-r img (cv-bounding-rect points) (make-cv-scalar 255 0 0) 2)
    (cv-show-image "bounding-rect" img)
    (cv-wait-key 0)

    ;;use list
    (cv-rectangle-r img (cv-bounding-rect (vector->list points)) (make-cv-scalar 0 255 0) 2)
    (cv-show-image "bounding-rect" img)
    (cv-wait-key 0)

    ;;use <cv-seq>
   (let1 seq (make-cv-seq storage CV_SEQ_ELTYPE_POINT)
      (cv-seq-push-multi seq points)
      (cv-rectangle-r img (cv-bounding-rect seq) (make-cv-scalar 0 0 255) 2)
      (cv-show-image "bounding-rect" img)
      (cv-wait-key 0))
    ))


