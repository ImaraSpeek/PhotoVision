function model = vec2model(w,model)
% model = vec2model(w,model)

w = double(w);

% Deformation parameters
for i = 1:length(model.defs),
  x = model.defs(i);
  s = size(x.w);
  j = x.i:x.i+prod(s)-1;
  model.defs(i).w = reshape(w(j),s);
end

% Filters 
for i = 1:length(model.filters),
  x = model.filters(i);
  if x.i > 0,
    s = size(x.w);
    j = x.i:x.i+prod(s)-1;
    model.filters(i).w = reshape(w(j),s);
  end
end

% Debug
w2 = model2vec(model);
assert(isequal(w,w2));
