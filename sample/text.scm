(use cv)
(use gauche.sequence)


(let ([img (make-image 450 600 IPL_DEPTH_8U 3)]
      [rng (make-cv-rng (sys-time))])
  (cv-zero img)
  (for-each-with-index
    (lambda (i font)
      (cv-put-text img "OpenCV sample code"
                   (make-cv-point 15 (* (+ i 1) 30))
                   font
                   (cv-rgb (remainder (cv-rand-int rng) 256)
                           (remainder (cv-rand-int rng) 256)
                           (remainder (cv-rand-int rng) 256))))
    (fold 
      (lambda (font acc)
        (cons 
          (make-cv-font font 1 1)
          (cons 
            (make-cv-font (logior font CV_FONT_ITALIC) 1 1)
            acc)))
      '()
      (list CV_FONT_HERSHEY_SIMPLEX
            CV_FONT_HERSHEY_PLAIN
            CV_FONT_HERSHEY_DUPLEX
            CV_FONT_HERSHEY_COMPLEX
            CV_FONT_HERSHEY_TRIPLEX
            CV_FONT_HERSHEY_COMPLEX_SMALL
            CV_FONT_HERSHEY_SCRIPT_SIMPLEX
            CV_FONT_HERSHEY_SCRIPT_COMPLEX
            CV_FONT_VECTOR0)))
  (cv-show-image "Font sample" img)
  (cv-wait-key 0))


