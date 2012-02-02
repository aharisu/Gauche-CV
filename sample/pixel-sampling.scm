(use cv)
(use gauche.uvector)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst (cv-clone-image src)])
  (cv-get-rect-sub-pix src dst 
                       (make-cv-point-2d32f (- (ref src 'width) -1)
                                            (- (ref src 'height) -1)))
  (cv-show-image "src" src)
  (cv-show-image "dst" dst)
  (cv-wait-key 0))

(define-constant angle 45)
(define-constant pi 3.14)
(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst (cv-clone-image src)]
       [mat (make-cv-mat-from-uvector 2 3 1
              (f32vector (cos (/ (* angle pi) 180))
                              (- (sin (/ (* angle pi) 180)))
                              (* (ref src 'width) 0.5)
                              (sin (/ (* angle pi) 180))
                              (cos (/ (* angle pi) 180))
                              (* (ref src 'height) 0.5)))])
  (cv-get-quadrangle-sub-pix src dst mat)
  (cv-show-image "src" src)
  (cv-show-image "dst" dst)
  (cv-wait-key 0))


