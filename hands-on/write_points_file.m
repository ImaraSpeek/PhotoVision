function write_points_file(filename, points)
%WRITE_POINTS_FILE Writes the specified points to a file
%
%   write_points_file(filename, points)
%
% Writes the specified points to a file file with shape annotations.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Write the points to the file
    h = fopen(filename, 'w');
    fprintf(h, 'version: 1\n');
    fprintf(h, 'n_points: %d\n', numel(points) / 2);
    fprintf(h, '{\n');
    for i=1:2:length(points)
        fprintf(h, '%f %f\n', points(i), points(i + 1));
    end
    fprintf(h, '}\n');
    fclose(h);