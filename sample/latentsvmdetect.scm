(use cv)
(use cv.objdetect)

;;tbb not support

(let* ([image (cv-load-image "data/image/cat.jpg")]
       [detector (cv-load-latent-svm-detector "data/data/cat.xml")]
       [storage (make-cv-mem-storage)]
       [detections (cv-latent-svm-detect-objects image detector storage)])
  (dotimes [i (slot-ref detections 'total)]
    (let1 r (slot-ref (cv-get-seq-elem-cast <cv-object-detection> detections i)
                      'rect)
      (cv-rectangle image 
                    (make-cv-point (slot-ref r 'x)
                                   (slot-ref r 'y))
                    (make-cv-point (+ (slot-ref r 'x) (slot-ref r 'width))
                                   (+ (slot-ref r 'y) (slot-ref r 'height)))
                    (cv-rgb 255 0 0) 3)))
  (cv-show-image "LatentSvmDetect" image)
  (cv-wait-key 0))





