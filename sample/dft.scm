(use cv)


(define (shift-dft src dst)
  (let ([size (cv-get-size src)]
        [dst-size (cv-get-size dst)]
        [cx (quotient (ref src 'width) 2)]
        [cy (quotient (ref src 'height) 2)])
    (when (or (not (eqv? (ref size 'width) (ref dst-size 'width)))
            (not (eqv? (ref size 'height) (ref dst-size 'height))))
      (error "Source and Destination arrays must have equal sizes"))
    (let ([q1 (cv-get-sub-rect src (make-cv-rect 0 0 cx cy))]
          [q2 (cv-get-sub-rect src (make-cv-rect cx 0 cx cy))]
          [q3 (cv-get-sub-rect src (make-cv-rect cx cy cx cy))]
          [q4 (cv-get-sub-rect src (make-cv-rect 0 cy cx cy))]
          [d1 (cv-get-sub-rect dst (make-cv-rect 0 0 cx cy))]
          [d2 (cv-get-sub-rect dst (make-cv-rect cx 0 cx cy))]
          [d3 (cv-get-sub-rect dst (make-cv-rect cx cy cx cy))]
          [d4 (cv-get-sub-rect dst (make-cv-rect 0 cy cx cy))])
      (if (not (eq? src dst))
        (begin 
          (unless (cv-are-types-eq? q1 d1)
            (error "Source and Destination arrays must have the same format"))
          (cv-copy q3 d1)
          (cv-copy q4 d2)
          (cv-copy q1 d3)
          (cv-copy q2 d4))
        (let1 tmp (make-cv-mat cy cx (cv-get-elemtype src))
          (cv-copy q3 tmp)
          (cv-copy q1 q3)
          (cv-copy tmp q1)
          (cv-copy q4 tmp)
          (cv-copy q2 q4)
          (cv-copy tmp q2)
          (cv-release-mat tmp))))))

(let* ([src (cv-load-image "data/image/skytree.jpg" CV_LOAD_IMAGE_GRAYSCALE)]
       [r-input (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_64F 1)]
       [i-input (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_64F 1)]
       [complex-input (make-image (ref src 'width) (ref src 'height) IPL_DEPTH_64F 2)])
  (cv-scale src r-input 1.0 0.0)
  (cv-zero i-input)
  (cv-merge r-input i-input c:null c:null complex-input)
  (let* ([dft-m (cv-get-optimal-dft-size (- (ref src 'height) 1))]
         [dft-n (cv-get-optimal-dft-size (- (ref src 'width) 1))]
         [dft-a (make-cv-mat dft-m dft-n CV_64FC2)]
         [image-re (make-image dft-n dft-m IPL_DEPTH_64F 1)]
         [image-im (make-image dft-n dft-m IPL_DEPTH_64F 1)])
    (let1 tmp (cv-get-sub-rect dft-a (make-cv-rect 0 0 (ref src 'width) (ref src 'height)))
      (cv-copy complex-input tmp)
      (when (> (ref dft-a 'cols) (ref src 'width))
        (let1 tmp (cv-get-sub-rect dft-a (make-cv-rect (ref src 'width) 0
                                                       (- (ref dft-a 'cols) (ref src 'width))
                                                       (ref src 'height)))
          (cv-zero tmp))))
    (cv-dft dft-a dft-a CV_DXT_FORWARD (ref complex-input 'height))
    (cv-split dft-a image-re image-im c:null c:null)

    (cv-pow image-re image-re 2.0)
    (cv-pow image-im image-im 2.0)
    (cv-add image-re image-im image-re)
    (cv-pow image-re image-re 0.5)

    (cv-add-s image-re (make-cv-scalar-all 1.0) image-re)
    (cv-log image-re image-re)

    (shift-dft image-re image-re)

    (receive (min max min-loc max-loc)
      (cv-min-max-loc image-re)
      (cv-scale image-re image-re 
                (/ 1.0 (- max min))
                (/ (* 1.0 (- min))
                   (- max min))))

    (cv-named-window "Image")
    (cv-show-image "Image" src)
    (cv-named-window "Magnitude")
    (cv-show-image "Magnitude" image-re)
    (cv-wait-key 0)))

