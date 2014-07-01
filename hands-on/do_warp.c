#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *appearance, *newCoordsX, *newCoordsY, *size_aam, *warped_appear;
    int i, appear_height, height, width;
    bool *in;
    
    /* Retrieve inputs */
    appearance = mxGetPr(prhs[0]);
    newCoordsX = mxGetPr(prhs[1]);
    newCoordsY = mxGetPr(prhs[2]);
    in = mxGetLogicals(prhs[3]);
    size_aam = mxGetPr(prhs[4]);
    appear_height = mxGetM(prhs[0]);
    height = (int) size_aam[0];
    width  = (int) size_aam[1];
    
    /* Construct output matrix */
    plhs[0] = mxCreateDoubleMatrix(height, width, mxREAL);
    warped_appear = mxGetPr(plhs[0]);
    
    /* Fill result image */
    for(i = 0; i < height * width; i++) {
        if(in[i]) {
            warped_appear[i] = appearance[(int) newCoordsY[i] - 1 + 
                                         ((int) newCoordsX[i] - 1) * appear_height];
        }
    }
}
