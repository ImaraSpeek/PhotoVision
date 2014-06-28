
% Signature:
% [PredTags,PredVal] = facial_attributes(im,face_lmks,att_struct)
% Usage:
% Given a face image it predicts facial attributes: gender, ethnicity, beard, moustache and glasses.
% 
% Input:
% Im: Input image, Only RGB format is supported
% Face_lmks: Predicted landmarks (49 x 2) or [] if no face detected(or not reliable)
% att_struct: Structure that contains information about the model to detect
% facial attributes
% 
% Output:
% PredTags: Cell array containing the text string associated with the attribute values.
% PredTags(1)={Beard,No beard}, PredTags(2)={Female,Male}, PredTags(3)={Asian,White,African,Indian}, PredTags(4)={Moustache,No Moustache}, PredTags(5)={No Glasses,Eye-glasses, Sun-glasses}, 
%
% PredVal: Predicted scores from the classifier
% 1    No beard <0, Beard >0
% 2    Female <0, Male >0 
% 3    SVM confidence for Asian, White, African American, Indian
% 4    No moustache <0, Moustache >0
% 5    SVM confidence for No glasses, Eye-glasses, Sun-glasses
% 
% 
% Dependence:
% OpenCV2.4 above, mexopencv
% mexopencv can be downloaded here:
% http://www.cs.stonybrook.edu/~kyamagu/mexopencv/
% 
% You do not need to install the above packages unless you want to
% re-compile mexopencv files. All DLLs and mex functions are
% included in this folder.
% 
% Example:
% 
% % Initialize facial feature detection
% tracker_models_path='./models'; [DM, TM, option] = xx_initialize(tracker_models_path);
% 
% % Initialize facial attribute detector
% attributes_models_path='./models'; att_struct = att_initialize(attributes_models_path);
% 
% % Load test image
% image_file_path='test_im.jpg';   im=imread(image_file_path);
% 
% % Detect 49 facial landmarks
% [pred,pose] = xx_track_detect(DM,[],im,[],option);
% 
% %  Display and landmarks.
% imshow(im);   hold on;   plot(pred(:,1),pred(:,2),'r*'); hold off
% 
% % Predict facial attributes
% [PredTags,PredVal] = facial_attributes(im, pred,att_struct);
% 
% Authors:
% Francisco Vicente, fvicente.ri@gmail.com
% Fernando De la Torre, ftorre@cs.cmu.edu

