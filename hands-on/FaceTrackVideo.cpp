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
    int i, j, n, no_frames, frame_no;
    mxArray *thisfilenameData, *resultCell;
    int thisfilenameLength;
    char *thisfilename;
    char *movie_name, *cascade_name;
	bool bufferCreated = false;
    
    // Check if the input is a cell array
    if(mxIsChar(prhs[0])) {
        n = mxGetN(prhs[0]) + 1;
        movie_name = (char*) mxCalloc(n, sizeof(char));
        mxGetString(prhs[0], movie_name, n);
    }
    else {
        mexErrMsgTxt("Input should be a movie name.\n" );
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
		mexErrMsgTxt("Could not load classifier cascade.\n");
    }
    
    // Open the specified movie
	mexPrintf("Running face detection on movie: %s\n", movie_name);
    CvCapture* pCapture = cvCaptureFromAVI(movie_name);
	if(!pCapture)
		mexErrMsgTxt("Movie file does not exist or format is not supported.\n");
    myImage = cvQueryFrame(pCapture);
    no_frames = (int) cvGetCaptureProperty(pCapture, CV_CAP_PROP_FRAME_COUNT);
	mexPrintf("Movie contains %d frames.\n", no_frames);
    
    // Create result cell array
    plhs[0] = mxCreateCellMatrix(no_frames, 1);
    storage = cvCreateMemStorage(0);
        
    // Loop over all frames in the movie
    for(frame_no = 0; frame_no < no_frames; frame_no++) {
        
        // Print out progress
        if((frame_no + 1) % 100 == 0) {
            mexPrintf("Running face detection for image %d of %d...\n", frame_no + 1, no_frames);
        }
              
        // Retrieve image name
        myImage = cvQueryFrame(pCapture);
		if(!myImage)
			mexErrMsgTxt("Could not read frame from movie.\n");
        
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
        if(frame_no == 0) {
            
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
            mxSetCell(plhs[0], frame_no, resultCell);
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
            mxSetCell(plhs[0], frame_no, resultCell);
            outArray = mxGetPr(resultCell);
            
            // Copy object detection result into result array and clean up
            for(i = 0; i < 4; i++) {
                outArray[i] = data3[i];
            }
			free(data3);
        }
    }
    
    // Close down tracker
	releaseTracker();
    
    // Clean up memory
	mxFree(movie_name);
    mxFree(cascade_name);
	cvReleaseImage(&imageCopy);
	cvReleaseCapture(&pCapture);
	cvClearMemStorage(storage);
	cvReleaseHaarClassifierCascade(&cascade);
}
