(use cv)

(let* ([src (cv-load-image "data/image/fruits.jpg")]
       [dst (make-image (ref src 'width) (ref src 'height) (ref src 'depth) (ref src 'n-channels))]
       [kernel (make-cv-mat 1 21 CV_32FC1)])
  (cv-set-data kernel #f32(2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 1) CV_AUTO_STEP)
  (cv-normalize kernel kernel 1 0 CV_L1)
  (cv-filter-2d src dst kernel (make-cv-point 0 0))
  (cv-show-image "src" src)
  (cv-show-image "Filter 2D" dst)
  (cv-wait-key 0))



