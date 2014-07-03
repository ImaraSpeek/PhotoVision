%MEXALL Compiles all MEX-files of the face tracker
%
% Note: you may need to edit the OpenCV path in this file!
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


disp('Compiling...');
mex -O compute_error_im.c
mex -O do_warp.c
mex -O do_warp_color.c
mex -O linear_interpol.c
mex -O linear_interpol2.c
mex -O minus_bordercheck.c
mex -O compute_shape_change.c
mex -O rgb2gray.c
% try
%     system('gcc -c camshift_wrapper.c -m32 -I/usr/local/include/opencv');
%     mex -O FaceDetect.cpp -I/usr/local/include/opencv -L/usr/local/lib -lcxcore -lcv -lcvaux
% catch
%     disp('Compilation of face detector and tracker failed. Did you install OpenCV?');
% end
% cd initialization
% mexall
% cd ..
disp('Done!')