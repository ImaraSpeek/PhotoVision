#include "math.h"
#include "mex.h"

typedef unsigned char uint8;

void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    uint8 *c_im, *im;
    int i, height, width, no_pixels, dims[2];
    
    /* Retrieve inputs */
    c_im   = (uint8*) mxGetPr(prhs[0]);
    height = mxGetM(prhs[0]);
    width  = mxGetN(prhs[0]) / 3;
    no_pixels = height * width;
    
    /* Make output matrix */
    dims[0] = height; dims[1] = width;
    plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    im = (uint8*) mxGetPr(plhs[0]);
    
    /* Compute grayscale image */
    for(i = 0; i < no_pixels; i++) {
        im[i] = (uint8) (((int) c_im[i] + (int) c_im[i + no_pixels] + (int) c_im[i + 2 * no_pixels]) / 3);
    }
}
