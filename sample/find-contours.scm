(use cv)

(define-constant size 500)

(define-macro (to-int num)
  `(truncate->exact (round ,num)))

(let1 img (make-image size size IPL_DEPTH_8U 1)
  (cv-zero img)
  (dotimes [i 6]
    (let ([dx (to-int (- (* (remainder i 2) 250) 30))]
          [dy (to-int (* (quotient i 2) 150))])
      (when (zero? i)
        (dotimes [j 11]
          (let1 angle (/ (* (+ j 5) 3.14) 21)
            (cv-line img 
                     (make-cv-point (to-int (- (+ dx 100 (* j 10)) (* 80 (cos angle))))
                                    (to-int (- (+ dy 100) (* 90 (sin angle)))))
                     (make-cv-point (to-int (- (+ dx 100 (* j 10)) (* 30 (cos angle))))
                                    (to-int (- (+ dy 100) (* 30 (sin angle)))))
                     (cv-rgb 255 255 255) 1 16))))
      (cv-ellipse img (make-cv-point (+ dx 150) (+ dy 100)) (make-cv-size 100 70) 0 0 360 (cv-rgb 255 255 255) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 115) (+ dy 70)) (make-cv-size 30 20) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 185) (+ dy 70)) (make-cv-size 30 20) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 115) (+ dy 70)) (make-cv-size 15 15) 0 0 360 (cv-rgb 255 255 255) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 185) (+ dy 70)) (make-cv-size 15 15) 0 0 360 (cv-rgb 255 255 255) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 115) (+ dy 70)) (make-cv-size 5 5) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 185) (+ dy 70)) (make-cv-size 5 5) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 150) (+ dy 100)) (make-cv-size 10 5) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 150) (+ dy 150)) (make-cv-size 40 10) 0 0 360 (cv-rgb 0 0 0) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 27) (+ dy 100)) (make-cv-size 20 35) 0 0 360 (cv-rgb 255 255 255) -1 16)
      (cv-ellipse img (make-cv-point (+ dx 273) (+ dy 100)) (make-cv-size 20 35) 0 0 360 (cv-rgb 255 255 255) -1 16)))
  (let* ([storage (make-cv-mem-storage)]
         [contours (cv-approx-poly (cv-find-contours img storage CV_RETR_TREE CV_CHAIN_APPROX_SIMPLE)
                                   storage 0 3 1)])
    (cv-show-image "image" img)
    (cv-named-window "contours")
    (let1 on-trackbar (lambda (pos)
                     (let1 cnt-img (make-image size size IPL_DEPTH_8U 3)
                       (cv-zero cnt-img)
                       (cv-draw-contours cnt-img contours (cv-rgb 255 0 0) (cv-rgb 0 255 0) (- pos 3) 3 16)
                       (cv-show-image "contours" cnt-img)
                       (cv-release-image cnt-img)))
      (cv-create-trackbar "levels+3" "contours" 3 7 on-trackbar)
      (on-trackbar 3)))
  (cv-wait-key 0))


