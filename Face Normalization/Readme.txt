'faceNormalization.m' function gets a scanned image (such as "input.jpg")
and returns an extracted canonical image, according to ISO standard for 
E-passport applications.
This function has 2 built-in functions:

    - croppedImage: Gets initial scanned image and extracts the approximate facial region.

    - canonicalImage.m: Gets the output of croppedImage.m and returns a standard canonical image. 

To produce the canonical image, 'eyefinder' function of Machine Perception Toolbox is adopted. 
This toolbox is downloadable at:
   
    http://sourceforge.net/projects/mptbox/

Note that you have to run a VC++6 program, included in MPT to obtain necessary MATLAB components for eye finding.
So follow instructions bellow, if you want my functions work correctly!

    1. Firstly, run  Microsoft Visual C++ 6.

    2. go to "Tools->Options->Directories".
       Under Show directories for select Include files select new entry and add 
       "C:\Program Files\MATLAB7\extern\include" (note path may be different).

    3. Under Show directories for select Library files add 
       "C:\Program Files\MATLAB7\extern\lib\win32\microsoft\msvc60".

    4. Open "<MPT path>\Libraries\eyefinder\matlab\windows\mp_eyefinderMex.dsw" in VC++6.

    5. Build either mp_eyefinderMex - release or debug.
       Make sure that mp_eyefinderMex is the active project. To confirm it, go to
       "Build->Set active configuration" and set mp_eyefindermex as active project.

    6. Finally, copy mp_eyefindermex.lib, which must be produced by VC++6 into
       "<MATLAB root>\extern\lib\win32\microsoft". 

After building and copying mp_eyefinderMex.lib, you don't need VC++6 to use 'eyefinder' function in MATLAB.
I encourage you to take a look at 'example.m' and run it with "input.jpg" as its input image.

Have fun!
Amir Hossein Omidvarnia
aomidvar@ece.ut.ac.ir