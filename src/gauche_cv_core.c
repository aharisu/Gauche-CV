/*
 * gauche_cv_core.c
 *
 * MIT License
 * Copyright 2011-2012 aharisu
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 *
 * aharisu
 * foo.yobina@gmail.com
 */

#include "gauche_cv_core.h"
#include "core_type.gen.h"

#include <opencv2/core/core_c.h>

//---------------
//CvObject
//---------------
ScmObj Scm_MakeCvObject(CvObject data) {
	ScmCvObject* obj = SCM_NEW(ScmCvObject);
	SCM_SET_CLASS(obj, SCM_CLASS_CVOBJECT);
	obj->data = data;
	SCM_RETURN(SCM_OBJ(obj));
}

//---------------
//CvStruct
//---------------
ScmObj Scm_MakeCvStruct(CvStruct data) {
	ScmCvStruct* obj = SCM_NEW(ScmCvStruct);
	SCM_SET_CLASS(obj, SCM_CLASS_CVSTRUCT);
	obj->data = data;
	SCM_RETURN(SCM_OBJ(obj));
}

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
extern void Scm_Init_cv_corelib(ScmModule*);
extern void Scm_Init_core_type(ScmModule*);
void Scm_Init_gauche_cv_core(void)
{
				ScmModule *mod;

				/* Register this DSO to Gauche */
				SCM_INIT_EXTENSION(gauche_cv_core);

				/* Create the module if it doesn't exist yet. */
				mod = SCM_MODULE(SCM_FIND_MODULE("cv.core", TRUE));
				
				/* Register stub-generated procedures */
				Scm_Init_cv_corelib(mod);
				Scm_Init_core_type(mod);

				//set opencv error handler
				cvRedirectError(cv_error_handler, NULL, NULL);
}
