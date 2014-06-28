%
% Signature: 
%   xx_initialize
%
% Dependence:
%   OpenCV2.4 above, mexopencv
%   mexopencv can be downloaded here:
%   http://www.cs.stonybrook.edu/~kyamagu/mexopencv/
%   
%   After installing mexopencv, remember to add it to the path.
%   
%   The program assumes that detection and tracking models are in the
%   current working directory.
%
% Usage:
%   This function initializes the tracker.
%
% Params:
%   None
%
% Return:
%   DM - detection model
%   TM - tracking model
%   option - tracker parameters
%
% Author: 
%   Xuehan Xiong, xiong828@gmail.com
% 
% Date:
%   5/30/2013
%

function [DM, TM, option] = xx_initialize(xxPath)
  if ~exist('xxPath','var')
    xxPath = '';
  end

  % re-initialization parameter
  option.face_score = -1.5;
  % face detector threshold, positive integers
  option.min_neighbors = 1;
  % minimum face size to detect
  option.min_face_size = [50 50];
  % flag to compute head pose
  option.compute_pose = true;
  % flag to return HOG features
  option.return_feature = true;
  % flag to return HOG feature types
  option.return_feature_type = {'appearance','shape','norm_image','norm_pred'}; 
  
  % OpenCV face detector model file
  xml_file = fullfile(xxPath,'haarcascade_frontalface_alt2.xml');
  
  % load tracking model
  load(fullfile(xxPath,'TrackingModel-xxsift-v1.8.mat'));
  
  % load detection model
  load(fullfile(xxPath,'DetectionModel-xxsift-v1.4.mat'));
  
  % create face detector handle
  fd_h = cv.CascadeClassifier(xml_file);
  
  % pass it to detection and tracking model
  DM{1}.fd_h = fd_h;
 
end

