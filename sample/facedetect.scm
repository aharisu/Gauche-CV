(use cv)
(use cv.objdetect)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [gray (make-image (slot-ref src 'width)
                         (slot-ref src 'height)
                         IPL_DEPTH_8U 1)]
       [cascade (cv-cast <cv-haar-classifier-cascade> 
                         (cv-load "data/data/haarcascade_frontalface_default.xml"))]
       [storage (make-cv-mem-storage)])
  (cv-clear-mem-storage storage)
  (cv-cvt-color src gray CV_BGR2GRAY)
  (cv-equalize-hist gray gray)
  ;;detect object
  (let1 face (cv-haar-detect-objects gray cascade storage 1.11 4 0 (make-cv-size 40 40))
    (dotimes [i (slot-ref face 'total)]
      (let1 r (slot-ref (cv-get-seq-elem-cast <cv-avg-comp> face i) 'rect)
        (cv-circle src 
                   (make-cv-point (+ (slot-ref r 'x) (quotient (slot-ref r 'width) 2))
                                  (+ (slot-ref r 'y) (quotient (slot-ref r 'height) 2)))
                   (quotient (+ (slot-ref r 'width) (slot-ref r 'height)) 4)
                   (make-cv-scalar-all 255)
                   3 8 0))))
  (cv-show-image "Face Detection" src)
  (cv-wait-key 0))





