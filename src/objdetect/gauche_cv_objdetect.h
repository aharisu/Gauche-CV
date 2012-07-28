/*
 * gauche_cv_imgproc.h
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

/* Prologue */
#ifndef GAUCHE_GAUCHE_CV_OBJDETECT_H
#define GAUCHE_GAUCHE_CV_OBJDETECT_H

#include <gauche.h>
#include <gauche/extend.h>
#include <gauche/class.h>

#include "../gauche_cv_core.h"

SCM_DECL_BEGIN

#define ENSURE_NOT_NULL(data) \
				if(!(data)) Scm_Error("already been released. object is invalied.");

/* Epilogue */
SCM_DECL_END

#endif 

