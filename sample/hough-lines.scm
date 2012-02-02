(use cv)

(define-macro (to-int num)
  `(truncate->exact (round ,num)))

(let* ([src-gray (cv-load-image "data/image/skytree.jpg" CV_LOAD_IMAGE_GRAYSCALE)]
       [src-std (cv-load-image "data/image/skytree.jpg")]
       [src-prob (cv-clone-image src-std)])
  (cv-canny src-gray src-gray 50 200 3)
  (let1 storage (make-cv-mem-storage)
    (let1 lines (cv-hough-lines2 src-gray storage CV_HOUGH_STANDARD 1 (/ 3.14 180) 50)
      (dotimes [i (min (ref lines 'total) 10)]
      (let* ([polar (cv-get-seq-elem lines i)]
             [a (cos (ref polar 'theta))]
             [b (sin (ref polar 'theta))]
             [x0 (* a (ref polar 'rho))]
             [y0 (* b (ref polar 'rho))])
        (cv-line src-std
                 (make-cv-point (to-int (+ x0 (* 1000 (- b))))
                                (to-int (+ y0 (* 1000 a))))
                 (make-cv-point (to-int (- x0 (* 1000 (- b))))
                                (to-int (- y0 (* 1000 a))))
                 (cv-rgb 255 0 0) 1 16))))
    (let1 lines (cv-hough-lines2 src-gray storage CV_HOUGH_PROBABILISTIC 1 (/ 3.14 180) 100 50 15)
      (dotimes [i (ref lines 'total)]
        (let1 pt (cv-get-seq-elem lines i)
          (cv-line src-prob (ref pt 'p1) (ref pt 'p2) (cv-rgb 0 255 0) 1 16)))))
  (cv-show-image "standard" src-std)
  (cv-show-image "proabilistic" src-prob)
  (cv-wait-key 0))



