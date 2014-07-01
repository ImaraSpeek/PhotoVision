#include "mex.h"

// requires the OpenCV library to compile 

#ifndef _EiC
#include <cv.h>
#include <highgui.h>

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

void detect_and_draw( IplImage* image );

const char* cascade_name = "haarcascade_frontalface_alt.xml";

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Variable declarations
    IplImage *myImage;
    double **data2, *outArray;
    int scale = 1;
    int i, j, no_images, im_no;
    mxArray *thisfilenameData, *resultCell;
    int thisfilenameLength;
    char *thisfilename;
    
    // Check if the input is a cell array
    if(!mxIsCell(prhs[0])) {
        mexErrMsgTxt("ERROR: Input should be a cell array.\n" );
    }
   
    // Load cascade
    cascade = (CvHaarClassifierCascade*) cvLoad(cascade_name, 0, 0, 0);
    if(!cascade) {
		mexErrMsgTxt("ERROR: Could not load classifier cascade.\n");
    }
    
    // Create result cell array
    no_images = mxGetNumberOfElements(prhs[0]);
    plhs[0] = mxCreateCellMatrix(no_images, 1);
    storage = cvCreateMemStorage(0);
        
    // Loop over all images
    for(im_no = 0; im_no < no_images; im_no++) {
        
        // Print out progress
        if(i / 100 == 0) {
            mexPrintf("Running face detection for image %d of %d...\n", im_no, no_images);
        }
              
        // Retrieve image name
        thisfilenameData = (mxArray*) mxGetCell(prhs[0], im_no);
        thisfilenameLength = (int) mxGetN(thisfilenameData) + 1;
        thisfilename = (char*) mxCalloc(thisfilenameLength, sizeof(char));
        mxGetString(thisfilenameData, thisfilename, thisfilenameLength);        
        
        // Load image
        myImage = cvLoadImage(thisfilename, 1);
        if(!myImage) {
            mexErrMsgTxt("ERROR: Specified file does not exist.\n");
        }

        // Perform object detection
        CvSeq* faces = cvHaarDetectObjects(myImage, cascade, storage, 1.1, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(40, 40));
        
        // Process results of object detection, and store into data2
        data2 = (double**) malloc((faces->total) * sizeof(double));        
        for(i = 0; i < faces->total; i++)
            data2[i] = (double*) malloc(4 * sizeof(double));
        for(i = 0; i < (faces ? faces->total : 0); i++) {
            CvRect* r = (CvRect*) cvGetSeqElem(faces, i);
            data2[i][0] = r->x * scale;
            data2[i][1] = (r->x + r->width) * scale;
            data2[i][2] = r->y * scale;
            data2[i][3] = (r->y + r->height) * scale;
        }

        // Store results in cell array
        resultCell = mxCreateDoubleMatrix(4, faces->total, mxREAL);
        mxSetCell(plhs[0], im_no, resultCell);
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
    }
    
    // Clean up memory
    cvClearMemStorage(storage);
	cvReleaseHaarClassifierCascade(&cascade);
}
