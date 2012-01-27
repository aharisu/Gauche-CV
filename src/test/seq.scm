
;;
;;test section for <cv-seq>

(test-section "cv.core#<cv-seq>")

(define storage (make-cv-mem-storage))
(define seq (make-cv-seq storage))
(cv-seq-push seq 1)
(cv-seq-push seq 2)
(cv-seq-push seq 3)
(test* "(cv-seq-pop seq)" 3
  (cv-seq-pop seq))
(test* "(cv-seq-pop seq)" 2
  (cv-seq-pop seq))
(test* "(cv-seq-pop seq)" 1
  (cv-seq-pop seq))
(cv-seq-push-front seq 1)
(cv-seq-push-front seq 2)
(cv-seq-push-front seq 3)
(test* "(cv-seq-pop-front seq)" 3
  (cv-seq-pop-front seq))
(test* "(cv-seq-pop seq)" 1
  (cv-seq-pop seq))
(cv-seq-push-multi seq #(1 2 3 4 5))
(test* "cv-seq-push-multi cv-seq-pop-multi (small size) (vector)" #(1 2 3 4 5)
  (cv-seq-pop-multi seq 5))
(cv-seq-push-multi seq #(1 2 3 4 5 6 7 8 9 10 11 12 13 14))
(test* "cv-seq-push-multi cv-seq-pop-multi (large size) (vector)" #(1 2 3 4 5 6 7 8 9 10 11 12 13 14)
  (cv-seq-pop-multi seq 14))
(cv-seq-push-multi seq '(1 2 3 4 5))
(test* "cv-seq-push-multi cv-seq-pop-multi (small size) (list)" #(1 2 3 4 5)
  (cv-seq-pop-multi seq 5))
(cv-seq-push-multi seq '(1 2 3 4 5 6 7 8 9 10 11 12 13 14))
(test* "cv-seq-push-multi cv-seq-pop-multi (large size) (list)" #(1 2 3 4 5 6 7 8 9 10 11 12 13 14)
  (cv-seq-pop-multi seq 14))

(cv-seq-push-multi seq #(1 2 3))
(cv-clear-seq seq)
(test* "(cv-seq-clear seq)" 0
  (ref seq 'total))

(define writer (cv-start-append-to-seq seq))
(cv-write-seq-elem 1 writer)
(cv-write-seq-elem 2 writer)
(cv-write-seq-elem 3 writer)
(cv-end-write-seq writer)
(test* "<cv-seq-writer>" #(1 2 3)
  (cv-seq-pop-multi seq 3))

(cv-seq-push-multi seq #(1 2 3 4 5 6 7 8 9 10 11 12 13 14))
(define reader (cv-start-read-seq seq))
(test* "cv-read-seq-elem" 1
  (cv-read-seq-elem reader))
(cv-next-seq-elem reader)
(test* "cv-next-seq-elem cv-ref-req-elem" 3
  (cv-ref-seq-elem reader))
(cv-prev-seq-elem reader)
(test* "cv-prev-seq-elem cv-ref-req-elem" 2
  (cv-ref-seq-elem reader))
(cv-set-seq-reader-pos reader 4)
(test* "cv-set-seq-reader-pos cv-get-seq-reader-pos" 4
  (cv-get-seq-reader-pos reader))


