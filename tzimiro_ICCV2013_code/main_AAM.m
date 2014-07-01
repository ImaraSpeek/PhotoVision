%% Main script for training an AAM and fitting using FAST-SIC algorithm
%% Please cite
%% [1] G. Tzimiropoulos, and M. Pantic, "Optimization problems for fast AAM
%% fitting in-the-wild," ICCV 2013
%
% Unless stated, code written by Georgios Tzimiropoulos (gtzimiropoulos@lincoln.ac.uk)
% Part of the code developed based on Octaam. Many thanks for this!
% Special thanks to Joan Alabort-i-Medina
%
% Code released as is for research purposes only
% Feel free to modify/distribute but please cite [1]

clear; clc; close all;
addpath functions

%% Train
% should you change any of the parameters below, set flag_train = 1;
flag_train = 1;
where = '.';
folder = 'trainset';
what = 'png';
AAM.num_of_points = 68;
% scales refers to the resolution that fitting is taking place.
% if scale is 1, then we fit in 1/(2^(1-1)) = 1 i.e. in the original image resolution
% if scale is 2, then we fit in 1/(2^(2-1)) = 1/2 i.e. half the original resolution
% Multi-resolution fitting is a heuristic for improving fitting.
AAM.scales = [1 2];
% max_n and max_m refers to the number of components
% that we keep after we apply PCA on the similarity-free shapes and shape-free textures
AAM.shape.max_n = 136;
num_of_scales = length(AAM.scales);
AAM.texture = cell(1, num_of_scales);
for ii = 1:num_of_scales
    AAM.texture{ii}.max_m = 550;
end

% Create the AAM
if flag_train
    AAM = train_AAM(where, folder, what, AAM);
    save([where '/' folder '/AAM.mat'], 'AAM');
end

%% Precompute
% This step precomputes all precomputable quantities required during fitting
% should you change any of the parameters below, set flag_precompute = 1;
% The code below creates a "chopped AAM" used in Fast-SIC algorithm
% n_all and m refers to the number of model parameters
% i.e. the number of components for the shape and texture model that we use for fitting
% at each scale (these are usually much smaller than AAM.shape.max_n
% and AAM.texture{ii}.max_m). So these are the total number of
% parameters that Fast-SIC algorithm is aimed to recover. In the example below we fit
% n_all = 3+4 shapes in half resolution and n_all = 10+4 shapes in the original resolution.
% 4 is the number of similarity eigenvectors and is always fixed.
% Exactly the same applies for the texture parameters.
flag_precompute = 1;
if flag_train
    flag_precompute = 1;
end
cAAM.shape{1}.n = 10;
cAAM.shape{2}.n = 3;
cAAM.shape{1}.num_of_similarity_eigs = 4;
cAAM.shape{2}.num_of_similarity_eigs = 4;
cAAM.shape{1}.n_all = cAAM.shape{1}.n + cAAM.shape{1}.num_of_similarity_eigs;
cAAM.shape{2}.n_all = cAAM.shape{2}.n + cAAM.shape{2}.num_of_similarity_eigs;
cAAM.texture{1}.m = 200;
cAAM.texture{2}.m = 50;

if flag_precompute
    if ~flag_train
        load([where '/' folder '/AAM.mat']);
    end
    
    cAAM.num_of_points = AAM.num_of_points;
    cAAM.scales = AAM.scales;
    cAAM.coord_frame = AAM.coord_frame;
    
    for ii = 1:num_of_scales
        % shape
        cAAM.shape{ii}.s0 = AAM.shape.s0;
        cAAM.shape{ii}.S = AAM.shape.S(:, 1:cAAM.shape{ii}.n);
        cAAM.shape{ii}.Q = AAM.shape.Q;
        
        % texture
        cAAM.texture{ii}.A0 = AAM.texture{ii}.A0;
        cAAM.texture{ii}.A = AAM.texture{ii}.A(:, 1:cAAM.texture{ii}.m);
        cAAM.texture{ii}.AA0 = AAM.texture{ii}.AA0;
        cAAM.texture{ii}.AA = AAM.texture{ii}.AA(:, 1:cAAM.texture{ii}.m);
        
        % warp jacobian
        [cAAM.texture{ii}.dW_dp, cAAM.coord_frame{ii}.triangles_per_point] = create_warp_jacobian(cAAM.coord_frame{ii}, cAAM.shape{ii});
    end
    save([where '/' folder '/cAAM.mat'], 'cAAM');
    
else
    load([where '/' folder '/cAAM.mat']);
end

%% fitting related parameters
num_of_scales_used = 2;
num_of_iter = [50 50];

