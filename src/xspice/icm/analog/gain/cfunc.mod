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
static PyObject* set_output(PyObject* self, PyObject* args) {

    int arg1;
    float arg2;
    if (!PyArg_ParseTuple(args, "if", &arg1, &arg2)) {
        return NULL;
    }

    PyObject* value = PyObject_GetAttrString(self, "mif_private");

    if (!PyCapsule_CheckExact(value)) {
        PyErr_SetString(PyExc_TypeError, "Attribute 'mif_private' is not a capsule");
        Py_XDECREF(value);
        return NULL;
    }
    Mif_Private_t* mif_private = (Mif_Private_t*)PyCapsule_GetPointer(value, "mif_private");

    if(arg1<0)
    {
        PyErr_SetString(PyExc_TypeError, "Port number must be positive");
        Py_XDECREF(value);
        return NULL;
    }
    if(arg1>PORT_SIZE(out)-1)
    {
        PyErr_SetString(PyExc_TypeError, "Port number is out of range");
        Py_XDECREF(value);
        return NULL;
    }

    OUTPUT(out[arg1]) = arg2;

    return PyFloat_FromDouble(0);
}

static PyObject* get_input(PyObject* self, PyObject* args) {

    int arg1;
    if (!PyArg_ParseTuple(args, "i", &arg1)) {
        return NULL;
    }

    PyObject* value = PyObject_GetAttrString(self, "mif_private");

    if (!PyCapsule_CheckExact(value)) {
        PyErr_SetString(PyExc_TypeError, "Attribute 'mif_private' is not a capsule");
        Py_XDECREF(value);
        return NULL;
    }
    Mif_Private_t* mif_private = (Mif_Private_t*)PyCapsule_GetPointer(value, "mif_private");

    if(arg1<0)
    {
        PyErr_SetString(PyExc_TypeError, "Port number must be positive");
        Py_XDECREF(value);
        return NULL;
    }
    if(arg1>PORT_SIZE(in)-1)
    {
        PyErr_SetString(PyExc_TypeError, "Port number is out of range");
        Py_XDECREF(value);
        return NULL;
    }

    return PyFloat_FromDouble(INPUT(in[arg1]));
}

static PyObject* example_cpp_wrapper(PyObject* self, PyObject* args) {
    // Parse arguments
    int arg1, arg2;
    if (!PyArg_ParseTuple(args, "ii", &arg1, &arg2)) {
        return NULL;
    }

    PyObject* value = PyObject_GetAttrString(self, "mif_private");

    if (!PyCapsule_CheckExact(value)) {
        PyErr_SetString(PyExc_TypeError, "Attribute 'mif_private' is not a capsule");
        Py_XDECREF(value);
        return NULL;
    }

    Mif_Private_t* mif_private = (Mif_Private_t*)PyCapsule_GetPointer(value, "mif_private");

    return PyFloat_FromDouble(mif_private->circuit.time);
}

static PyMethodDef my_module_methods[] = {
    {"example_cpp_wrapper", example_cpp_wrapper, METH_VARARGS, "Documentation for my_function"},
    {"set_output", set_output, METH_VARARGS, "Set the output to a certain value"},
    {"get_input", get_input, METH_VARARGS, "Get the input voltage"},
    {NULL, NULL, 0, NULL}  // Sentinel
};

void call_python_eval(Mif_Private_t *mif_private, PyObject* pModule, char* python_module, char* python_function)
{

    // Execute a Python function with parameters
    PyObject* pFunc = PyObject_GetAttrString(pModule, python_function);

    if (pFunc && PyCallable_Check(pFunc)) {
        PyObject* pArgs = PyTuple_Pack(2,
            PyLong_FromLong(mif_private->circuit.anal_type), // 0 DC, 2 TRAN
            PyFloat_FromDouble(mif_private->circuit.time) // Time in s
        );
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

}

PyObject* init_pymodule(char* python_module, char* python_function)
{
    PyObject* pName = PyUnicode_DecodeFSDefault(python_module);
    PyObject* pModule = PyImport_Import(pName);
    Py_XDECREF(pName);

    PyObject* ptr = PyCFunction_New(&my_module_methods[0], pModule);
    PyModule_AddObject(pModule, "example_cpp_wrapper", ptr);
    ptr = PyCFunction_New(&my_module_methods[1], pModule);
    PyModule_AddObject(pModule, "set_output", ptr);
    ptr = PyCFunction_New(&my_module_methods[2], pModule);
    PyModule_AddObject(pModule, "get_input", ptr);


    return pModule;
}

void cm_gain(ARGS)   /* structure holding parms, inputs, outputs, etc.     */
{

    if (INIT == 1) {
        // Load python module
        STATIC_VAR(pymodule) = init_pymodule(PARAM(python_module), PARAM(python_function));
    }else{
        // Retrieve python module
        PyObject* module = STATIC_VAR(pymodule);

        PyObject* mif_private_wrapper = PyCapsule_New((void*)mif_private, "mif_private", NULL);
        PyModule_AddObject(module, "mif_private", mif_private_wrapper);


        PyModule_AddObject(module, "t", PyFloat_FromDouble(mif_private->circuit.time));

        PyModule_AddObject(module, "num_in", PyLong_FromLong(PORT_SIZE(in)));
        PyModule_AddObject(module, "num_out", PyLong_FromLong(PORT_SIZE(out)));

        call_python_eval(mif_private, module, PARAM(python_module), PARAM(python_function));
    }

}
