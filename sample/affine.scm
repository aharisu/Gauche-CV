(use cv)

(let* ([src (cv-load-image "data/image/skytree.jpg")]
       [dst (cv-clone-image src)]
       [map-matrix (cv-get-affine-transform 
                     (list 
                       (make-cv-point-2d32f 200 200)
                       (make-cv-point-2d32f 250 200)
                       (make-cv-point-2d32f 200 100))
                     (list
                       (make-cv-point-2d32f 300 100)
                       (make-cv-point-2d32f 300 50)
                       (make-cv-point-2d32f 200 100)))])
  (cv-warp-affine src dst map-matrix
                  (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS)
                  (make-cv-scalar-all 0))
  (cv-named-window "src")
  (cv-named-window "dst")
  (cv-show-image "src" src)
  (cv-show-image "dst" dst)
  (cv-wait-key 0))

       

