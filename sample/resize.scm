(use cv)

(let* ([src (cv-load-image "data/image/shape.png")]
       [width (* (ref src 'width) 4)]
       [height (* (ref src 'width) 4)]
       [dst-nn (make-image width height (ref src 'depth) (ref src 'n-channels))]
       [dst-cubic (make-image width height (ref src 'depth) (ref src 'n-channels))]
       [dst-linear (make-image width height (ref src 'depth) (ref src 'n-channels))]
       [dst-lanczos (make-image width height (ref src 'depth) (ref src 'n-channels))])
  (cv-resize src dst-nn CV_INTER_NN)
  (cv-resize src dst-cubic CV_INTER_CUBIC)
  (cv-resize src dst-linear CV_INTER_LINEAR)
  (cv-resize src dst-lanczos CV_INTER_LANCZOS4)

  (cv-show-image "src" src)
  (cv-show-image "NearestNeighbor" dst-nn)
  (cv-show-image "Cubic" dst-cubic)
  (cv-show-image "Linear" dst-linear)
  (cv-show-image "Lanczos4" dst-lanczos)
  (cv-wait-key 0))

