
;;
;;test section for <cvarr>

(test-section "cv.core#<cvarr>")

(let ([image (make-image 36 50 IPL_DEPTH_8U 3)])

  (test* "cv-get-elemtype" CV_8UC3
    (cv-get-elemtype image))
  (test* "cv-get-dims" #s32(50 36)
    (cv-get-dims image))
  (test* "cv-get-dimsize" (values 50 36)
    (values (cv-get-dimsize image 0) (cv-get-dimsize image 1)))

  (image 0 0 (make-cv-scalar 255 128 0))
  (cv-set-zero image)
  (test* "cv-set-zero" (make-cv-scalar-all 0)
    (image 0 0))

  (image 0 0 (make-cv-scalar 255 128 0))
  (cv-zero image)
  (test* "cv-zero" (make-cv-scalar-all 0)
    (image 0 0))

  (image 0 0 (make-cv-scalar 255 128 88))
  (let ([ch1 (make-image 36 50 IPL_DEPTH_8U 1)]
        [ch2 (make-image 36 50 IPL_DEPTH_8U 1)]
        [ch3 (make-image 36 50 IPL_DEPTH_8U 1)])
    (cv-split image ch1 ch2 ch3 c:null)
    (test* "cv-split" 
      (values
        (make-cv-scalar 255 0 0)
        (make-cv-scalar 128 0 0)
        (make-cv-scalar 88 0 0))
      (values 
        (ch1 0 0)
        (ch2 0 0)
        (ch3 0 0)))
    (cv-zero image)
    (cv-merge ch1 ch2 ch3 c:null image)
    (test* "cv-merge" (image 0 0)
      (make-cv-scalar 255 128 88 0)))
  )

