(use cv)
(use gauche.sequence)

(define (wid num width)
  (let1 w (expt 10 width)
    (+ (truncate->exact num)
       (/. (abs (- (truncate->exact (* w num))
                   (* (truncate->exact num) w)))
           w))))

(let1 src (cv-load-image "data/image/lenna.png")
  (when (and (eq? (ref src 'n-channels) 3) (zero? (ref src 'coi)))
    (slot-set! src 'coi 1))
  (let1 moments (cv-moments src)
    (slot-set! src 'coi 0)
    (let ([spatial (cv-get-spatial-moment moments 0 0)]
          [central (cv-get-central-moment moments 0 0)]
          [norm (cv-get-normalized-central-moment moments 0 0)]
          [hu (cv-get-hu-moments moments)]
          [font (make-cv-font CV_FONT_HERSHEY_SIMPLEX 1 1 0 2 8)])
      (receive (size baseline)
        (cv-get-text-size "Aa1=" font)
        (for-each-with-index
          (lambda (i text)
            (cv-put-text src text (make-cv-point 10 (* (+ 3 (ref size 'height)) (+ i 1)))
                         font (cv-rgb 0 0 0)))
          (list
            (format #f "spatial=~D" spatial)
            (format #f "central=~D" central)
            (format #f "norm=~D" norm)
            (format #f "hu1=~D" (wid (ref hu 'hu1) 10))
            (format #f "hu2=~D" (wid (ref hu 'hu2) 10))
            (format #f "hu3=~D" (wid (ref hu 'hu3) 10))
            (format #f "hu4=~D" (wid (ref hu 'hu4) 10))
            (format #f "hu5=~D" (wid (ref hu 'hu5) 10))
            (format #f "hu6=~D" (wid (ref hu 'hu6) 10))
            (format #f "hu7=~D" (wid (ref hu 'hu7) 10)))))))
  (cv-show-image "image" src)
  (cv-wait-key 0))


