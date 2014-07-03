function model = train(name, model, pos, neg, iter, C, wpos, maxsize, overlap)
% model = train(name, model, pos, neg, iter, C, Jpos, maxsize, overlap)
%                  1,     2,   3,   4,    5, 6,    7,       8,       9
% Train LSVM.
%
% warp=1 uses warped positives
% warp=0 uses latent positives
% iter is the number of training iterations
% maxsize is the maximum size of the training data cache (in GB)
% overlap is the minimum overlap in latent positive search
% C & Jpos are the parameters for LSVM objective function

if nargin < 5
    iter = 1;
end

if nargin < 6
    C = 0.002;
end

if nargin < 7
    wpos = 2;
end

if nargin < 8
    maxsize = 4;
end

fprintf('Using %.1f GB\n',maxsize);

if nargin < 9
    overlap = 0.6;
end

% Vectorize the model
len  = sparselen(model);
nmax = round(maxsize*.25e9/len);

rand('state',0);
globals;

% Define global QP problem
global qp;
qp_init(len,nmax,5);
[w,qp.wreg,qp.w0,qp.noneg] = model2vec(model);
qp.Cpos = C*wpos;
qp.Cneg = C;
qp.w    = (w - qp.w0).*qp.wreg;

for t = 1:iter,
    fprintf('\niter: %d/%d\n', t, iter);
    model.delta = poslatent(name, t, model, pos, overlap);
    
    % Stop iterations if there is a small change in positive loss
    if model.delta < .001,
        break;
    end
    
    % Fix positive examples as permenant support vectors
    % Initialize QP soln to a valid weight vector
    % Update QP with coordinate descent
    qp.svfix = 1:qp.n;
    qp.sv(qp.svfix) = 1;
    qp_prune();
    qp_opt(.5);
    model = vec2model(qp_w(),model);
    model.interval = 4;
    
    for i = 1:length(neg),
        fprintf('\n Image(%d/%d)',i,length(neg));
        im  = imread(neg(i).im);
        [box,model] = detect(im, model, -1, [], 0, i, -1);
        fprintf(' #cache+%d=%d/%d, #sv=%d, #sv>0=%d, (est)UB=%.4f, LB=%.4f,',length(box),qp.n,nmax,sum(qp.sv),sum(qp.a>0),qp.ub,qp.lb);
        % Stop if cache is full
        if sum(qp.sv) == nmax,
            break;
        end
    end
    
    % One final pass of optimization
    qp_opt();
    model = vec2model(qp_w(),model);
    
    fprintf('\nDONE iter: %d/%d #sv=%d/%d, LB=%.4f\n',t,iter,sum(qp.sv),nmax,qp.lb);
    
    % Compute minimum score on positive example (with raw, unscaled features)
    r = sort(qp_scorepos());
    model.thresh   = r(ceil(length(r)*.05));
    model.interval = 10;
    model.lb = qp.lb;
    model.ub = qp.ub;
    
end
fprintf('qp.x size = [%d %d]\n',size(qp.x));

% get positive examples using latent detections
% we create virtual examples by flipping each image left to right
function delta = poslatent(name, t, model, pos, overlap)
numpos = length(pos);
model.interval = 5;
numpositives = zeros(length(model.components), 1);
% pixels  = model.minsize * model.sbin;
% minsize = prod(pixels);
score0  = qp_scorepos;

global qp;
qp.n = 0;
w    = (model2vec(model) - qp.w0).*qp.wreg;
assert(norm(qp.w - w) < 1e-5);

