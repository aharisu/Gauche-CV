(use cv)

(let* ([src (cv-load-image "data/image/items.jpg")]
       [gray (make-image (slot-ref src 'width)
                         (slot-ref src 'height)
                         IPL_DEPTH_8U 1)])
  (cv-cvt-color src gray CV_BGR2GRAY)
  (cv-set-image-roi gray (make-cv-rect 0 0 
                                       (quotient (slot-ref gray 'width) 2)
                                       (quotient (slot-ref gray 'height) 2)))
  (cv-threshold gray gray 90 255 CV_THRESH_BINARY)
  (cv-reset-image-roi gray)
  (cv-save "image.xml" gray)
  (cv-show-image "src" gray)
  (cv-wait-key 0))

