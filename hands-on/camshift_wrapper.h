// camshift_wrapper.h - by Robin Hewitt, 2007
// http://www.cognotics.com/opencv/downloads/camshift_wrapper
// This is free software. See License.txt, in the download
// package, for details.
//
//
// Public interface for the Simple Camshift Wrapper

#ifndef __SIMPLE_CAMSHIFT_WRAPPER_H
#define __SIMPLE_CAMSHIFT_WRAPPER_H

// Main Control functions
int		testCS();
int     createTracker(const IplImage * pImg);
void    releaseTracker();
void    startTracking(IplImage * pImg, CvRect * pRect);
CvBox2D track(IplImage *);


// Parameter settings
void setVmin(int vmin);
void setSmin(int smin);

#endif
