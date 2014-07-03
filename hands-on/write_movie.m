function write_movie(filename, base_folder, images, p, shape_model, lambda, appear_model)
%WRITE_MOVIE Writes a movie of the specified images
%
%   write_movie(filename, base_folder, images)
%   write_movie(filename, base_folder, images, p, shape_model, lambda, appear_model)
%   write_movie(filename, movie, [], p, shape_model, lambda, appear_model)
%
% Writes a movie of the specified images into the file filename. The 
% function requires a working installation of ffmpeg or DirectShow, and of 
% videoIO. The user may need to specify the library path to ffmpeg.
% The functions writes movie frames that have the fitted appearance model
% overlaid (if fits are specified).
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Initialize the frame reader
    if isempty(images)
        addpath('videoIO');
        setenv('LD_LIBRARY_PATH', '/usr/local/lib');
        vr = videoReader(base_folder, 'ffmpegDirect');
        info = get(vr);
        no_frames = info.numFrames;
        fps = info.fps;
    else
        no_frames = length(images);
        fps = 25;
    end
    
    % Initialize the frame writer
    vw = videoWriter(filename, 'ffmpegDirect', 'fps', fps);
    
    % Write the frames
    for i=1:no_frames
        
        % Progress bar
        if ~rem(i, 100)
            disp(['Writing frame ' num2str(i) ' of ' num2str(no_frames) '...']);
        end
        
        % Get next frame
        if isempty(images)
            next(vr); 
            im = deinterlace(getframe(vr));
        else
            im = imread([base_folder '/images/' images(i).name]);
        end 
        
        % Overlay appearance fit
        if exist('p', 'var') && exist('lambda', 'var') && ~isempty(p{i}) && ~isempty(lambda{i})
            
            % Compute current shape and appearance
            cur_shape = shape_model.shape_mu + sum(bsxfun(@times, p{i}, shape_model.shape_pcs), 2)';
            appearance = reshape(appear_model.appearance_mu(:) + sum(bsxfun(@times, lambda{i}, appear_model.appearance_pcs), 2), appear_model.size_aam);
            offset = [min(cur_shape(1:2:end)) min(cur_shape(2:2:end))];
            cur_shape(1:2:end) = 1 + cur_shape(1:2:end) - offset(1);
            cur_shape(2:2:end) = 1 + cur_shape(2:2:end) - offset(2);
            appearance = pw_linear_warp(appearance, cur_shape, shape_model.shape_mu, [ceil(max(cur_shape(2:2:end))) ceil(max(cur_shape(1:2:end))) 3]);
            appearance = uint8(round(appearance * 255));
            
            % Overlay appearance fit over original frame
            if all(offset > 1) && offset(2) + size(appearance, 1) - 1 < size(im, 1) && offset(1) + size(appearance, 2) - 1 < size(im, 2)
                offset = round(offset);
                cur_content = im(offset(2):offset(2) + size(appearance, 1) - 1, offset(1):offset(1) + size(appearance, 2) - 1,:);
                ind = (appearance == 0);
                appearance(ind) = cur_content(ind);
                im(offset(2):offset(2) + size(appearance, 1) - 1, offset(1):offset(1) + size(appearance, 2) - 1,:) = appearance;
            end
        end
        
        % Write frame
        addframe(vw, im);
    end
  
    % Close video writer
    close(vw);
    