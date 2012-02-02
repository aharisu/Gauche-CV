(use cv)
(use gauche.collection)

(define-constant corner-count 100)

(let* ([dst1 (cv-load-image "data/image/lenna.png")]
       [dst2 (cv-clone-image dst1)]
       [src-gray (cv-load-image "data/image/lenna.png" CV_LOAD_IMAGE_GRAYSCALE)]
       [eig (make-image (ref src-gray 'width) (ref src-gray 'height) IPL_DEPTH_32F 1)]
       [temp (make-image (ref src-gray 'width) (ref src-gray 'height) IPL_DEPTH_32F 1)])
  ;;use cvCornerMinEigenVal
  (let1 corners (cv-good-features-to-track src-gray eig temp corner-count 0.1 15) 
    (cv-find-corner-sub-pix src-gray corners (make-cv-size 3 3) (make-cv-size -1 -1)
                            (make-cv-term-criteria (logior CV_TERMCRIT_ITER CV_TERMCRIT_EPS)
                                                   20 0.03))
    (for-each
      (lambda (pt)
        (cv-circle dst1 (make-cv-point
                          (truncate->exact (ref pt 'x))
                          (truncate->exact (ref pt 'y)))
                   3 (cv-rgb 255 0 0) 2))
      corners))
  ;;use cvCornerHarris
  (let1 corners (cv-good-features-to-track src-gray eig temp corner-count 0.1 15 '() 3 #t 0.01)
    (cv-find-corner-sub-pix src-gray corners (make-cv-size 3 3) (make-cv-size -1 -1)
                            (make-cv-term-criteria (logior CV_TERMCRIT_ITER CV_TERMCRIT_EPS)
                                                   20 0.03))
    (for-each
      (lambda (pt)
        (cv-circle dst2 (make-cv-point
                          (truncate->exact (ref pt 'x))
                          (truncate->exact (ref pt 'y)))
                   3 (cv-rgb 0 0 255) 2))
      corners))
  (cv-named-window "Eigen Val")
  (cv-show-image "Eigen Val" dst1)
  (cv-named-window "Harris")
  (cv-show-image "Harris" dst2)
  (cv-wait-key 0))


