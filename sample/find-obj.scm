(use cv)
(use cv.features2d)
(use cv.calib3d)
(use gauche.sequence)
(use gauche.uvector)
(use srfi-1)
(use srfi-11)

(define (compare-surf-descriptors d1 d2 best len)
  (let loop ([total-cost 0]
             [i 0])
    (if (or (> total-cost best) (>= i len))
      total-cost
      (loop (+ total-cost
               (expt (- (f32vector-ref d1 i) (f32vector-ref d2 i)) 2)
               (expt (- (f32vector-ref d1 (+ i 1)) (f32vector-ref d2 (+ i 1))) 2)
               (expt (- (f32vector-ref d1 (+ i 2)) (f32vector-ref d2 (+ i 2))) 2)
               (expt (- (f32vector-ref d1 (+ i 3)) (f32vector-ref d2 (+ i 3))) 2))
            (+ i 4)))))

(define (naive-nearest-neighbor vec laplacian
                                model-keypoints
                                model-descriptors)
  (let ([len (quotient (ref model-descriptors 'elem-size) 4)]
        [total (ref model-descriptors 'total)]
        [kreader (cv-start-read-seq model-keypoints)]
        [reader (cv-start-read-seq model-descriptors)])
    (let loop ([i 0]
               [dist1 1e6]
               [dist2 1e6]
               [neighbor #f])
      (if (< i total)
        (if (eq? laplacian (ref (cv-read-seq-elem-cast <cv-surf-point> kreader) 'laplacian))
          (let1 d (compare-surf-descriptors vec 
                                            (cv-read-seq-elem-cast <f32vector> reader)
                                            dist2 len)
            (cond
              [(< d dist1) (loop (+ i 1) d dist1 i)]
              [(< d dist2) (loop (+ i 1) dist1 d neighbor)]
              [else (loop (+ i 1) dist1 dist2 neighbor)]))
          (begin
            (cv-next-seq-elem reader)
            (loop (+ i 1) dist1 dist2 neighbor)))
        (if (< dist1 (* 0.6 dist2))
          neighbor
          #f)))))


(define (find-pairs object-keypoints object-descriptors
                    image-keypoints image-descriptors)
  (let ([kreader (cv-start-read-seq object-keypoints)]
        [reader (cv-start-read-seq object-descriptors)]
        [total (ref object-descriptors 'total)])
    (let loop ([i 0]
               [c1 '()]
               [c2 '()])
      (if (< i total)
        (let1 nn (naive-nearest-neighbor (cv-read-seq-elem-cast <f32vector> reader)
                                         (ref (cv-read-seq-elem-cast <cv-surf-point> kreader) 'laplacian)
                                         image-keypoints image-descriptors)
          (if nn
            (loop (+ i 1) (cons i c1) (cons nn c2))
            (loop (+ i 1) c1 c2)))
        (values (reverse c1) (reverse c2))))))


(define (locate-planar-object object-keypoints object-descriptors
                              image-keypoints image-descriptors
                              src-cornners)
  (receive (pt-i1 pt-i2) 
    (find-pairs object-keypoints object-descriptors image-keypoints image-descriptors)
    (if (< (length pt-i2) 4)
      #f
      (let ([generator (lambda (seq indices)
                         (list->f32vector 
                           (reverse (fold
                                      (lambda (i acc)
                                        (let1 pt (ref (cv-get-seq-elem-cast <cv-surf-point> seq i) 'pt)
                                          (cons (ref pt 'y) (cons (ref pt 'x) acc))))
                                      '()
                                      indices))))]
            [h (make-cv-mat 3 3 CV_64FC1)])
        (if (cv-find-homography 
              (make-cv-mat-from-uvector 1 (length pt-i1) 2 
                                        (generator object-keypoints pt-i1))
              (make-cv-mat-from-uvector 1 (length pt-i2) 2 
                                        (generator image-keypoints pt-i2))
              h CV_RANSAC 5)
          (map
            (lambda (pt)
              (let ([x (ref pt 'x)]
                    [y (ref pt 'y)])
                (let1 z (/ 1.0 (+ (* (cv-m-get h 2 0) x)
                                  (* (cv-m-get h 2 1) y)
                                  (cv-m-get h 2 2)))
                  (make-cv-point (cv-round (* (+ (* (cv-m-get h 0 0) x)
                                                 (* (cv-m-get h 0 1) y)
                                                 (cv-m-get h 0 2))
                                              z))
                                 (cv-round (* (+ (* (cv-m-get h 1 0) x)
                                                 (* (cv-m-get h 1 1) y)
                                                 (cv-m-get h 1 2))
                                              z))))))
            src-cornners)
          #f)))))


(let* ([storage (make-cv-mem-storage)]
       [object (cv-load-image "data/image/box.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [image (cv-load-image "data/image/box_in_scene.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [object-color (make-image (ref object 'width) (ref object 'height)
                                 8 3)]
       [params (cv-surf-params 500 1)]
       [correspond (make-image (ref image 'width) (+ (ref image 'height)
                                                     (ref object 'height))
                               8 1)])
  (cv-cvt-color object object-color CV_GRAY2BGR)
  (let-values ([(object-keypoints object-descriptors)
                (cv-extract-srfi-with-descriptors object c:null storage params)]
               [(image-keypoints image-descriptors)
                (cv-extract-srfi-with-descriptors image c:null storage params)])
    (cv-set-image-roi correspond (make-cv-rect 0 0 (ref object 'width) (ref object 'height)))
    (cv-copy object correspond)
    (cv-set-image-roi correspond (make-cv-rect 0 (ref object 'height) (ref correspond 'width) (ref correspond 'height)))
    (cv-copy image correspond)
    (cv-reset-image-roi correspond)

    (if-let1 dst-corners (locate-planar-object object-keypoints object-descriptors image-keypoints image-descriptors
                                               (list (make-cv-point 0 0)
                                                     (make-cv-point (ref object 'width) 0)
                                                     (make-cv-point (ref object 'width) (ref object 'height))
                                                     (make-cv-point 0 (ref object 'height))))
      (let1 dst-vec (list->vector dst-corners)
        (dotimes [i 4]
          (let ([r1 (ref dst-vec (remainder i 4))]
                [r2 (ref dst-vec (remainder (+ i 1) 4))])
            (cv-line correspond (make-cv-point (ref r1 'x) (+ (ref r1 'y) (ref object 'height)))
                     (make-cv-point (ref r2 'x) (+ (ref r2 'y) (ref object 'height)))
                     (cv-rgb 255 255 255))))))

    (receive (pt-i1 pt-i2)
      (find-pairs object-keypoints object-descriptors
                  image-keypoints image-descriptors)
      (for-each
        (lambda (v1 v2)
          (let ([r1 (cv-get-seq-elem-cast <cv-surf-point> object-keypoints v1)]
                [r2 (cv-get-seq-elem-cast <cv-surf-point> image-keypoints v2)])
            (cv-line correspond (make-cv-point
                                  (cv-round (ref (ref r1 'pt) 'x))
                                  (cv-round (ref (ref r1 'pt) 'y)))
                     (make-cv-point
                       (cv-round (ref (ref r2 'pt) 'x))
                       (cv-round (+ (ref (ref r2 'pt) 'y)
                                    (ref object 'height))))
                     (cv-rgb 255 255 255))))
        pt-i1 pt-i2))
    (cv-show-image "Object Correspoind" correspond)

    (dotimes [i (ref object-keypoints 'total)]
      (let1 r (cv-get-seq-elem-cast <cv-surf-point> object-keypoints i)
        (cv-circle object-color
                   (make-cv-point (cv-round (ref (ref r 'pt) 'x))
                                  (cv-round (ref (ref r 'pt) 'y)))
                   (cv-round (* (/ (* (ref r 'size) 1.2) 9) 2))
                   (cv-rgb 0 0 255) 1 8 0)))
    (cv-show-image "Object" object-color) 
    (cv-wait-key 0))
  )

