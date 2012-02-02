(use cv)

(define-constant offset 30)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst-width (+ (ref src 'width) (* 2 offset))]
       [dst-height (+ (ref src 'height) (* 2 offset))]
       [dst-replicate (make-image dst-width dst-height (ref src 'depth) (ref src 'n-channels))]
       [dst-constant (make-image dst-width dst-height (ref src 'depth) (ref src 'n-channels))])
  (cv-copy-make-border src dst-replicate (make-cv-point offset offset) IPL_BORDER_REPLICATE)
  (cv-copy-make-border src dst-constant (make-cv-point offset offset) IPL_BORDER_CONSTANT (cv-rgb 255 0 0))

  (cv-named-window "Border Replicate")
  (cv-show-image "Border Replicate" dst-replicate)
  (cv-named-window "Border Constant")
  (cv-show-image "Border Constant" dst-constant)
  (cv-wait-key 0))

