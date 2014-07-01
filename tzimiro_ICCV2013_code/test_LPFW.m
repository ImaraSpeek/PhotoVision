%% Main script for testing on LFPW using FAST-SIC algorithm

clear; clc; close all;
addpath functions

%% load model
where = '.';
what = 'png';
folder = 'trainset';
load([where '/' folder '/cAAM.mat']);

%% fitting related parameters
num_of_scales_used = 2;
num_of_iter = [50 50];

%% landmark initializations
load initializations_LFPW

%% get images and ground truth shapes
names1 = dir('./testset/*.png');
names2 = dir('./testset/*.pts');

for gg = 1:length(names1);
    gg
    input_image = imread(['./testset/' names1(gg).name]);
    pts = read_shape(['./testset/' names2(gg).name], cAAM.num_of_points);
    
    if size(input_image, 3) == 3
        input_image = double(rgb2gray(input_image));
    else
        input_image = double(input_image);
    end
    
    try
        %% ground_truth
        gt_s = (pts);
        face_size = (max(gt_s(:,1)) - min(gt_s(:,1)) + max(gt_s(:,2)) - min(gt_s(:,2)))/2;
        
        %% initialization
        s0 = cAAM.shape{1}.s0;
        current_shape = scl(gg)*reshape(s0, cAAM.num_of_points, 2) + repmat(trans(gg, :), cAAM.num_of_points, 1);
        input_image = imresize(input_image, 1/scl(gg));
        current_shape = (1/scl(gg))*(current_shape);
        % uncomment to see the initialization of the algorithm for each image
        % figure;imshow(input_image, []); colormap(gray); hold on; plot(current_shape(:,1), current_shape(:,2), 'o');
        
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
                % trimesh(cAAM.coord_frame{ii}.triangles, current_shape(:,1),current_shape(:,2),'Color',(i/num_of_iter(ii)).*[0 1 1],'LineStyle','-');hold off;
                
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
                
                % update
                dqp = inv_Hfsic * Jfsic'*(II-AA0);
                dc = AA'*(II - Irec - J*dqp);
                
                % This function updates the shape in an inverse compositional fashion
                current_shape =  compute_warp_update(current_shape, dqp, cAAM.shape{ii}, cAAM.coord_frame{ii});
            end
            current_shape(:,1) = current_shape(:, 1) * sc(ii) ;
            current_shape(:,2) = current_shape(:, 2) * sc(ii) ;
        end
        current_shape = current_shape*scl(gg);
        
        %% compute pt-pt error
        pt_pt_err1 = [];
        for ii = 1:cAAM.num_of_points
            pt_pt_err1(ii) =  norm(gt_s(ii,:) - current_shape(ii,:));
        end
        pt_pt_err(gg) = mean(pt_pt_err1)/face_size;
        
    catch me3
        pt_pt_err(gg) = 1000;
    end
    
end

%% plot cumulative curve
var = 0:0.002:0.1;
cum_err = zeros(size(var));
for ii = 1:length(cum_err)
    cum_err(ii) = length(find(pt_pt_err<var(ii)))/length(pt_pt_err);
end

figure; plot(var, cum_err, 'blue-s', 'MarkerSize', 11, 'linewidth', 2); grid on
set(gca, 'FontSize', 0.1)
set(gca, 'FontWeight', 'bold')
xtick = 5*var; 
ytick = 0:0.1:1;
set(gca, 'xtick', xtick);
set(gca,'ytick', ytick);
ylabel('Percentage of Images', 'Interpreter','tex', 'fontsize', 15)
xlabel('Pt-Pt error normalized by face size', 'Interpreter','tex', 'fontsize', 13)
legend('FAST-SIC')
title('LFPW', 'Interpreter','tex', 'fontsize', 15)
