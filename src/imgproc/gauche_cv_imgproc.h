/* Prologue */
#ifndef GAUCHE_GAUCHE_CV_IMGPROC_H
#define GAUCHE_GAUCHE_CV_IMGPROC_H

#include <gauche.h>
#include <gauche/extend.h>
#include <gauche/class.h>

SCM_DECL_BEGIN

#define ENSURE_NOT_NULL(data) \
				if(!(data)) Scm_Error("already been released. object is invalied.");

/* Epilogue */
SCM_DECL_END

#endif 

