/*
 * gauche_cv_highgui.c
 */

#include "gauche_cv_highgui.h"

/*
 * Module initialization function.
 */
extern void Scm_Init_gauche_cv_highguilib(ScmModule *mod);
void Scm_Init_gauche_cv_highgui(void)
{
				ScmModule *mod;

				/* Register this DSO to Gauche */
				SCM_INIT_EXTENSION(gauche_cv_highgui);

				/* Create the module if it doesn't exist yet. */
				mod = SCM_MODULE(SCM_FIND_MODULE("cv.highgui", TRUE));
				
				/* Register stub-generated procedures */
				Scm_Init_gauche_cv_highguilib(mod);
}
