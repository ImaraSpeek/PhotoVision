#include "math.h"
#include "mex.h"


void mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs) {

    /* Initialize some variables */
    double *appearance, *newCoordsX, *newCoordsY, *size_aam, *warped_appear;
    int i, appear_height, appear_width, appear_no_pixels, height, width, no_pixels;
    bool *in;
    
    /* Retrieve inputs */
    appearance = mxGetPr(prhs[0]);
    newCoordsX = mxGetPr(prhs[1]);
    newCoordsY = mxGetPr(prhs[2]);
    in = mxGetLogicals(prhs[3]);
    size_aam = mxGetPr(prhs[4]);
    appear_height = mxGetM(prhs[0]);
    appear_width  = mxGetN(prhs[0]) / 3;
    appear_no_pixels = appear_height * appear_width;
    height = (int) size_aam[0];
    width  = (int) size_aam[1];
    no_pixels = height * width;
    
    /* Construct output matrix */
    plhs[0] = mxCreateDoubleMatrix(height, width * 3, mxREAL);
    warped_appear = mxGetPr(plhs[0]);
    
    /* Fill result image */
    for(i = 0; i < no_pixels; i++) {
        if(in[i]) {
            warped_appear[i + 0 * no_pixels] = appearance[(int) newCoordsY[i] - 1 + 
                                                         ((int) newCoordsX[i] - 1) * appear_height + 0 * appear_no_pixels];
            warped_appear[i + 1 * no_pixels] = appearance[(int) newCoordsY[i] - 1 + 
                                                         ((int) newCoordsX[i] - 1) * appear_height + 1 * appear_no_pixels];
            warped_appear[i + 2 * no_pixels] = appearance[(int) newCoordsY[i] - 1 + 
                                                         ((int) newCoordsX[i] - 1) * appear_height + 2 * appear_no_pixels];
        }
    }
}
