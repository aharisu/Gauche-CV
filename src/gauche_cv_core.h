/*
 * gauche_cv_core.h
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
#ifndef GAUCHE_GAUCHE_CV_CORE_H
#define GAUCHE_GAUCHE_CV_CORE_H

#include <gauche.h>
#include <gauche/extend.h>
#include <gauche/class.h>

SCM_DECL_BEGIN

typedef void* CvObject;
typedef void* CvStruct;

//---------------
//CvObject
//---------------
typedef struct ScmCvObjectRec {
	SCM_HEADER;
	CvObject data;
}ScmCvObject;
SCM_CLASS_DECL(Scm_CvObjectClass);
#define SCM_CLASS_CVOBJECT (&Scm_CvObjectClass)
#define SCM_CVOBJECT(obj) ((ScmCvObject*)(obj))
#define SCM_CVOBJECT_P(obj) SCM_ISA(obj, SCM_CLASS_CVOBJECT)
#define SCM_CVOBJECT_DATA(obj) (SCM_CVOBJECT(obj)->data)
#define SCM_MAKE_CVOBJECT(data) (Scm_MakeCvObject(data))
extern ScmObj Scm_MakeCvObject(CvObject data);

//---------------
//CvStruct
//---------------
typedef struct ScmCvStructRec {
	SCM_HEADER;
	CvStruct data;
}ScmCvStruct;
SCM_CLASS_DECL(Scm_CvStructClass);
#define SCM_CLASS_CVSTRUCT (&Scm_CvStructClass)
#define SCM_CVSTRUCT(obj) ((ScmCvStruct*)(obj))
#define SCM_CVSTRUCT_P(obj) SCM_ISA(obj, SCM_CLASS_CVSTRUCT)
#define SCM_CVSTRUCT_DATA(obj) (SCM_CVSTRUCT(obj)->data)
#define SCM_MAKE_CVSTRUCT(data) (Scm_MakeCvStruct(data))
extern ScmObj Scm_MakeCvStruct(CvStruct data);


#define ENSURE_NOT_NULL(data) \
				if(!(data)) Scm_Error("already been released. object is invalied.");

typedef ScmObj (*t_cast_proc)(ScmClass* to_class, ScmObj object);
void register_cast_proc(t_cast_proc proc);

/* Epilogue */
SCM_DECL_END

#endif  /* GAUCHE_GAUCHE_CV_H */

