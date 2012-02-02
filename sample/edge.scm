(use cv)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [gray (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [temp (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_16S 1)]
       [dst-sobel (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [dst-laplace (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [dst-canny (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)])
  (cv-cvt-color src gray CV_BGR2GRAY)
  ;;sobel
  (cv-sobel gray temp 1 0 3)
  (cv-convert-scale-abs temp dst-sobel)
  ;;laplace
  (cv-laplace gray temp 3)
  (cv-convert-scale-abs temp dst-laplace)
  ;;canny
  (cv-canny gray dst-canny 50 200 3)

  (cv-show-image "src" src)
  (cv-show-image "sobel" dst-sobel)
  (cv-show-image "laplace" dst-laplace)
  (cv-show-image "canny" dst-canny)
  (cv-wait-key 0))

