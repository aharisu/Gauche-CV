(use cv)

(define (sum-line-pixels image pt1 pt2)
  (receive (count iterator)
    (cv-init-line-iterator image pt1 pt2 8)
    (let loop ([i 0]
               [blue-sum 0]
               [green-sum 0]
               [red-sum 0])
      (let ([b (cv-get-byte-line-iterator iterator 0)]
            [g (cv-get-byte-line-iterator iterator 1)]
            [r (cv-get-byte-line-iterator iterator 2)])
        (cv-next-line-point iterator)
        (if (< (+ i 1) count)
          (loop (+ i 1)
                (+ blue-sum b)
                (+ green-sum g)
                (+ red-sum r))
          (make-cv-scalar blue-sum green-sum red-sum))))))

(let ([image (cv-load-image "data/image/lenna.png")]
      [pt1 (make-cv-point 30 100)]
      [pt2 (make-cv-point 500 400)])
  (print (sum-line-pixels image pt1 pt2))
  (cv-line image pt1 pt2 (cv-rgb 255 0 0) 3 8)
  (cv-show-image "line" image)
  (cv-wait-key 0))



