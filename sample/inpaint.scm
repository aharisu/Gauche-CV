(use cv)

(print
  "Hot keys:\n"
  "\tESC - quit the program\n"
  "\tr - restore the original image\n"
  "\ti or ENTER - run inpainting algorithm\n"
  "\t\t(before running it, paint something on the image)\n"
  "\ts - save the original image, mask image, original+mask image and inpainted image.")

(let* ([img0 (cv-load-image "data/image/fruits.jpg")]
       [img (cv-clone-image img0)]
       [inpaint-mask (make-image (ref img 'width) (ref img 'height) IPL_DEPTH_8U 1)]
       [inpainted (cv-clone-image img0)])
  (cv-zero inpainted)
  (cv-zero inpaint-mask)
  (cv-show-image "image" img)
  (cv-set-mouse-callback 
    "image" 
    (let1 prev-pt (make-cv-point -1 -1)
      (lambda (ev x y flags)
        (cond
          [(or (eq? ev CV_EVENT_LBUTTONUP) (zero? (logand flags CV_EVENT_FLAG_LBUTTON)))
           (set! prev-pt (make-cv-point -1 -1))]
          [(eq? ev CV_EVENT_LBUTTONDOWN)
           (set! prev-pt (make-cv-point x y))]
          [(and (eq? ev CV_EVENT_MOUSEMOVE) (not (zero? (logand flags CV_EVENT_FLAG_LBUTTON))))
           (let1 pt (make-cv-point x y)
             (let1 prev-pt (if (< (ref prev-pt 'x) 0) pt prev-pt)
               (cv-line inpaint-mask prev-pt pt (cv-rgb 255 255 255) 5 16)
               (cv-line img prev-pt pt (cv-rgb 255 255 255) 5 16))
             (set! prev-pt pt)
             (cv-show-image "image" img))]))))
  (let loop ()
    (case (cv-wait-key 0)
      [(27) ;ESC
       (cv-destroy-all-windows)]
      [(114) ;r
       (cv-zero inpaint-mask)
       (cv-copy img0 img)
       (cv-show-image "image" img)
       (loop)]
      [(105 10 13) ;i ENTER
       (cv-inpaint img inpaint-mask inpainted 3 CV_INPAINT_TELEA)
       (cv-show-image "inpainted image" inpainted)
       (loop)]
      [(115) ;s
       (cv-save-image "original.png" img0)
       (cv-save-image "mask.png" inpaint-mask)
       (cv-save-image "original+mask.png" img)
       (cv-save-image "inpainted.png" inpainted)
       (loop)]
      [else (loop)]))
  )




