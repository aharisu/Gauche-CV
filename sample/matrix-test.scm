(use cv)

(let* ([a (make-cv-mat-from-uvector 3 3 1 #f64(1 2 3 4 5 6 7 8 9))]
       [b (make-cv-mat-from-uvector 3 3 1 #f64(1 4 7 2 5 8 3 6 9))]
       [result (cv-clone-mat a)])
  (cv-add a b result)
  (print result)
  (cv-sub a b result)
  (print result)
  (cv-mul a b result)
  (print result)
  (cv-div a b result)
  (print result)
  (cv-and a b result)
  (print result))


