function warpRunner(imageName, originalPoints, desiredPoints, format)
% Usage:  this file is a simple way to run the warpImage.m file and save the results to disk
%   
% Input:  the image to warp (imageName), the points on the image to warp (originalPoints), the points where the original points should be mapped to
%  (desiredPoints), optionally the format to save the image as (i.e. jpg, bmp - etc.).
%
% Output: writes warp"fileName"."format" to disk
%
% (c) Ethan Meyers 2002  emeyers@mit.edu 



% load the image
I = imread(imageName);
I = double(I);


load(originalPoints);
originalMarks = points;

load(desiredPoints);
desiredMarks = points;


% warp the image
warpedImage = warpImage(I, originalMarks, desiredMarks);
warpedImage = uint8(warpedImage);

% output file name
fileName = ['warped_' imageName(1:end-4)];

% if file type is specified, saves to disk as that file type
if (nargin > 3)
    fileName = [fileName '.' format];  % add .jpg extension
    imwrite(warpedImage, fileName, format);
  
 % writes as a jpg by default
else     
    fileName = [fileName '.jpg'];  % add .jpg extension
    imwrite(warpedImage, fileName, 'jpg');   
end