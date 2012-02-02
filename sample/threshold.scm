(use cv)

(let* ([src-gray (cv-load-image "data/image/lenna.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [dst (make-image (ref src-gray 'width) (ref src-gray 'height) IPL_DEPTH_8U 1)])
  (cv-smooth src-gray src-gray CV_GAUSSIAN 5)
  (cv-named-window "Threshold")
  (let1 callback (lambda (pos)
                   (cv-threshold src-gray dst pos 255 CV_THRESH_BINARY)
                   (cv-show-image "Threshold" dst))
    (cv-create-trackbar "threshold" "Threshold" 90 255 callback)
    (callback 90)
    (cv-wait-key 0)))

