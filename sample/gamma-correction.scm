(use cv)
(use gauche.uvector)

(define (correct-gamma src dst gamma)
  (let1 lut (make-u8vector 256)
    (dotimes [i 256]
      (u8vector-set! lut i (truncate->exact
                             (* (expt (/ i 255) (/ 1 gamma)) 255))))
    (cv-lut src dst lut)))

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst-0.25 (cv-clone-image src)]
       [dst-0.5 (cv-clone-image src)]
       [dst-2 (cv-clone-image src)])
  (correct-gamma src dst-0.25 0.25)
  (correct-gamma src dst-0.5 0.5)
  (correct-gamma src dst-2 2)
  (cv-show-image "src" src)
  (cv-show-image "gamma = 0.25" dst-0.25)
  (cv-show-image "gamma = 0.5" dst-0.5)
  (cv-show-image "gamma = 2.0" dst-2)
  (cv-wait-key 0))

