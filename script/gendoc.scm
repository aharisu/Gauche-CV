(use ginfo.revert)
(use gauche.parseopt)



(define (main args)
  (let-args (cdr args)
    ((template "t|template=s")
     (srcfile "s|srcfile=s")
     (outfile "o|outfile=s")
     (else (opt . _) (print "Unkown option : " opt))
     . args)
    (if (and template srcfile)
      (let ([t-port (open-input-file template)]
            [o-port (if outfile (open-output-file outfile) (standard-output-port))])
        (with-ports t-port o-port (standard-error-port)
                    (lambda ()
                      (port-for-each print read-line)))
        (revert-doc (geninfo srcfile) o-port)
        (close-input-port t-port)
        (close-output-port o-port)
				0)
			1)))





