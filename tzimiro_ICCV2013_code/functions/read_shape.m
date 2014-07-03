function [shape] = read_shape(shape_path, n_vertices)

% read_shape pts
fid = fopen(shape_path);
tline = fgetl(fid);
start = 1;
while ~strcmp(tline, '{')
    start = start + 1;
    tline = fgetl(fid);
end
fclose(fid);

% read shape
shape =  dlmread(shape_path, ' ', [start 0 start+n_vertices-1 1]);

