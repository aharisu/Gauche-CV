(use cv)
(use gauche.collection)

(define-constant size 500)

(print "ESC - quit the program")

(cv-named-window "hull")
(let* ([img (make-image size size IPL_DEPTH_8U 3)]
       [rng (make-cv-rng (sys-time))])
  (let loop ([count (+ (remainder (cv-rand-int rng) 100) 1)])
    (cv-zero img)
    (let1 ptseq (make-vector count)
      (dotimes [i count]
        (vector-set! ptseq i (make-cv-point
                               (+ (remainder (cv-rand-int rng) (quotient (ref img 'width) 2))
                                  (quotient (ref img 'width) 4))
                               (+ (remainder (cv-rand-int rng) (quotient (ref img 'height) 2))
                                  (quotient (ref img 'height) 4))))
        (cv-circle img (vector-ref ptseq i) 2 (cv-rgb 255 0 0) -1))
      ;;use vector
      (let* ([hull (cv-convex-hull2 ptseq CV_CLOCKWISE)]
             [pt0 (vector-ref hull (- (vector-length hull) 1))])
        (for-each 
          (lambda (pt)
            (cv-line img pt0 pt (cv-rgb 0 255 0))
            (set! pt0 pt))
          hull))
      ;;use list
      #;(let* ([hull (cv-convex-hull2 (vector->list ptseq) CV_CLOCKWISE)]
             [pt0 (vector-ref hull (- (vector-length hull) 1))])
        (for-each 
          (lambda (pt)
            (cv-line img pt0 pt (cv-rgb 0 255 0))
            (set! pt0 pt))
          hull))
      ;;use <cv-seq>
      #;(let* ([storage (make-cv-mem-storage)]
             [seq (make-cv-seq storage CV_SEQ_ELTYPE_POINT)])
        (cv-seq-push-multi seq ptseq)
        (let* ([hull (cv-convex-hull2 seq CV_CLOCKWISE)]
               [pt0 (vector-ref hull (- (vector-length hull) 1))])
          (for-each 
            (lambda (pt)
              (cv-line img pt0 pt (cv-rgb 0 255 0))
              (set! pt0 pt))
            hull)))
      (cv-show-image "hull" img)
      (unless (eqv? (cv-wait-key 0) 27) ;ESC
        (loop (+ (remainder (cv-rand-int rng) 100) 1))))))

