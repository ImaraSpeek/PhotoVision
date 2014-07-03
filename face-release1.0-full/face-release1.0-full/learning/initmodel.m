function model = initmodel(pos, sbin)

% pick mode of aspect ratios

h = zeros(length(pos),1);
w = zeros(length(pos),1);
for i = 1:length(pos)
    h(i) = pos(i).box.y2 - pos(i).box.y1 + 1;
    w(i) = pos(i).box.x2 - pos(i).box.x1 + 1;
end

% pick 20 percentile area
areas = sort(h.*w);
area = areas(floor(length(areas) * 0.2));

% pick dimensions
nw  = sqrt(area);
nh  = nw;
nf = length(features(zeros([3 3 3]),1));


size = [round(nh/sbin) round(nw/sbin) nf];


% deformation
d.w  = 0;
d.i  = 1;
d.anchor = [0 0 0];

% filter
f.w = zeros(size);
f.i = 1+1;

% set up one component model
c(1).filterid = 1;
c(1).defid    = 1;
c(1).parent   = 0;
model.defs(1)    = d;
model.filters(1) = f;
model.components{1} = c;

% initialize the rest of the model structure
model.maxsize  = size(1:2);
model.len      = 1+prod(size);
model.interval = 10;
model.sbin     = sbin;

model = poswarp(model,pos);

% get positive examples by warping positive bounding boxes
function model = poswarp(model,pos)
warped = warppos( model, pos);
siz    = size(model.filters(1).w);
ny = siz(1);
nx = siz(2);
nf = siz(3)-1;

% Cache features
num  = length(warped);
feats = zeros(ny*nx*nf,num);
for i = 1:num,
    im = warped{i};
    feat = features(im,model.sbin);
    feat = feat(:,:,1:end-1);
    feats(:,i) = feat(:);
end

w = mean(feats,2);
score = w'*w;

w = reshape(w,[ny nx nf]);
w(:,:,end+1) = 0;
model.filters(1).w = w;
model.obj    = -score;

function warped = warppos(model, pos)

f   = model.components{1}(1).filterid;
siz = size(model.filters(f).w);
siz = siz(1:2);
pixels = siz * model.sbin;
numpos = length(pos);
heights = zeros(numpos,1);
widths = zeros(numpos,1);
for i = 1:numpos
    heights(i) = pos(i).box.y2 - pos(i).box.y1 + 1;
    widths(i) = pos(i).box.x2 - pos(i).box.x1 + 1;
end
cropsize = (siz+2) * model.sbin;
warped  = [];
for i = 1:numpos
    fprintf('warp: %d/%d\n', i, numpos);
    im = (imread(pos(i).im));
    padx = model.sbin * widths(i) / pixels(2);
    pady = model.sbin * heights(i) / pixels(1);
    x1 = round(pos(i).box.x1-padx);
    x2 = round(pos(i).box.x2+padx);
    y1 = round(pos(i).box.y1-pady);
    y2 = round(pos(i).box.y2+pady);
    window = subarray(im, y1, y2, x1, x2, 1);
    warped{end+1} = imresize(window, cropsize, 'bilinear');
end

function B = subarray(A, i1, i2, j1, j2, pad)

% B = subarray(A, i1, i2, j1, j2, pad)
% Extract subarray from array
% pad with boundary values if pad = 1
% pad with zeros if pad = 0

dim = size(A);
B = zeros(i2-i1+1, j2-j1+1, dim(3));
if pad
    for i = i1:i2
        for j = j1:j2
            ii = min(max(i, 1), dim(1));
            jj = min(max(j, 1), dim(2));
            B(i-i1+1, j-j1+1, :) = A(ii, jj, :);
        end
    end
else
    for i = max(i1,1):min(i2,dim(1))
        for j = max(j1,1):min(j2,dim(2))
            B(i-i1+1, j-j1+1, :) = A(i, j, :);
        end
    end
end

