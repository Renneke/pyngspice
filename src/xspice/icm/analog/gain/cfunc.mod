/*.......1.........2.........3.........4.........5.........6.........7.........8
================================================================================

FILE gain/cfunc.mod

Copyright 1991
Georgia Tech Research Corporation, Atlanta, Ga. 30332
All Rights Reserved

PROJECT A-8503-405


AUTHORS

    6 Jun 1991     Jeffrey P. Murray


MODIFICATIONS

     2 Oct 1991    Jeffrey P. Murray


SUMMARY

    This file contains the model-specific routines used to
    functionally describe the gain code model.


INTERFACES

    FILE                 ROUTINE CALLED

    N/A                  N/A


REFERENCED FILES

    Inputs from and outputs to ARGS structure.


NON-STANDARD FEATURES

    NONE

===============================================================================*/

/*=== INCLUDE FILES ====================*/

#include <Python.h>


/*=== CONSTANTS ========================*/




/*=== MACROS ===========================*/




/*=== LOCAL VARIABLES & TYPEDEFS =======*/




/*=== FUNCTION PROTOTYPE DEFINITIONS ===*/





/*==============================================================================

FUNCTION void cm_gain()

AUTHORS

     2 Oct 1991     Jeffrey P. Murray

MODIFICATIONS

    NONE

SUMMARY

    This function implements the gain code model.

INTERFACES

    FILE                 ROUTINE CALLED

    N/A                  N/A


RETURNED VALUE

    Returns inputs and outputs via ARGS structure.

GLOBAL VARIABLES

    NONE

NON-STANDARD FEATURES

    NONE

==============================================================================*/


/*=== CM_GAIN ROUTINE ===*/

void call_python_eval(Mif_Private_t *mif_private)
{
    // Execute a Python function with parameters
    PyObject* pName = PyUnicode_DecodeFSDefault("example_module");
    PyObject* pModule = PyImport_Import(pName);
    Py_XDECREF(pName);

    if (pModule != NULL) {
        PyObject* pFunc = PyObject_GetAttrString(pModule, "example_function");
        if (pFunc && PyCallable_Check(pFunc)) {
            PyObject* pArgs = PyTuple_Pack(2,
            PyLong_FromLong(mif_private->circuit.anal_type), // 0 DC, 2 TRAN
            PyLong_FromLong(2));
            PyObject* pValue = PyObject_CallObject(pFunc, pArgs);
            Py_XDECREF(pArgs);

            if (pValue != NULL) {
                printf("Result of call: %ld\n", PyLong_AsLong(pValue));
                Py_XDECREF(pValue);
            } else {
                PyErr_Print();
            }
            Py_XDECREF(pFunc);
        } else {
            PyErr_Print();
        }
        Py_XDECREF(pModule);
    } else {
        PyErr_Print();
    }
}

void cm_gain(ARGS)   /* structure holding parms, inputs, outputs, etc.     */
{

    call_python_eval(mif_private);


    Mif_Complex_t ac_gain;

    if (ANALYSIS == MIF_DC) {

        OUTPUT(out) = PARAM(out_offset) + PARAM(gain) *
                         ( INPUT(in) + PARAM(in_offset));
        PARTIAL(out,in) = PARAM(gain);

    } else if (ANALYSIS == MIF_TRAN) {

        OUTPUT(out) = PARAM(out_offset) + PARAM(gain) *
                         ( INPUT(in) + PARAM(in_offset));
        PARTIAL(out,in) = PARAM(gain);

    } else if (ANALYSIS == MIF_AC){
        /*ac_gain.real = PARAM(gain);
        ac_gain.imag= 0.0;
        AC_GAIN(out,in) = ac_gain;*/
    }

}
