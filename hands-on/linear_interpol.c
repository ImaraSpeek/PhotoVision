#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *z, *tri, *w, *zi;
    int i, j, no_pixels, no_tri;
    bool *in;
    
    /* Get inputs */
    no_pixels = mxGetM(prhs[1]);
    no_tri = mxGetN(prhs[1]);
    z   = mxGetPr(prhs[0]);
    tri = mxGetPr(prhs[1]);
    w   = mxGetPr(prhs[2]);
    in  = mxGetLogicals(prhs[3]);
    
    /* Allocate memory for the output matrix */
    plhs[0] = mxCreateDoubleMatrix(no_pixels, 1, mxREAL);
    zi = mxGetPr(plhs[0]);
    
    /* Start filling matrix */
    for(j = 0; j < no_tri; j++) {
        for(i = 0; i < no_pixels; i++) {
            if(in[i]) {
                zi[i] += (z[(int) tri[i + j * no_pixels] - 1] * w[i + j * no_pixels]);
            }
        }
    }
    
    /* Round results */
    for(i = 0; i < no_pixels; i++) {
        if(in[i]) {
            zi[i] = floor(zi[i]+0.5);
        }
    }
}
