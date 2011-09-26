/*
 * gauche_cv_core.c
 */

#include "gauche_cv_core.h"
#include "core_type.gen.h"

#include <opencv2/core/core_c.h>

static int CV_CDECL cv_error_handler(int status, const char* func_name,
								const char* err_msg, const char* file_name, int line, void* userdata)
{
				Scm_RaiseCondition(
						SCM_OBJ(SCM_CLASS_OPENCV_ERROR),
						SCM_RAISE_CONDITION_MESSAGE,
						"%s\nin function %s\nin file %s(%d)\n",
						err_msg, func_name, file_name, line);


				cvSetErrStatus(CV_StsOk);
				return 0;
}

/*
 * Module initialization function.
 */
extern void Scm_Init_gauche_cv_corelib(ScmModule*);
extern void Scm_Init_core_type(ScmModule*);
void Scm_Init_gauche_cv_core(void)
{
				ScmModule *mod;

				/* Register this DSO to Gauche */
				SCM_INIT_EXTENSION(gauche_cv_core);

				/* Create the module if it doesn't exist yet. */
				mod = SCM_MODULE(SCM_FIND_MODULE("cv.core", TRUE));
				
				/* Register stub-generated procedures */
				Scm_Init_gauche_cv_corelib(mod);
				Scm_Init_core_type(mod);

				//set opencv error handler
				cvRedirectError(cv_error_handler, NULL, NULL);
}
