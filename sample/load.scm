(use cv)

(let* ([img (cv-cast <iplimage> (cv-load "image.xml"))])
  (cv-show-image "src" img)
  (cv-wait-key 0))

