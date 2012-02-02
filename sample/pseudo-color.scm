(use cv)
(use gauche.uvector)
(use gauche.collection)

(define (fill-gray-scale-values img)
  (dotimes [y (ref img 'height)]
    (dotimes [x (ref img 'width)]
        (cv-set-2d img y x (make-cv-scalar
                             (* (/. 255 (ref img 'width)) x))))))

(define (create-lut-data)
  (with-builder (<u8vector> add! get :size (* 256 3))
    (dotimes [i 256]
      (cond
        [(and (>= i 0) (<= i 63))
         (add! 0);red
         (add! (truncate->exact (* (/. 255 63) i))) ;green
         (add! 255) ;blue
         ]
        [(and (> i 63) (<= i 127))
         (add! 0);red
         (add! 255) ;green
         (add! (truncate->exact (- 255 (* (/. 255 (- 127 63)) (- i 63))))) ;blue
         ]
        [(and (> i 127) (<= i 191))
         (add! (truncate->exact (* (/. 255 (- 191 127)) (- i 127)))) ;red
         (add! 255) ;green
         (add! 0) ;blue
         ]
        [else
          (add! 255) ;red
          (add! (truncate->exact (- 255 (* (/. 255 (- 255 191)) (- i 191)))))
          (add! 0) ;blue
          ]))
    (get)))

(define (convert-to-pseudo-color src dst)
  (let* ([src3ch (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_8U 3)]
         [lut (make-cv-mat-from-uvector 256 1 3 (create-lut-data))])
    (cv-merge src src src '() src3ch)
    (cv-lut src3ch dst lut)
    ))


(let* ([img-gray (make-image 500 100 IPL_DEPTH_8U 1)]
       [img-pseudo (make-image (ref img-gray 'width) (ref img-gray 'height) IPL_DEPTH_8U 3)])
  (fill-gray-scale-values img-gray)
  (convert-to-pseudo-color img-gray img-pseudo)

  (cv-show-image "gray" img-gray)
  (cv-show-image "pseudo" img-pseudo)
  (cv-wait-key 0))
