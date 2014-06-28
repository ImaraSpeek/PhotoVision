function att_struct = att_initialize(models_path)
%  Signature: 
%     att_struct = att_initialize(models_path)
%
%   Usage:
%     This function initializes the attribute classifiers.
%
%   Params:
%     models_path - Path where the classfier models are located    
%
%   Return:
%     att_struct - Struct that contains the classifier models
% 
%   Example:    
%     %Initializing face attributes detection
%       attributes_models_path='./models';
%       att_struct = att_initialize(attributes_models_path);
%
%   Authors: 
%     Francisco Vicente, fvicente.ri@gmail.com  
%     Fernando De la Torre, ftorre@cs.cmu.edu
%


if ~exist('models_path','var')
    error('No path to the model has been introduced')
end

% loading mean face
aux_mean_face=load(fullfile(models_path,'mean_face.mat'),'mean_shape');
att_struct.mean_face=aux_mean_face.mean_shape';

% loading beard model
aux_model_beard=load(fullfile(models_path,'model_beard.mat'),'model_liblinear_beard');
att_struct.model_beard=aux_model_beard.model_liblinear_beard;

% loading females model
aux_model_ethnicity_females=load(fullfile(models_path,'model_ethnicity_females.mat'),'model_liblinear_ethnicity');
att_struct.model_ethnicity_females=aux_model_ethnicity_females.model_liblinear_ethnicity;

% loading males model
aux_model_ethnicity_males=load(fullfile(models_path,'model_ethnicity_males.mat'),'model_liblinear_ethnicity');
att_struct.model_ethnicity_males=aux_model_ethnicity_males.model_liblinear_ethnicity;

% loading gender model
aux_model_gender=load(fullfile(models_path,'model_gender.mat'),'model_liblinear_gender');
att_struct.model_gender = aux_model_gender.model_liblinear_gender;

% loading glasses model
aux_model_glasses=load(fullfile(models_path,'model_glasses.mat'),'model_liblinear_glasses');
att_struct.model_glasses = aux_model_glasses.model_liblinear_glasses;

% loading moustache model
aux_model_moustache=load(fullfile(models_path,'model_moustache.mat'),'model_liblinear_moustache');
att_struct.model_moustache = aux_model_moustache.model_liblinear_moustache;

end