#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *X, *Y, *Z, *max;
    int i, height, width;
    bool *in;
    
    /* Retrieve inputs */
    X   = mxGetPr(prhs[0]);
    Y   = mxGetPr(prhs[1]);
    in  = mxGetLogicals(prhs[2]);
    max = mxGetPr(prhs[3]);
    height = mxGetM(prhs[0]);
    width  = mxGetN(prhs[0]);
    
    /* Make output matrix */
    plhs[0] = mxCreateDoubleMatrix(height, width, mxREAL);
    Z = mxGetPr(plhs[0]);
    
    /* Subtract entries in matrix */
    for(i = 0; i < height * width; i++) {
        if(in[i]) {
            Z[i] = X[i] - Y[i];
        }
    }
    
    /* Check whether none of the assignments is out of range */
    for(i = 0; i < height * width; i++) {
        if(in[i]) {
            if(Z[i] < 1.0) {
               Z[i] = 1.0;
            }
            else if(Z[i] > max[0]) {
               Z[i] = max[0];
            }
        }
    }
}
