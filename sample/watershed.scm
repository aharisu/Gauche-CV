(use cv)

(let* ([src (cv-load-image "data/image/skytree.jpg")]
       [dst (cv-clone-image src)]
       [dsp (cv-clone-image src)]
       [markers (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_32S 1)])
  (cv-zero markers)
  (cv-named-window "image")
  (cv-show-image "image" src)
  (cv-set-mouse-callback 
    "image" 
    (let1 seed-num 0
      (lambda (event x y flags)
        (when (eq? event CV_EVENT_LBUTTONDOWN)
          (inc! seed-num)
          (let1 pt (make-cv-point x y)
            (cv-circle markers pt 20
                       (make-cv-scalar-all seed-num)
                       -1)
            (cv-circle dsp pt 20
                       (cv-rgb 255 255 255)
                       3))
          (cv-show-image "image" dsp)))))
  (cv-wait-key 0)
  (cv-destroy-window "image")
  (cv-watershed src markers)
  (dotimes [i (ref markers 'height)]
    (dotimes [j (ref markers 'width)]
      (let1 idx (truncate->exact (ref (cv-get-2d markers i j) 'val0))
        (when (eq? idx -1)
          (cv-set-2d dst i j (cv-rgb 255 0 0))))))
  (cv-show-image "watershed transform" dst)
  (cv-wait-key 0))

