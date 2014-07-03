#include "math.h"
#include "mex.h"

typedef unsigned char uint8;

void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    uint8 *new_im, *im;
    int i, j, height, width, dims[3];
    
    /* Retrieve inputs */
    im     = (uint8*) mxGetPr(prhs[0]);
    height = mxGetM(prhs[0]);
    width  = mxGetN(prhs[0]);
    
    /* Make output matrix */
    dims[0] = height; dims[1] = width / 3; dims[2] = 3;
    plhs[0] = mxCreateNumericArray(3, dims, mxUINT8_CLASS, mxREAL);
    new_im = (uint8*) mxGetPr(plhs[0]);
    
    /* Perform deinterlacing */
    for(j = 1; j < width; j++) {
        for(i = 0; i < height - 1; i += 2) {
            new_im[i + j * height] = im[i + j * height];
        }
        for(i = 1; i < height - 1; i += 2) {
            new_im[i + j * height] = (uint8) (((int) im[(i - 1) + j * height] + (int) im[(i + 1) + j * height]) / 2);
        }
    }
}
