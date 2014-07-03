#include "mex.h"

// requires the OpenCV library to compile 

#ifndef _EiC
#include <cv.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <time.h>
#include <ctype.h>
#endif

#ifdef _EiC
#define WIN32
#endif

static CvMemStorage* storage = 0;
static CvHaarClassifierCascade* cascade = 0;

typedef unsigned char uint8;


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Variable declarations
    IplImage *myImage;
    double **data2, *outArray;
    int scale = 1;
    int i, j, n, height, width, no_channels;
    mxArray *resultCell;
    uint8 *image;
    char* cascade_name;
    
    // Check if the input is a cell array
    if(!mxIsNumeric(prhs[0])) {
        mexErrMsgTxt("ERROR: Input should be an image.\n" );
    }
    
    // Check if we were given a cascade name
    if(nrhs > 1) {
        n = mxGetN(prhs[1]) + 1;
        cascade_name = (char*) mxCalloc(n, sizeof(char));
        mxGetString(prhs[1], cascade_name, n);
    }
    else {
        cascade_name = (char*) mxCalloc(sizeof("haarcascade_frontalface_alt.xml") + 1, sizeof(char));
        strcpy(cascade_name, "haarcascade_frontalface_alt.xml");
    }
   
    // Load cascade
    cascade = (CvHaarClassifierCascade*) cvLoad(cascade_name, 0, 0, 0);
    if(!cascade) {
		mexErrMsgTxt("ERROR: Could not load classifier cascade.\n");
    }
    
    // Get input image
    no_channels = 3;                            // should be done smarter!
    height = mxGetM(prhs[0]);
    width  = mxGetN(prhs[0]) / no_channels;
    image  = (uint8*) mxGetPr(prhs[0]);
    
    // Create result cell array
    plhs[0] = mxCreateCellMatrix(1, 1);
    storage = cvCreateMemStorage(0);
        
    // Convert Matlab image to OpenCV image
    myImage = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, no_channels);
    for(i = 0; i < height; i++) {
        for(j = 0; j < width; j++) {
            myImage->imageData[3 * (i * width + j) + 0] = image[j * height + i + 2 * (width * height)];     // R -> B
            myImage->imageData[3 * (i * width + j) + 1] = image[j * height + i + 1 * (width * height)];     // G -> G
            myImage->imageData[3 * (i * width + j) + 2] = image[j * height + i + 0 * (width * height)];     // B -> R
        }
    }   
    
    // Perform object detection
    CvSeq* faces = cvHaarDetectObjects(myImage, cascade, storage, 1.1, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(40, 40));

    // Process results of object detection, and store into data2
    data2 = (double**) malloc((faces->total) * sizeof(double));        
    for(i = 0; i < faces->total; i++)
        data2[i] = (double*) malloc(4 * sizeof(double));
    for(i = 0; i < (faces ? faces->total : 0); i++) {
        CvRect* r = (CvRect*) cvGetSeqElem(faces, i);
        data2[i][0] =  r->x * scale;
        data2[i][1] = (r->x + r->width) * scale;
        data2[i][2] =  r->y * scale;
        data2[i][3] = (r->y + r->height) * scale;
    }

    // Store results in cell array
    resultCell = mxCreateDoubleMatrix(4, faces->total, mxREAL);
    mxSetCell(plhs[0], 0, resultCell);
    outArray = mxGetPr(resultCell);

    // Copy object detection result into result array
    for(i = 0; i < faces->total; i++) {
        for(j = 0; j < 4; j++) {
            outArray[(i * 4) + j] = data2[i][j];
        }
    }

    // Clean up memory
    cvReleaseImage(&myImage);
    for(i = 0; i < faces->total; i++)
        free(data2[i]);
    free(data2);
    mxFree(cascade_name);
    cvClearMemStorage(storage);
	cvReleaseHaarClassifierCascade(&cascade);
}
