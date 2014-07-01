#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *X, *Y, *Z;
    int i, height, width;
    
    /* Retrieve inputs */
    X  = mxGetPr(prhs[0]);
    Y  = mxGetPr(prhs[1]);
    height = mxGetM(prhs[0]);
    width  = mxGetN(prhs[0]);
    
    /* Make output matrix */
    plhs[0] = mxCreateDoubleMatrix(1, height * width, mxREAL);
    Z = mxGetPr(plhs[0]);
    
    /* Compute error image */
    for(i = 0; i < height * width; i++) {
        Z[i] = X[i] - Y[i];
    }
}
