function p = initialize_aam(im, shape_mu, shape_pcs, data_name)
%INITIALIZE_AAM Tries to initialize an AAM using V&J and skin detection
%
%   p = initialize_aam(im, shape_mu, shape_pcs, data_name)
%   p = initialize_aam(im, shape_mu, shape_pcs, transf_mult)
%
% Tries to initialize an AAM using V&J and skin detection. The
% initialization is returned in p. The function returns an empty matrix p
% if the initialization has failed.
% The best initialization performance can be obtained if data_name is
% specified (currently only 'ARF' is supported). Otherwise transf_mult HAS
% to be specified.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    if ~ischar(data_name)
        transf_mult = data_name;
        data_name = 'None';
    end
    if ndims(im) == 2
        im = repmat(im, [1 1 3]);
    end
    p = [];

    % If dataset unknown, initialize using V&J detection
    if strcmpi(data_name, 'None')
        warning('You have not specified the dataset name, as a result of which a weaker initialization method has to be used. This may lead to inferior results.');
        face = face_detection(im);
        if ~isempty(face)
            face = face{1};
            if numel(face) > 0

                % Initialize shape parameters
                rx = (face(2) - face(1)) / (max(shape_mu(1:2:end)) - 1);
                ry = (face(4) - face(3)) / (max(shape_mu(2:2:end)) - 1);
                scale = (rx + ry) / 2;
                trans_x = face(1) + .09 * scale * (face(2) - face(1));
                trans_y = face(3) + .24 * scale * (face(4) - face(3));
                p = [(scale - 1) * transf_mult(1) 0 trans_x * transf_mult(3) trans_y * transf_mult(4) zeros(1, size(shape_pcs, 2) - 4)];
            else
                p = [];
            end
        else
            p = [];
        end
    else
        
%         warning('This AAM initialization implementation appears to have a memory leak!');
        
        % Set control point indices for various datasets
        if strcmpi(data_name, 'ARF')
            ind = [10 11 12 13 16 15 17 3 4];
        elseif any(strcmpi(data_name, {'Debat', 'Josh'}))
            ind = [1 2 4 5 7 8 9 10 11];
        elseif strcmpi(data_name, 'CohnKanade')
            ind = [20 22 27 25 39 59 40 41 47];
        elseif strcmpi(data_name, 'IMM')
            ind = [22 26 18 14 51 53 55 40 44];
        else
            error('Unknown dataset specified.');
        end
        
        % Construct model with affine transformations and nine feature points
        ind = [ind * 2 - 1; ind * 2];
        small_shape_mu  = shape_mu (ind(:));
        small_shape_pcs = shape_pcs(ind(:), 1:5);
        
        % Perform facial feature point detection
        addpath('initialization');
        init;
        [detections, points, descs, confs] = extfacedescs(opts, im, false);      % set to true to see detected facial feature points
        if ~isempty(points)

            % Select match with highest confidence
            [m, ii] = max(confs);
            
            % Compute optimal shape parameter initialization
            points = points(:,:,ii); points = points(:)';
            p = (small_shape_pcs \ (points - small_shape_mu)')';
            p = [p zeros(1, size(shape_pcs, 2) - 5)];
        end
    end
        
    