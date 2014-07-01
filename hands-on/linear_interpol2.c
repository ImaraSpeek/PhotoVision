#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *z, *tri, *w, *zi, *xi, *max;
    int i, j, no_pixels, no_tri;
    bool *in;
    
    /* Get inputs */
    no_pixels = mxGetM(prhs[1]);
    no_tri = mxGetN(prhs[1]);
    z   = mxGetPr(prhs[0]);
    tri = mxGetPr(prhs[1]);
    w   = mxGetPr(prhs[2]);
    in  = mxGetLogicals(prhs[3]);
    xi  = mxGetPr(prhs[4]);
    max = mxGetPr(prhs[5]);
    
    /* Allocate memory for the output matrix */
    plhs[0] = mxCreateDoubleMatrix(no_pixels, 1, mxREAL);
    zi = mxGetPr(plhs[0]);
    
    /* Compute pixel displacements */
    for(j = 0; j < no_tri; j++) {
        for(i = 0; i < no_pixels; i++) {
            if(in[i]) {
                zi[i] += (z[(int) tri[i + j * no_pixels] - 1] * w[i + j * no_pixels]);
            }
        }
    }
    
    /* Compute where to take pixels from */
    for(i = 0; i < no_pixels; i++) {
        if(in[i]) {
            
            /* Subtract displacements from original coordinates */
            zi[i] = xi[i] - zi[i];
    
            /* Check whether none of the assignments is out of range, and round */
            if(zi[i] < 1.0) {
               zi[i] = 1.0;
            }
            else if(zi[i] > max[0]) {
               zi[i] = max[0];
            }
            else {
                zi[i] = floor(zi[i]+0.5);
            }
            
            /* Excluding the round makes thing a lot faster, but a bit inaccurate */
        }
    }
}
