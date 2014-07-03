% Define model structures. 

opts.viewpoint = 90:-15:-90;
opts.partpoolsize = 39+68+39;

% Spatial resolution for HoG cells
opts.sbin = 4;

% define the structures for each global mixture
% global mixture 1 to 3, left face
opts.mixture(1).poolid = 1:39;
I = 1:39;
J = [6 5 4 3 2 1 ... % nose
    14 15 11 12 13 ... % left eye
    10 9 8 7 ... % eyebrow
    16 17 18 19 20 21 22 ... % outer lip
    25 24 23 26 27 ... % inner lip
    28:39]; % jaw
S = ones(1,39);
opts.mixture(1).anno2treeorder = full(sparse(I,J,S,39,39)); % label transformation
opts.mixture(1).pa = [0:5 ... % nose
    1 7:10 ... % left eye
    11:14 ... % eyebrow
    1 16:21 ... % outer lip
    19 23 24 23 26 ... % inner lip
    22 28:38]; % jaw

opts.mixture(2) = opts.mixture(1);
opts.mixture(3) = opts.mixture(1);


% global mixture 4 to 10, frontal face
opts.mixture(4).poolid = 40:107;
I = 1:68;
J = [34 33 32 35 36 ... % nose
    31 30 29 28 ... % nose
    40 41 42 39 38 37 ... % left eye
    18:22 ... % left eyebrow
    43 48 47 44 45 46 ... % right eye
    27:-1:23 ... % right eyebrow
    52 51 50 49 61 62 63 53 54 55 65 64 ... % upper lip
    56 66 57 67 59 68 60 58 ... % lower lip
    9:-1:1 10:17]; % jaw
S = ones(1,68);
opts.mixture(4).anno2treeorder = full(sparse(I,J,S,68,68)); % label transformation
opts.mixture(4).pa = [0 1 2 1 4 ... % nose
    1 6 7 8 ... % nose
    9 10 11 10 13 14 ... % left eye
    15:19 ... % left eyebrow
    9 21 22 21 24 25 ... % right eye
    26:30 ... % right eyebrow
    1 32 33 34 34 33 32 32 39 40 40 39 ... % upper lip
    41 44 45 46 47 48 49 ... % lower lip
    47 ... % ren zhong
    51:59 52 61:67]; % jaw


for i = 5:10
    opts.mixture(i) = opts.mixture(4);
end

% global mixture 11:13, right face
opts.mixture(11).poolid = 108:146;
I = 1:39;
J = [6 5 4 3 2 1 ... % nose
    14 15 11 12 13 ... % left eye
    10 9 8 7 ... % eyebrow
    16 17 18 19 20 21 22 ... % outer lip
    25 24 23 26 27 ... % inner lip
    28:39]; % jaw
S = ones(1,39);
opts.mixture(11).anno2treeorder = full(sparse(I,J,S,39,39)); % label transformation
opts.mixture(11).pa = [0:5 ... % nose
    1 7:10 ... % left eye
    11:14 ... % eyebrow
    1 16:21 ... % outer lip
    19 23 24 23 26 ... % inner lip
    22 28:38]; % jaw

opts.mixture(12) = opts.mixture(11);
opts.mixture(13) = opts.mixture(11);


clear I J S i
