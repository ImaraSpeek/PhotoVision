clear;
close all;
clc;
dbstop if error

globals;
name = 'multipie';

% record a log 
file = [cachedir name, '.log'];
diary(file);

try
    load([cachedir name '_data.mat']);
catch
    [pos, neg test] = multipie_data();
    pos = point2box(pos);
    save([cachedir name '_data.mat'],'pos','neg','test');
end

% train face model
model = model_train(name,pos,neg);

% test face model
% lower the threshod for higher recall
model.thresh = min(-0.1,model.thresh);
try
    load([cachedir name '_boxes']);
catch
    boxes = model_test(name, model, test);
    save([cachedir name '_boxes'], 'boxes');
end

% evaluate face model on MultiPIE
[ap prec rec] = multipie_eval_detection(boxes,test);
[accu_pose errtol_pose] = multipie_eval_pose(boxes,test);
[accu_lm errtol_lm] = multipie_eval_landmark(boxes,test);

fprintf('AP of detection: %f\n',ap);
fprintf('%.2f%% of the faces have pose estimation error below %d degrees\n',100*accu_pose(2),errtol_pose(2));
id = find(errtol_lm>=0.05,1,'first');
fprintf('%.2f%% of the faces have landmark localization error below 5%% of the face size\n',100*accu_lm(id));
diary off;

% visualize model
visualizemodel(model);