(use cv)
(use gauche.generator)
(use math.mt-random)

(define rand
    (let1 m (make <mersenne-twister>)
          (^n (mt-random-integer m n))))

(define-method object-apply ((sym <symbol>) obj)
  (slot-ref obj sym))

(define (draw-subdiv-point img fp color)
  (cv-circle img (make-cv-point (cv-round ('x fp)) (cv-round ('y fp)))
             3 color -1))

(define (draw-subdiv-edge img edge color)
  (let ([org-pt (cv-subdiv-2d-edge-org edge)]
        [dst-pt (cv-subdiv-2d-edge-dst edge)])
    (when (and org-pt dst-pt)
      (let ([org ('pt org-pt)]
            [dst ('pt dst-pt)])
        (cv-line img
                 (make-cv-point (cv-round ('x org)) (cv-round ('y org)))
                 (make-cv-point (cv-round ('x dst)) (cv-round ('y dst)))
                 color 1 CV_AA 0)))))

(define (draw-subdiv img subdiv delaunay-color voronoi-color)
  (let1 reader (cv-start-read-seq ('edges subdiv))
    (dotimes [i ('total ('edges subdiv))]
      (let1 edge (cv-read-seq-elem-cast <cv-quad-edge-2d> reader)
        (when (cv-is-set-elem? edge)
          (let1 e (cv-cast <cv-subdiv-2d-edge> edge)
            (draw-subdiv-edge img (cv-add-subdiv-2d-edge e 1)
                              voronoi-color)
            (draw-subdiv-edge img e
                              delaunay-color)))))))

(define (locate-point subdiv fp img active-color)
  (receive (ret e0) (cv-subdiv-2d-locate subdiv fp)
    (unless (zero? ('value e0))
      (let1 loop-body (lambda (e) 
                        (draw-subdiv-edge img e active-color)
                        (cv-subdiv-2d-get-edge e CV_NEXT_AROUND_LEFT))
        (let loop ([e (loop-body e0)])
          (unless (equal? e e0)
            (loop (loop-body e)))))))
  (draw-subdiv-point img fp active-color))


(define (draw-subdiv-facet img edge)
  (let1 c (let loop ([t (cv-subdiv-2d-get-edge edge CV_NEXT_AROUND_LEFT)]
                     [c 1])
            (if (equal? t edge)
              c
              (loop (cv-subdiv-2d-get-edge t CV_NEXT_AROUND_LEFT)
                    (+ c 1))))
    (let/cc cont
      (let1 pt-vec (list->vector (take (generator->lseq
                                         (generate (lambda (yield) 
                                                     (let loop ([t edge])
                                                       (let1 pt (cv-subdiv-2d-edge-org t)
                                                         (unless pt 
                                                           (cont #f))
                                                         (yield (make-cv-point (cv-round ('x ('pt pt))) (cv-round ('y ('pt pt)))))
                                                         (loop (cv-subdiv-2d-get-edge t CV_NEXT_AROUND_LEFT)))))))
                                       c))
        (cv-fill-convex-poly img pt-vec (cv-rgb (rand 255)
                                                (rand 255)
                                                (rand 255))
                             CV_AA)
        (cv-poly-line img (vector pt-vec) #t (cv-rgb 0 0 0) 1 CV_AA)
        (draw-subdiv-point img 
                           ('pt (cv-subdiv-2d-edge-dst (cv-subdiv-2d-rotate-edge edge 1)))
                           (cv-rgb 0 0 0))))))

(define (paint-voronoi subdiv img)
  (let ([reader (cv-start-read-seq ('edges subdiv))]
        [total ('total ('edges subdiv))])
    (cv-calc-subdiv-voronoi-2d subdiv)
    (dotimes [i total]
      (let1 edge (cv-read-seq-elem-cast <cv-quad-edge-2d> reader)
        (when (cv-is-set-elem? edge)
          (let1 e (cv-cast <cv-subdiv-2d-edge> edge)
            (draw-subdiv-facet img (cv-subdiv-2d-rotate-edge e 1))
            (draw-subdiv-facet img (cv-subdiv-2d-rotate-edge e 3)))))))
  )

(define rect (make-cv-rect 0 0 600 600))

(let ([active-facet-color (cv-rgb 255 0 0)]
      [delaunay-color (cv-rgb 0 0 0)]
      [voronoi-color (cv-rgb 0 180 0)]
      [bkgnd-color (cv-rgb 255 255 255)]
      [img (make-image ('width rect) ('height rect) 8 3)]
      [storage (make-cv-mem-storage)])
  (cv-set img bkgnd-color)
  (cv-named-window "source")
  (let1 subdiv (cv-create-subdiv-delaunay2d rect storage)
    (let loop ([i 0])
      (let1 fp (make-cv-point-2d32f (+ (rand (- ('width rect) 10)) 5)
                                    (+ (rand (- ('height rect) 10)) 5))
        (locate-point subdiv fp img active-facet-color)
        (cv-show-image "source" img)
        (when (< (cv-wait-key 50) 0)
          (cv-subdiv-delaunay-2d-insert subdiv fp)
          (cv-calc-subdiv-voronoi-2d subdiv)
          (cv-set img bkgnd-color)
          (draw-subdiv img subdiv delaunay-color voronoi-color)
          (cv-show-image "source" img)
          (when (and (< (+ i 1) 400)(< (cv-wait-key 50) 0))
            (loop (+ i 1))))))
    (cv-set img bkgnd-color)
    (paint-voronoi subdiv img)
    (cv-show-image "source" img)
    (cv-wait-key 0)))



