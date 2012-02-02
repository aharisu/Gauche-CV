(use cv)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst1 (make-image (quotient (ref src 'width) 2) (quotient (ref src 'height) 2) (ref src 'depth) (ref src 'n-channels))]
       [dst2 (make-image (* (ref src 'width) 2) (* (ref src 'height) 2) (ref src 'depth) (ref src 'n-channels))])
  (cv-pyr-down src dst1 CV_GAUSSIAN_5x5)
  (cv-pyr-up src dst2 CV_GAUSSIAN_5x5)
  (cv-show-image "original" src)
  (cv-show-image "PyrDown" dst1)
  (cv-show-image "PyrUp" dst2)
  (cv-wait-key 0))
