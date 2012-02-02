(use cv)

(define-macro (to-int num)
  `(truncate->exact ,num))

(let* ([src (cv-load-image "data/image/items.jpg")]
       [gray (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 1)]
       [hough (cv-clone-image src)])
  (cv-cvt-color src gray CV_BGR2GRAY)
  (cv-smooth gray gray CV_GAUSSIAN 9)
  (let* ([storage (make-cv-mem-storage)]
         [seq (cv-hough-circles gray storage CV_HOUGH_GRADIENT 1 100 150 55 0 0)])
    (dotimes [i (ref seq 'total)]
      (let1 pt (cv-get-seq-elem seq i)
        (cv-circle src (make-cv-point (to-int (ref pt 'x)) (to-int (ref pt 'y)))
                   3 (cv-rgb 0 255 0) -1 8)
        (cv-circle src (make-cv-point (to-int (ref pt 'x)) (to-int (ref pt 'y)))
                   (to-int (ref pt 'z)) (cv-rgb 255 0 0) 3 8))))
  (cv-show-image "circles" src)
  (cv-wait-key 0))


