(use cv)

(let* ([src (cv-load-image "data/image/lenna.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [dst (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_32F 1)]
       [dst-norm (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)])
  (cv-dist-transform src dst CV_DIST_L2 3)
  (cv-normalize dst dst-norm 0 255 CV_MINMAX)
  (cv-named-window "Source")
  (cv-show-image "Source" src)
  (cv-named-window "Distance Image")
  (cv-show-image "Distance Image" dst-norm)
  (cv-wait-key 0))

