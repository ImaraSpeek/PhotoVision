%% Function to test facial_attributes
clear all,close all

%Donwload from www.humansensing.cs.cmu.edu/intraface the Matlab function
%for facial feature detection

tracker_models_path='./models';
[DM, TM, option] = xx_initialize(tracker_models_path);

%Initialize facial attribute function
attributes_models_path='./models';
att_struct = att_initialize(attributes_models_path);

%Reading test image
image_file_path='test_im.jpg'; im=imread(image_file_path);

%Detect facial feature points
[pred,pose] = xx_track_detect(DM,[],im,[],option);

%Display image and landmarks
imshow(im); hold on; plot(pred(:,1),pred(:,2),'r*'); hold off;

%Predicting facial attributes
[PredTags,PredVal] = facial_attributes(im, pred,att_struct);
attributes_string=[PredTags{1}  PredTags{2}  PredTags{3}  PredTags{4}  PredTags{5}];
y_location=floor(size(im,1)*.1);
x_location=floor(size(im,2)*.1);
text(x_location,y_location,attributes_string,'Color','b');




