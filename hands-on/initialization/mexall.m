%MEXALL Compiles all MEX-files of the AAM initializer
%
% Note: you may need to edit the OpenCV path in this file!
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


mex -O mre_disttransform.cxx
mex -O mre_haarcascade_masked.cxx
mex -O mre_intimg_cols.cxx
mex -O vgg_interp2.cxx
try
    mex -O MatlabFaceDetect.cpp -I/usr/local/include/opencv -L/usr/local/lib -lcxcore -lcv -lcvaux -lhighgui
    mex -O FastFaceDetect.cpp -I/usr/local/include/opencv -L/usr/local/lib -lcxcore -lcv -lcvaux
catch
    disp('Compilation of face detector and tracker failed. Did you install OpenCV?');
end
