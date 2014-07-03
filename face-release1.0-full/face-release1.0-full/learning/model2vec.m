function [w,wreg,w0,noneg] = model2vec(model)
% [w,wreg,w0,nonneg] = model2vec(model)

w     = zeros(model.len,1);
w0    = zeros(model.len,1);
wreg  = ones(model.len,1);
noneg = uint32([]);

for x = model.defs,
    j = x.i:x.i+prod(size(x.w))-1;
    w(j) = x.w;
    if length(j) == 1,
        wreg(j) = .01;
%wreg(j) = .001;
    else
        wreg(j) = 0.1;
% Enforce minimum quadratic deformation costs of .01
        j = [j(1) j(3)];
        w0(j) = .01;
        noneg = [noneg uint32(j)];
    end
end

for x = model.filters,
    if x.i > 0,
        j = x.i:x.i+prod(size(x.w))-1;
        w(j) = x.w;
    end
end

assert(length(w) == model.len);
