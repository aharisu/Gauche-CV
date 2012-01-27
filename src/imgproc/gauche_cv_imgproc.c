
#include "gauche_cv_imgproc.h"

/*
 * Module initialization function.
 */
extern void Scm_Init_cv_imgproclib(ScmModule *mod);
extern void Scm_Init_imgproc_type(ScmModule *mod);
void Scm_Init_gauche_cv_imgproc(void)
{
				ScmModule *mod;

				/* Register this DSO to Gauche */
				SCM_INIT_EXTENSION(gauche_cv_imgproc);

				/* Create the module if it doesn't exist yet. */
				mod = SCM_MODULE(SCM_FIND_MODULE("cv.imgproc", TRUE));
				
				/* Register stub-generated procedures */
				Scm_Init_cv_imgproclib(mod);
				Scm_Init_imgproc_type(mod);
}
