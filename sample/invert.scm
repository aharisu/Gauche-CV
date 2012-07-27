(use cv)
(use math.mt-random)

(define rand (make-cv-rng))

(define-constant nrow 3)
(define-constant ncol 3)

(let ([src (make-cv-mat nrow ncol CV_32FC1)]
      [dst (make-cv-mat nrow ncol CV_32FC1)]
      [mul (make-cv-mat nrow ncol CV_32FC1)])
  (print "src")
  (cv-m-set src 0 0 1)
  (dotimes [i (slot-ref src 'rows)]
    (dotimes [j (slot-ref src 'cols)]
      (cv-m-set src i j (cv-rand-real rand))
      (display #`",(cv-m-get src i j) "))
    (print ""))

  (let1 det (cv-invert src dst CV_SVD)
    (print #`"det(src)=,det"))

  (print "dst")
  (dotimes [i (slot-ref dst 'rows)]
    (dotimes [j (slot-ref dst 'cols)]
      (display #`",(cv-m-get dst i j) "))
    (print ""))

  (cv-mat-mul src dst mul)
  (print "mul")
  (dotimes [i (slot-ref mul 'rows)]
    (dotimes [j (slot-ref mul 'cols)]
      (display #`",(cv-m-get mul i j) "))
    (print ""))
  )



