(load "gauche/cgen/cise.scm")
(select-module gauche.cgen.cise)


(define-cise-expr result
  [(_ e) `(set! SCM_RESULT ,e)]
  [(_ e0 e1) `(set! SCM_RESULT0 ,e0 SCM_RESULT1 ,e1)]
  [(_ e0 e1 e2) `(set! SCM_RESULT0 ,e0 SCM_RESULT1 ,e1 SCM_RESULT2 ,e2)]
  [(_ e0 e1 e2 e3) `(set! SCM_RESULT0 ,e0 SCM_RESULT1 ,e1 SCM_RESULT2 ,e2 SCM_RESULT3 ,e3)]
  [(_ e0 e1 e2 e3 e4) `(set! SCM_RESULT0 ,e0 SCM_RESULT1 ,e1 SCM_RESULT2 ,e2 SCM_RESULT3 ,e3 SCM_RESULT4 ,e4)]
  )

