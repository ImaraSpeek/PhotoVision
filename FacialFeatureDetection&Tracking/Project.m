% Set the correct folder
% cd D:/School/Computer_Vision/PhotoVision/FacialFeatureDetection&Tracking/

% Initialize the model and read in the images
%[Models, option] = xx_initialize;
%im = imread('./data/subtiel.jpg');

im = imread('./data/subtiel2.jpg');
%im = imrotate(im, 45);

  % check whether the image is too big
  if size(im, 1) > 600
      im = cv.resize(im, (600 / size(im, 1)));
  end
  
% Train a Viola & jones object detector configured by default to detect
% faces (DEFAULT = FrontalFaceCART), or FrontalFaceLBP
faceDetector = vision.CascadeObjectDetector('FrontalFaceLBP');
% Steps through multiscale detecting all images, 
% input image can be gray or RGB
% returns a bounding box for every face
bbox = step(faceDetector, im);

% display all the found images
imdetect = insertObjectAnnotation(im,'rectangle',bbox,'Face');
figure, imshow(imdetect), title('Detected Face');