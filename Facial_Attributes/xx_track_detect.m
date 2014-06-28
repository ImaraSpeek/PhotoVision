% Signature: 
%   [pred,pose] = xx_track_detect(DM,TM,im,prev,option)
%
% Dependence:
%   OpenCV2.4 above, mexopencv
%   mexopencv can be downloaded here:
%   http://www.cs.stonybrook.edu/~kyamagu/mexopencv/
%   
%   You do not need the above two packages unless you want to build OpenCV
%   on yourself or re-compile mexopencv. All DLLs and mex functions are
%   included in this package.
%
% Usage:
%   This function detects or tracks one face in a given image. The function
%   performs detection when input prev=[], and tracking when prev is given.
%   The function also optionally returns the head pose estimated from those 
%   tracked points.
%
% Params:
%   DM - detection model, 
%   TM - tracking model,
%   im - image
%   prev - landmarks in previous frame
%   option - tracker parameters
%     .face_score - threshold (<=0) determining whether the tracked face is
%     lost. The lower the value the more tolerated it becomes.
%
%     .min_neighbors - OpenCV face detector parameter (>0). The lower the more 
%     likely to find a face as well as false positives.
%
%     .min_face_size - minimum face size for OpenCV face detector.
%
%     .compute_pose - flag indicating whether to compute head pose.
%
% Return:
%   pred - predicted landmarks (49 x 2) or [] if no face detected(or not reliable) 
%   pose - head pose struct
%     .angle  1x3 - rotation angle
%     .rot    3x3 - rotation matrix
%
% Authors: 
%   Xuehan Xiong, xiong828@gmail.com
%   Zehua Huang, huazehuang@gmail.com
%   Fernando De la Torre, ftorre@cs.cmu.edu
%
% Citation: 
%   Xuehan Xiong, Fernando de la Torre, Supervised Descent Method and Its
%   Application to Face Alignment. CVPR, 2013
%
% Creation Date: 3/25/2013
%