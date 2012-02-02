(use cv)

(define-constant level 2)

(print "processing ...")

(let1 src (cv-load-image "data/image/items.jpg")
  (slot-set! src 'roi (make-cv-rect 0 0 (logand (ref src 'width) 
                                                (- (ash 1 level)))
                                    (logand (ref src 'height)
                                            (- (ash 1 level)))))
  (let1 dst (cv-clone-image src)
    (cv-pyr-mean-shift-filtering src dst 30 30 level 
                                 (make-cv-term-criteria (logior CV_TERMCRIT_ITER CV_TERMCRIT_EPS)
                                                        5 1))
    (cv-show-image "Source" src)
    (cv-show-image "MeanShift" dst)
    (cv-wait-key 0)))

