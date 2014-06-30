%clear all, clc;

% Set the correct folder
cd D:/School/Computer_Vision/PhotoVision/FacialFeatureDetection&Tracking/

% Initialize the model and read in the images
%[Models, option] = xx_initialize;
%im = imread('./data/subtiel.jpg');

im = imread('./data/context.jpg');
%im = imrotate(im, 45);

  % check whether the image is too big
  if size(im, 1) > 600
      im = cv.resize(im, (600 / size(im, 1)));
  end
  
% Train a Viola & jones object detector configured by default to detect
% faces (DEFAULT = FrontalFaceCART), or FrontalFaceLBP
LBPDetector = vision.CascadeObjectDetector('FrontalFaceLBP', 'MergeThreshold', 5);
faceDetector = vision.CascadeObjectDetector('FrontalFaceCART', 'MergeThreshold', 4);
profileDetector = vision.CascadeObjectDetector('ProfileFace', 'MergeThreshold', 4);
% Steps through multiscale detecting all images, 
% input image can be gray or RGB
% returns a bounding box for every face
bboxlbp = step(LBPDetector, im);
bboxface = step(faceDetector, im);
bboxprofile = step(profileDetector, im);

bbox = zeros((length(bboxlbp) + length(bboxface) + length(bboxprofile)), 4);
% check for similarities and remove redundant faces
for i=1:size(bboxlbp, 1)
   for j=1:size(bboxprofile,1)
      if ((bboxprofile(j,1) < bboxlbp(i,1) + (bboxlbp(i,3) / 2)) && (bboxprofile(j,1) > bboxlbp(i,1) - (bboxlbp(i,3) / 2)) ...
              && (bboxprofile(j,2) < bboxlbp(i,2) + (bboxlbp(i,4)/ 2)) && (bboxprofile(j,2) > bboxlbp(i,2) - (bboxlbp(i,4) / 2)))
          % set to zeroes if the array is already added
          bboxprofile(j,:) = [0 0 0 0];
      end
   end
end

for k=1:size(bboxface,1)
   for h=1:size(bboxlbp,1)
      if ((bboxlbp(h,1) < bboxface(k,1) + (bboxface(k,3) / 2)) && (bboxlbp(h,1) > bboxface(k,1) - (bboxface(k,3) / 2)) ...
              && (bboxlbp(h,2) < bboxface(k,2) + (bboxface(k,4)/ 2)) && (bboxlbp(h,2) > bboxface(k,2) - (bboxface(k,4) / 2)))
          % set to zeroes if the array is already added
          bboxlbp(h,:) = [0 0 0 0];
      end
   end
end

bbox = [bbox; bboxlbp];
bbox = [bbox; bboxprofile];
bbox = [bbox; bboxface];

% remove the zero rows
bbox( all(~bbox,2), : ) = [];

% put all the faces into different cells so it can be handled in the rest
A = mat2cell(bbox, ones(size(bbox, 1), 1), [4]);
faces = A';

%bbox(bbox == 0) = [];
%bbox = sparse(bbox);


% display all the found images
% imdetect = insertObjectAnnotation(im, 'rectangle', bboxlbp(5,:), 'Face');
% figure, imshow(imdetect);

imdetect = insertObjectAnnotation(im, 'rectangle', bbox, 'Face');
figure, imshow(imdetect), title('Detected Face');

