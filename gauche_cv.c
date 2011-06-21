/*
 * gauche_cv.c
 */

#include "gauche_cv.h"

/*
 * The following function is a dummy one; replace it for
 * your C function definitions.
 */

ScmObj test_gauche_cv(void)
{
    return SCM_MAKE_STR("gauche_cv is working");
}

/*
 * Module initialization function.
 */
extern void Scm_Init_gauche_cvlib(ScmModule*);

void Scm_Init_gauche_cv(void)
{
    ScmModule *mod;

    /* Register this DSO to Gauche */
    SCM_INIT_EXTENSION(gauche_cv);

    /* Create the module if it doesn't exist yet. */
    mod = SCM_MODULE(SCM_FIND_MODULE("gauche-cv", TRUE));

    /* Register stub-generated procedures */
    Scm_Init_gauche_cvlib(mod);
}