(let* ([rgba (make-cv-mat 100 100 CV_8UC4)]
       [bgr (make-cv-mat (ref rgba 'rows) (ref rgba 'cols) CV_8UC3)]
       [alpha (make-cv-mat (ref rgba 'rows) (ref rgba 'cols) CV_8UC1)])
  (cv-set rgba (make-cv-scalar 1 2 3 4))

  (cv-zero bgr)
  (cv-zero alpha)
  (cv-mix-channels rgba `#(,bgr ,alpha) #s32(0 2 1 1 2 0 3 3))
  (test* "mix-channels vector vector s32vector" (values (make-cv-scalar 3 2 1 0) (make-cv-scalar 4 0 0 0))
    (values (bgr 0 0) (alpha 0 0)))

  (cv-mix-channels (list rgba) (list bgr alpha) (list 0 2 1 1 2 0 3 3))
  (test* "mix-channels list list list" (values (make-cv-scalar 3 2 1 0) (make-cv-scalar 4 0 0 0))
    (values (bgr 0 0) (alpha 0 0)))

  (cv-zero bgr)
  (cv-zero alpha)
  (cv-mix-channels `#(,rgba) `#(,bgr ,alpha) #(0 2 1 1 2 0 3 3))
  (test* "mix-channels vector vector vector" (values (make-cv-scalar 3 2 1 0) (make-cv-scalar 4 0 0 0))
    (values (bgr 0 0) (alpha 0 0)))

  (cv-zero bgr)
  (cv-zero alpha)
  (cv-mix-channels `#(,rgba) `#(,bgr ,alpha) #s32(0 2 1 1 2 0 3 3))
  (test* "mix-channels vector vector s32vector" (values (make-cv-scalar 3 2 1 0) (make-cv-scalar 4 0 0 0))
    (values (bgr 0 0) (alpha 0 0)))
  )

;;no test cv-convert-scale cv-cvt-scale cv-scale cv-convert
;; cv-cvt-scale-abs
;; cv-check-term-criteria

(let ([img1 (make-image 36 50 IPL_DEPTH_8U 1)]
      [img2 (make-image 36 50 IPL_DEPTH_8U 1)]
      [dst (make-image 36 50 IPL_DEPTH_8U 1)]
      [mask (make-image 36 50 IPL_DEPTH_8U 1)])

      (cv-set img1 (make-cv-scalar 100))
      (cv-set img2 (make-cv-scalar 50))
      (cv-zero mask)
      (mask 0 (make-cv-scalar 1))

      (cv-zero dst)
      (cv-add img1 img2 dst)
      (test* "cv-add" (make-cv-scalar 150) (dst 0))

      (cv-zero dst)
      (cv-add img1 img2 dst mask)
      (test* "cv-add:masked" 
        (values 
          (make-cv-scalar 150)
          (make-cv-scalar 0))
        (values (dst 0) (dst 1)))

      (cv-zero dst)
      (cv-add-s img1 (make-cv-scalar 100) dst)
      (test* "cv-add-s" (make-cv-scalar 200) (dst 0))

      (cv-zero dst)
      (cv-add-s img1 (make-cv-scalar 100) dst mask)
      (test* "cv-add-s:masked" 
        (values 
          (make-cv-scalar 200)
          (make-cv-scalar 0))
        (values (dst 0) (dst 1)))

      ;;no test cv-sub cv-sub-s cv-sub-rs cv-mul cv-div
      ;; cv-scale-add cv-axpy cv-add-weighted cv-dot-product
      ;; cv-and cv-and-s cv-or cv-or-s cv-xor cv-xor-s cv-not
      ;; cv-in-range cv-in-range-s 

      )
(let ([img1 (make-image 36 50 IPL_DEPTH_8U 1)]
      [img2 (make-image 36 50 IPL_DEPTH_8U 1)]
      [dest (make-image 36 50 IPL_DEPTH_8U 1)])
      (cv-set-zero img1)
      (cv-set-zero img2)

      (img1 1 (make-cv-scalar 128))
      (img2 1 (make-cv-scalar 255))
      (img1 2 (make-cv-scalar 255))
      (img2 2 (make-cv-scalar 0))

      (cv-cmp img1 img2 dest CV_CMP_EQ)
      (test* "cv-cmp:CV_CMP_EQ" 
        (values
          (make-cv-scalar 255)
          (make-cv-scalar 0)
          (make-cv-scalar 0))
        (values 
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp img1 img2 dest CV_CMP_GT)
      (test* "cv-cmp:CV_CMP_GT" 
        (values
          (make-cv-scalar 0)
          (make-cv-scalar 255)
          (make-cv-scalar 0))
        (values 
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp img1 img2 dest CV_CMP_GE)
      (test* "cv-cmp:CV_CMP_GE" 
        (values
          (make-cv-scalar 255)
          (make-cv-scalar 255)
          (make-cv-scalar 0))
        (values 
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp img1 img2 dest CV_CMP_NE)
      (test* "cv-cmp:CV_CMP_NE" 
        (values
          (make-cv-scalar 0)
          (make-cv-scalar 255)
          (make-cv-scalar 255))
        (values 
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp-s img1 128 dest CV_CMP_EQ)
      (test* "cv-cmp-s:CV_CMP_GT"
        (values
          (make-cv-scalar 0)
          (make-cv-scalar 255)
          (make-cv-scalar 0))
        (values
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp-s img1 128 dest CV_CMP_GT)
      (test* "cv-cmp-s:CV_CMP_GT"
        (values
          (make-cv-scalar 0)
          (make-cv-scalar 0)
          (make-cv-scalar 255))
        (values
          (dest 0)
          (dest 1)
          dest 2))

      (cv-cmp-s img1 128 dest CV_CMP_GE)
      (test* "cv-cmp-s:CV_CMP_GT"
        (values
          (make-cv-scalar 0)
          (make-cv-scalar 255)
          (make-cv-scalar 255))
        (values
          (dest 0)
          (dest 1)
          dest 2))

      ;;no test cv-min cv-max cv-min-s cv-max-s 
      ;;cv-abs-diff cv-abs-diff-s cv-abs
  )

;; no test cv-cart-to-polar cv-polar-to-cart 
;; cv-pow cv-exp cv-log cv-fast-arctan cv-cbrt

;; no test cv-check-arr cv-check-array
;; cv-rand-arr cv-rand-shuffle

;;no test cv-sort cv-solve-cubic cv-solve-poly

;;no test cv-cross-product
;;cv-mat-mul-add-ex cv-mat-mul-add cv-mat-mul cv-mat-mul-add-s
;;cv-perspective-transform cv-mul-transposed cv-transpose
;;cv-t cv-complete-symm cv-flip cv-mirror

(let ([matrix (make-cv-mat 3 3 CV_64FC1)]
      [w (make-cv-mat 3 3 CV_64FC1)]
      [v (make-cv-mat 3 3 CV_64FC1)]
      [u (make-cv-mat 3 3 CV_64FC1)]
      [v-t (make-cv-mat 3 3 CV_64FC1)]
      [valid (make-cv-mat 3 3 CV_64FC1)])
  (cv-set-data matrix #f64(1 3 3 -3 -5 -3 3 3 1) (ref matrix 'step))
  (cv-svd matrix w u v CV_SVD_MODIFY_A)
  (cv-mat-mul u w valid)
  (cv-transpose v v-t)
  (cv-mat-mul valid v-t valid)
  (test* "cv-svd"
    (values 
      1.0 3.0 3.0
      -3.0 -5.0 -3.0
      3.0 3.0 1.0)
    (values
        (round (ref (valid 0) 'val0))
        (round (ref (valid 1) 'val0))
        (round (ref (valid 2) 'val0))
        (round (ref (valid 3) 'val0))
        (round (ref (valid 4) 'val0))
        (round (ref (valid 5) 'val0))
        (round (ref (valid 6) 'val0))
        (round (ref (valid 7) 'val0))
        (round (ref (valid 8) 'val0))))
  )

(let ([src (make-cv-mat 3 3 CV_32FC1)]
      [dst (make-cv-mat 3 3 CV_32FC1)]
      [mul (make-cv-mat 3 3 CV_32FC1)])
  (cv-set-data src #f32(1 3 3 -3 -5 -3 3 3 1) (ref src 'step))
  (cv-invert src dst CV_SVD)
  (cv-mat-mul src dst mul)
  (test* "cv-invert"
    (values
      1.0 1.0 1.0)
    (values
      (round (ref (mul 0) 'val0))
      (round (ref (mul 4) 'val0))
      (round (ref (mul 8) 'val0))))
  )

(let ([input (make-vector 10)]
      [output (make-cv-mat 2 2 CV_32FC1)]
      [meavec (make-cv-mat 1 2 CV_32FC1)]
      [exp-round (lambda (num n)
                   (receive (q r)
                     (quotient&remainder (inexact->exact (round (* num (expt 10 n))))
                                         (expt 10 n))
                     (+ q (/ r (expt 10 n)))))])
  ;;test for vector
  (for-each
    (lambda (val)
      (let1 mat (make-cv-mat 1 2 CV_32FC1)
        (cv-set-real2d mat 0 0 (cadr val))
        (cv-set-real2d mat 0 1 (caddr val))
        (vector-set! input (car val) mat)))
    '((0 2.5 2.4) (1 0.5 0.7)
      (2 2.2 2.9) (3 1.9 2.2)
      (4 3.1 3.0) (5 2.3 2.7)
      (6 2 1.6) (7 1 1.1)
      (8 1.5 1.6) (9 1.1 0.9)))
  (cv-calc-covar-matrix input output meavec
                        (logior CV_COVAR_NORMAL CV_COVAR_SCALE))
  (test* "cv-calc-covar-matrix for vector"
    (values
      (/ 5549 10000)
      (/ 5539 10000)
      (/ 5539 10000)
      (/ 6449 10000))
    (values
      (exp-round (cv-get-real2d output 0 0) 4)
      (exp-round (cv-get-real2d output 0 1) 4)
      (exp-round (cv-get-real2d output 1 0) 4)
      (exp-round (cv-get-real2d output 1 1) 4)))
  ;;test for list
  (cv-calc-covar-matrix (map
                          (lambda (val)
                            (let1 mat (make-cv-mat 1 2 CV_32FC1)
                              (cv-set-real2d mat 0 0 (car val))
                              (cv-set-real2d mat 0 1 (cadr val))
                              mat))
                          '((2.5 2.4) (0.5 0.7)
                            (2.2 2.9) (1.9 2.2)
                            (3.1 3.0) (2.3 2.7)
                            (2 1.6) (1 1.1)
                            (1.5 1.6) (1.1 0.9)))
                        output meavec
                        (logior CV_COVAR_NORMAL CV_COVAR_SCALE))
  (test* "cv-calc-covar-matrix for list"
    (values
      (/ 5549 10000)
      (/ 5539 10000)
      (/ 5539 10000)
      (/ 6449 10000))
    (values
      (exp-round (cv-get-real2d output 0 0) 4)
      (exp-round (cv-get-real2d output 0 1) 4)
      (exp-round (cv-get-real2d output 1 0) 4)
      (exp-round (cv-get-real2d output 1 1) 4)))
  )






