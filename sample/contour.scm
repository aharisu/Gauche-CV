(use cv)

(define-constant size 500)
(define-constant point-count 30)
(define-constant pi 3.141592653589793)

(let* ([img (make-image size size IPL_DEPTH_8U 3)]
       [storage (make-cv-mem-storage)]
       [rng (make-cv-rng)]
       [points (make-cv-seq storage CV_SEQ_POLYLINE)])
  (cv-zero img)
  (let* ([rand-pt (lambda (i)
                    (let1 scale (+ (cv-rand-real rng) 0.5)
                      (make-cv-point
                        (truncate->exact
                          (+ (* (/ (* (cos (/ (* i 2 pi) point-count)) size) 4) scale) (/ size 2)))
                        (truncate->exact
                          (+ (* (/ (* (sin (/ (* i 2 pi) point-count)) size) 4) scale) (/ size 2))))
                      ))]
         [pt0 (rand-pt 0)])
    (cv-circle img pt0 2 (cv-rgb 0 255 0))
    (cv-seq-push points pt0)
    (let loop ([i 1]
               [pt0 pt0])
      (let1 pt1 (rand-pt i)
        (cv-line img pt0 pt1 (cv-rgb 0 255 0) 2)
        (cv-circle img pt1 3 (cv-rgb 0 255 0) -1)
        (cv-seq-push points pt1)
        (when (< (+ i 1) point-count)
          (loop (+ i 1) pt1))))
    (cv-line img (cv-get-seq-elem points (- point-count 1))
             pt0 (cv-rgb 0 255 0) 2))
  (let ([rect (cv-bounding-rect points)]
        [area (cv-contour-area points)]
        [length (cv-arc-length points CV_WHOLE_SEQ 1)]
        [font (make-cv-font CV_FONT_HERSHEY_SIMPLEX 0.7 0.7 0 1 16)])
    (cv-rectangle-r img rect (cv-rgb 255 0 0) 2)
    (cv-put-text img (format #f "Area: wrect=~a,contour=~a" 
                             (* (ref rect 'width) (ref rect 'height))
                             area)
                 (make-cv-point 10 (- (ref img 'height) 30))
                 font (cv-rgb 255 255 255))
    (cv-put-text img (format #f "Length:rect=~a,contour=~a" 
                             (* 2 (+ (ref rect 'width) (ref rect 'height)))
                             length)
                 (make-cv-point 10 (- (ref img 'height) 10))
                 font (cv-rgb 255 255 255)))
  (cv-named-window "contour")
  (cv-show-image "contour" img)
  (cv-wait-key 0))
             

