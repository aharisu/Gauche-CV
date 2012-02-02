(use cv)

(let* ([src (cv-load-image "data/image/fruits.jpg")]
       [log (make-image 256 256 IPL_DEPTH_8U 3)]
       [linear (make-image 256 256 IPL_DEPTH_8U 3)]
       [recoverd1 (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 3)]
       [recoverd2 (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 3)])
  (cv-log-polar src log (make-cv-point-2d32f (/ (ref src 'width) 2) (/ (ref src 'height) 2))
                40 (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS))
  (cv-log-polar log recoverd1 (make-cv-point-2d32f (/ (ref src 'width) 2) (/ (ref src 'height) 2))
                40 (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS CV_WARP_INVERSE_MAP))

  (cv-linear-polar src linear (make-cv-point-2d32f (/ (ref src 'width) 2) (/ (ref src 'height) 2))
                   (ref linear 'width) (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS))
  (cv-linear-polar linear recoverd2 (make-cv-point-2d32f (/ (ref src 'width) 2) (/ (ref src 'height) 2))
                   (ref linear 'width) (logior CV_INTER_LINEAR CV_WARP_FILL_OUTLIERS CV_WARP_INVERSE_MAP))

  (cv-show-image "log-polar" log)
  (cv-show-image "inverse log-polar" recoverd1)
  (cv-show-image "linear-polar" linear)
  (cv-show-image "inverse linear-polar" recoverd2)
  (cv-wait-key 0))


