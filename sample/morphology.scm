(use cv)

(let* ([src (cv-load-image "data/image/lenna.png")]
       [dst-dilate (cv-clone-image src)]
       [dst-erode (cv-clone-image src)]
       [dst-openig (cv-clone-image src)]
       [dst-closing (cv-clone-image src)]
       [dst-gradient (cv-clone-image src)]
       [dst-tophat (cv-clone-image src)]
       [dst-blackhat (cv-clone-image src)]
       [tmp (cv-clone-image src)]
       [element (cv-create-structuring-element-ex 9 9 4 4 CV_SHAPE_RECT )])
  (cv-dilate src dst-dilate element 1)
  (cv-erode src dst-erode element 1)
  (cv-morphology-ex src dst-openig tmp element CV_MOP_OPEN 1)
  (cv-morphology-ex src dst-closing tmp element CV_MOP_CLOSE 1)
  (cv-morphology-ex src dst-gradient tmp element CV_MOP_GRADIENT 1)
  (cv-morphology-ex src dst-tophat tmp element CV_MOP_TOPHAT 1)
  (cv-morphology-ex src dst-blackhat tmp element CV_MOP_BLACKHAT 1)
  (cv-show-image "src" src)
  (cv-show-image "dilate" dst-dilate)
  (cv-show-image "erode" dst-erode)
  (cv-show-image "opening" dst-openig)
  (cv-show-image "closing" dst-closing)
  (cv-show-image "gradient" dst-gradient)
  (cv-show-image "tophat" dst-tophat)
  (cv-show-image "blackhat" dst-blackhat)
  (cv-wait-key 0))

