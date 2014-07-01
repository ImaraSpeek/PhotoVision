#include "mex.h"

// requires the OpenCV library to compile 

#ifndef _EiC
#include <cv.h>
#include <highgui.h>

extern "C" {
	#include "camshift_wrapper.h"
}

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


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Variable declarations
    IplImage *myImage, *imageCopy;
    double **data2, *data3, *outArray;
    int scale = 1;
    int i, j, n, no_images, im_no;
    mxArray *thisfilenameData, *resultCell;
    int thisfilenameLength;
    char *thisfilename;
    char* cascade_name;
	bool bufferCreated = false;
    
    // Check if the input is a cell array
    if(!mxIsCell(prhs[0])) {
        mexErrMsgTxt("Input should be a cell array.\n" );
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
    
    // Create result cell array
    no_images = mxGetNumberOfElements(prhs[0]);
    plhs[0] = mxCreateCellMatrix(no_images, 1);
    storage = cvCreateMemStorage(0);
        
    // Loop over all images
    for(im_no = 0; im_no < no_images; im_no++) {
        
        // Print out progress
        if((im_no + 1) % 100 == 0) {
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
            mexErrMsgTxt("Specified file does not exist.\n");
        }
        
        // Create buffer for tracker
        if(!bufferCreated) {
            imageCopy = cvCreateImage(cvGetSize(myImage), IPL_DEPTH_8U, myImage->nChannels);
			bufferCreated = true;
        }
        
        // Copy frame into buffer
        cvCopy(myImage, imageCopy, 0);
        imageCopy->origin = myImage->origin;
        if(imageCopy->origin == 1) {
            cvFlip(imageCopy, 0, 0);
            imageCopy->origin = 0;
        }
        
        // Detect the objects!
        if(im_no == 0) {
            
            // Perform V&J object detection for first frame
            CvSeq* faces = cvHaarDetectObjects(imageCopy, cascade, storage, 1.1, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(40, 40));

            // Process results of object detection, and store into data2
			CvRect* r;
            data2 = (double**) malloc((faces->total) * sizeof(double));        
            for(i = 0; i < faces->total; i++)
                data2[i] = (double*) malloc(4 * sizeof(double));
            for(i = 0; i < (faces ? faces->total : 0); i++) {
                r = (CvRect*) cvGetSeqElem(faces, i);
                data2[i][0] =  r->x * scale;
                data2[i][1] = (r->x + r->width) * scale;
                data2[i][2] =  r->y * scale;
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
            
            // Clean up some memory
            for(i = 0; i < faces->total; i++)
                free(data2[i]);
			free(data2);
            
            // Create tracker
            if(!createTracker(imageCopy))
                mexErrMsgTxt("Tracker not created!");
            setVmin(60);
            setSmin(50);
            if(faces->total == 0)
                mexErrMsgTxt("No face detected in first frame!");
            startTracking(imageCopy, r);
        }
		else {
            
            // Perform tracking of the object
            CvBox2D tracked = track(imageCopy);
            CvPoint2D32f corners[4];
            cvBoxPoints(tracked, corners);
            
            // Process results of tracking
            data3 = (double*) malloc(4 * sizeof(double));
            for(i = 0; i < 4; i++) data3[i] = -1.0;
            for(i = 0; i < 4; i++) {
                if(data3[0] == -1.0 || data3[0] > corners[i].x) data3[0] = corners[i].x;
                if(data3[1] == -1.0 || data3[1] < corners[i].x) data3[1] = corners[i].x;
                if(data3[2] == -1.0 || data3[2] > corners[i].y) data3[2] = corners[i].y;
                if(data3[3] == -1.0 || data3[3] < corners[i].y) data3[3] = corners[i].y;
            }
            
            // Store results in cell array
            resultCell = mxCreateDoubleMatrix(4, 1, mxREAL);
            mxSetCell(plhs[0], im_no, resultCell);
            outArray = mxGetPr(resultCell);
            
            // Copy object detection result into result array and clean up
            for(i = 0; i < 4; i++) {
                outArray[i] = data3[i];
            }
			free(data3);
        }
        
        // Clean up memory
        cvReleaseImage(&myImage);
    }
    
    // Close down tracker
    releaseTracker();
    
    // Clean up memory
    mxFree(cascade_name);
    cvReleaseImage(&imageCopy);
    cvClearMemStorage(storage);
	cvReleaseHaarClassifierCascade(&cascade);
}
