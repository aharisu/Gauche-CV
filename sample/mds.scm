(use cv)
(use gauche.uvector)
(use srfi-43)

(define (centering-matrix n)
  (let ([mat1 (make-cv-mat n n CV_64FC1)]
        [mat2 (make-cv-mat n n CV_64FC1)])
    (cv-set-identity mat1)
    (cv-set mat2 (make-cv-scalar (/ 1.0 n)))
    (cv-sub mat1 mat2 mat1)
    (cv-release-mat mat2)
    mat1))

(define (torgerson mat)
  (let ([n (ref mat 'rows)]
        [mat-tmp (cv-clone-mat mat)])
    (cv-add-weighted mat -1 mat 0 0 mat-tmp)
    (receive (v-min v-max)
      (cv-min-max mat-tmp)
      (let1 c1 0
        (dotimes [i n]
          (dotimes [j n]
            (dotimes [k n]
              (let1 v (- (cv-get-real2d mat i k) (cv-get-real2d mat i j) (cv-get-real2d mat j k))
                (when (> v c1)
                  (set! c1 v))))))
        (max (max c1 v-max) 0)))))

(define-constant city-distance 
  '(
    #(0 587 1212 701 1936 604 748 2139 2182 543)
    #(587 0 920 940 1745 1188 713 1858 1737 597)
    #(1212 920 0 879 831 1726 1631 949 1021 1494)
    #(701 940 879 0 1734 968 1420 1645 1891 1220)
    #(1936 1745 831 1734 0 2339 2451 247 959 2300)
    #(604 1188 1726 968 2339 0 1092 2594 2734 923)
    #(748 713 1631 1420 2451 1092 0 2571 2408 205)
    #(2139 1858 949 1645 347 2594 2571 0 678 2442)
    #(2182 1737 1021 1891 959 2734 2408 678 0 2329)
    #(543 597 1494 1220 2300 923 205 2442 2329 0)
    ))

(define-constant city-names
  #(
    "Atlanta" "Chicago" "Denver" "Houston"
    "Los Angeles" "Miami" "New York"
    "San Francisco" "Seattle" "Washington D.C."
    ))

(define (op2 op left right :optional tmp)
  (let1 tmp (if (undefined? tmp)
              (cv-clone left)
              tmp)
  (op left right tmp)
  tmp))

(define (op1 op left :optional tmp)
  (let1 tmp (if (undefined? tmp)
              (cv-clone left)
              tmp)
  (op left tmp)
  tmp))

(define (cv-mul-real arr s dst)
  (cv-add-weighted arr s arr 0 0 dst))

(let* ([size (length city-distance)]
       [t (make-cv-mat-from-uvector size size 1
                                    (vector->f64vector (vector-concatenate city-distance)))]
       [g (centering-matrix size)]
       [vectors (make-cv-mat size size CV_64FC1)]
       [values (make-cv-mat size 1 CV_64FC1)])
  (cv-add-s t (make-cv-scalar (torgerson t)) t) 
  (cv-mul t t t)
  (cv-eigen-vv
    (op2 cv-mul-real (op2 cv-mul (op2 cv-mul g t) (op1 cv-transpose g)) -0.5)
    vectors values)
  (dotimes [r (ref values 'rows)]
    (if (< (cv-get-real1d values r) 0)
      (cv-set-real1d values r 0)))
  (let1 result (cv-get-rows vectors 0 2)
    (dotimes [r (ref result 'rows)]
      (dotimes [c (ref result 'cols)]
        (cv-set-real2d result r c
                       (* (cv-get-real2d result r c)
                          (sqrt (cv-get-real1d values r))))))
    (cv-normalize result result 0 800 CV_MINMAX)
    (let* ([img (make-image 800 600 IPL_DEPTH_8U 3)]
           [font (make-cv-font CV_FONT_HERSHEY_SIMPLEX 0.5 0.5)])
      (cv-zero img)
      (dotimes [c size]
        (let ([x (truncate->exact (round (+ (* (cv-get-real2d result 0 c) 0.7)
                                            (* (ref img 'width) 0.1))))]
              [y (truncate->exact (round (+ (* (cv-get-real2d result 1 c) 0.7)
                                            (* (ref img 'height) 0.1))))])
          (cv-circle img (make-cv-point x y) 5 (cv-rgb 255 0 0) -1)
          (cv-put-text img (vector-ref city-names c)
                       (make-cv-point (+ x 5) (+ y 10))
                       font (cv-rgb 255 255 255))))
      (cv-show-image "City Location Estimation" img)
      (cv-wait-key 0))))

