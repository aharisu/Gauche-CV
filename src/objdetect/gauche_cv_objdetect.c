/*
 * gauche_cv_objdetect.c
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


#include "gauche_cv_objdetect.h"

/*
 * Module initialization function.
 */
extern void Scm_Init_cv_objdetectlib(ScmModule *mod);
extern void Scm_Init_objdetect_type(ScmModule *mod);
void Scm_Init_gauche_cv_objdetect(void)
{
				ScmModule *mod;

				/* Register this DSO to Gauche */
				SCM_INIT_EXTENSION(gauche_cv_objdetect);

				/* Create the module if it doesn't exist yet. */
				mod = SCM_MODULE(SCM_FIND_MODULE("cv.objdetect", TRUE));
				
				/* Register stub-generated procedures */
				Scm_Init_cv_objdetectlib(mod);
				Scm_Init_objdetect_type(mod);
}
