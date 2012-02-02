(use cv)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst (cv-clone-image src)]
       [map-matrix (cv-get-perspective-transform
                     (vector
                       (make-cv-point-2d32f 150 150)
                       (make-cv-point-2d32f 150 300)
                       (make-cv-point-2d32f 350 300)
                       (make-cv-point-2d32f 350 150))
                     (vector
                       (make-cv-point-2d32f 200 200)
                       (make-cv-point-2d32f 150 300)
                       (make-cv-point-2d32f 350 300)
                       (make-cv-point-2d32f 300 200)))])
  (cv-warp-perspective src dst map-matrix 
                       (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS)
                       (make-cv-scalar-all 100))
  (cv-show-image "src" src)
  (cv-show-image "dst" dst)
  (cv-wait-key 0))




