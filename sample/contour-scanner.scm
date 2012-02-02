(use cv)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [gray (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [canny (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [result (cv-clone-image src)])
  (cv-cvt-color src gray CV_BGR2GRAY)
  (cv-canny gray canny 50 200)
  (let* ([storage (make-cv-mem-storage)]
         [scanner (cv-start-find-contours canny storage CV_RETR_TREE CV_CHAIN_APPROX_SIMPLE)])
    (let loop ([c (cv-find-next-contour scanner)])
      (when c
        (cv-draw-contours result c (cv-rgb 255 0 0) (cv-rgb 0 255 0) 0 3 16)
        (loop (cv-find-next-contour scanner))))
    (cv-end-find-contours scanner))
  (cv-named-window "ContourScanner canny")
  (cv-show-image "ContourScanner canny" canny)
  (cv-named-window "ContourScanner result")
  (cv-show-image "ContourScanner result" result)
  (cv-wait-key 0))