for i = 1:numpos
    fprintf('%s: iter %d: latent positive: %d/%d', name, t, i, numpos);
    
    numparts = length(pos(i).box);
    bbox.box = zeros(numparts,4);
    bbox.c = pos(i).gmixid;
    for p = 1:numparts
        bbox.box(p,:) = [pos(i).box(p).x1 pos(i).box(p).y1 pos(i).box(p).x2 pos(i).box(p).y2];
    end
    
    % get example
    im = imread(pos(i).im);
    [im, bbox.box] = croppos(im, bbox.box);
    
    box = detect(im, model, 0, bbox, overlap,i,1);
    if ~isempty(box),
        fprintf(' (mix=%d,sc=%.3f)',box.c,box.s);
        numpositives(box.c) = numpositives(box.c)+1;
        %         showboxes(im, box);hold on;
        %         x1 = bbox.box(1,1);
        %         y1 = bbox.box(1,2);
        %         x2 = bbox.box(1,3);
        %         y2 = bbox.box(1,4);
        %         line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', 'g', 'linewidth', 3);
        %         drawnow;
        % Make sure we score better
        if t > 1,
            assert(qp.i(2,qp.n) == i);
            assert(box.s > score0(qp.n) - 1e-3);
        end
    end
    
    fprintf('\n');
end
delta  = inf;
score1 = qp_scorepos();
loss0  = sum(max(0,1-score0));
loss1  = sum(max(0,1-score1));
fprintf('positive loss_prev=%.3f, loss=%.3f\n',loss0,loss1);
for i = 1:length(numpositives),
    fprintf('component %d got %d positives\n', i, numpositives(i));
end
if t > 1,
    assert(loss1 <= loss0);
    delta = abs( (loss0 - loss1)/loss0 );
end
assert(qp.n <= size(qp.x,2));
assert(sum(numpositives) <= 2*numpos);

% Compute score (weights*x) on positives examples
% Standardized QP stores w*x' where w = (weights-w0)*r, x' = c_i*(x/r)
% (w/r + w0)*(x'*r/c_i) = (v + w0*r)*x'/ C
function scores = qp_scorepos()
global qp;
y = qp.i(1,1:qp.n);
I = find(y == 1);
w = qp.w + qp.w0.*qp.wreg;
scores = score(w,qp.x,I) / qp.Cpos;

function len = sparselen(model)

len = 0;
for c = 1:length(model.components),
    numblocks = 0;
    feat = zeros(model.len,1);
    for p = model.components{c},
        x  = model.filters(p.filterid);
        i1 = x.i;
        i2 = i1 + numel(x.w) - 1;
        feat(i1:i2) = 1;
        numblocks = numblocks + 1;
        
        x  = model.defs(p.defid);
        i1 = x.i;
        i2 = i1 + numel(x.w) - 1;
        feat(i1:i2) = 1;
        numblocks = numblocks + 1;
    end
    
    % Number of entries needed to encode a block-sparse representation
    n = 1 + 2*numblocks+sum(feat);
    len = max(len,n);
end

function [im, box] = croppos(im, box)

% [newim, newbox] = croppos(im, box)
% Crop positive example to speed up latent search.

if isvector(box)
    % crop image around bounding box
    pad = 0.5*((box(3)-box(1)+1)+(box(4)-box(2)+1));
    x1 = max(1, round(box(1) - pad));
    y1 = max(1, round(box(2) - pad));
    x2 = min(size(im, 2), round(box(3) + pad));
    y2 = min(size(im, 1), round(box(4) + pad));
    
    im = im(y1:y2, x1:x2, :);
    box([1 3]) = box([1 3]) - x1 + 1;
    box([2 4]) = box([2 4]) - y1 + 1;
    
else
    x1 = box(:,1);
    y1 = box(:,2);
    x2 = box(:,3);
    y2 = box(:,4);
    
    x1 = min(x1); y1 = min(y1); x2 = max(x2); y2 = max(y2);
    pad = 0.5*((x2-x1+1)+(y2-y1+1));
    x1 = max(1, round(x1-pad));
    y1 = max(1, round(y1-pad));
    x2 = min(size(im,2), round(x2+pad));
    y2 = min(size(im,1), round(y2+pad));
    
    im = im(y1:y2, x1:x2, :);
    
    box(:,[1 3]) = box(:,[1 3]) - x1 + 1;
    box(:,[2 4]) = box(:,[2 4]) - y1 + 1;
    
end
