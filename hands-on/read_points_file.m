function point = read_points_file(base_folder, filename)
%READ_POINTS_FILE Read the specified points file
%
%   point = read_points_file(base_folder, filename)
%
% Read the specified points file with shape annotations.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Read the file
    point = [];
    h = fopen([base_folder '/points/' filename]);
    l = fgetl(h); 
    if strcmpi(l(1:7), 'version')               % Cootes' style point file
        l = fgetl(h); l = fgetl(h);
        while ~feof(h)
            l = fgetl(h);
            if ~strcmp(l, '}')
                [num1, l] = strtok(l);
                [num2, l] = strtok(l);
                point = [point str2double(num1) str2double(num2)];
            end
        end
        fclose(h);
    elseif strcmpi(l(1:7), '#######')           % IMM style point file
        for i=1:15
            l = fgetl(h);
        end
        point = fscanf(h, '%f');
        point = point(point > 0 & point < 1)';
        fclose(h);
    else                                        % plain text file
        fclose(h);
        point = load([base_folder '/points/' filename])';
        point = point(1:end);
    end