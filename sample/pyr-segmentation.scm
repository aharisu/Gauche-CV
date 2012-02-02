(use cv)

(define-constant threshold1 255)
(define-constant threshold2 50)

(let ([src (cv-load-image "data/image/items.jpg")]
      [storage (make-cv-mem-storage)])
  (dotimes [i 4]
    (slot-set! src 'roi (make-cv-rect 0 0
                                      (logand (ref src 'width)
                                              (- (ash 1 (+ i 1))))
                                      (logand (ref src 'height)
                                              (- (ash 1 (+ i 1))))))
    (let1 dst (cv-clone-image src)
      (cv-pyr-segmentation src dst storage (+ i 1) threshold1 threshold2)
      (cv-show-image (format #f "Segmentation Level=~a" (+ i 1)) dst)))
  (cv-show-image "src" src)
  (cv-wait-key 0))