%% landmark initializations
load initializations_LFPW

%% get images and ground truth shapes
names1 = dir('./testset/*.png');
names2 = dir('./testset/*.pts');

gg = 1; % choose image gg to fit
input_image = imread(['./testset/' names1(gg).name]);
pts = read_shape(['./testset/' names2(gg).name], cAAM.num_of_points);
if size(input_image, 3) == 3
    input_image = double(rgb2gray(input_image));
else
    input_image = double(input_image);
end

%% ground_truth
gt_s = (pts);
face_size = (max(gt_s(:,1)) - min(gt_s(:,1)) + max(gt_s(:,2)) - min(gt_s(:,2)))/2;

%% initialization
s0 = cAAM.shape{1}.s0;
current_shape = scl(gg)*reshape(s0, cAAM.num_of_points, 2) + repmat(trans(gg, :), cAAM.num_of_points, 1);
input_image = imresize(input_image, 1/scl(gg));
current_shape = (1/scl(gg))*(current_shape);
% uncomment to see initialization
% figure;imshow(input_image, []);  hold on; plot(current_shape(:,1), current_shape(:,2), '.', 'MarkerSize', 11);

%% Fitting an AAM using Fast-SIC algorithm
sc = 2.^(cAAM.scales-1);
for ii = num_of_scales_used:-1:1
    current_shape = current_shape /sc(ii);
    
    % indices for masking pixels out
    ind_in = cAAM.coord_frame{ii}.ind_in;
    ind_out = cAAM.coord_frame{ii}.ind_out;
    ind_in2 = cAAM.coord_frame{ii}.ind_in2;
    ind_out2 = cAAM.coord_frame{ii}.ind_out2;
    resolution = cAAM.coord_frame{ii}.resolution;
    
    A0 = cAAM.texture{ii}.A0;
    A = cAAM.texture{ii}.A;
    AA0 = cAAM.texture{ii}.AA0;
    AA = cAAM.texture{ii}.AA;
    
    for i = 1:num_of_iter(ii)
        
        % figure(1);clf;
        % imshow(imresize(input_image, [size(input_image, 1)/sc(ii) size(input_image, 2)/sc(ii)]), []); hold on;
        % trimesh(cAAM.coord_frame{ii}.triangles, current_shape(:,1),current_shape(:,2),'Color',(i/num_of_iter(ii)).*[0 1 1],'LineStIle','-');hold off;
        
        % Warp image
        Iw = warp_image(cAAM.coord_frame{ii}, current_shape*sc(ii), input_image);
        I = Iw(:); I(ind_out) = [];
        II = Iw(:); II(ind_out2) = [];
        
        % compute reconstruction Irec 
        if (i == 1)
            c = A'*(I - A0) ;
        else
            c = c + dc;
        end
        Irec = zeros(resolution(1), resolution(2));
        Irec(ind_in) = A0 + A*c;
        
        % compute gradients of Irec
        [Irecx Irecy] = gradient(Irec);
        Irecx(ind_out2) = 0; Irecy(ind_out2) = 0;
        Irec(ind_out2) = [];
        Irec = Irec(:);
        
        % compute J from the gradients of Irec
        J = image_jacobian(Irecx, Irecy, cAAM.texture{ii}.dW_dp, cAAM.shape{ii}.n_all);
        J(ind_out2, :) = [];
        
        % compute Jfsic and Hfsic 
        Jfsic = J - AA*(AA'*J);
        Hfsic = Jfsic' * Jfsic;
        inv_Hfsic = inv(Hfsic);
        
        % compute dp (and dq) and dc
        dqp = inv_Hfsic * Jfsic'*(II-AA0);
        dc = AA'*(II - Irec - J*dqp);
        
        % This function updates the shape in an inverse compositional fashion
        current_shape =  compute_warp_update(current_shape, dqp, cAAM.shape{ii}, cAAM.coord_frame{ii});
    end
    current_shape(:,1) = current_shape(:, 1) * sc(ii) ;
    current_shape(:,2) = current_shape(:, 2) * sc(ii) ;
end

figure;imshow(input_image, []); hold on; plot(current_shape(:,1), current_shape(:,2), '.', 'MarkerSize',11);
current_shape = current_shape*scl(gg);

%% error metric used, a value of approx 0.03 shows very good fitting
pt_pt_err1 = [];
for ii = 1:cAAM.num_of_points
    pt_pt_err1(ii) =  norm(gt_s(ii,:) - current_shape(ii,:));
end
pt_pt_err = mean(pt_pt_err1)/face_size
