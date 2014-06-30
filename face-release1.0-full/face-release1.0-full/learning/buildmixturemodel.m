function model = buildmixturemodel(models,defs)
globals;

assert(length(models)==opts.partpoolsize);
assert(length(defs) == length(opts.mixture));

model.filters = struct('w',{},'i',{});
model.defs = struct('w',{},'i',{},'anchor',{});
model.components{1} = struct('filterid',{},'defid',{},'parent',{});
model.maxsize = models{1}.maxsize;
model.len = 0;
model.interval = models{1}.interval;
model.sbin = models{1}.sbin;

% add filters
for i = 1:length(models)
    if ~isempty(models{i})
        f.w = models{i}.filters(1).w;
        f.i = model.len +1;
        model.filters(i) = f;
        model.len = model.len + numel(f.w);
    end
end


% build global mixtures
for i = 1:length(opts.mixture)
    
    % add defs
    % root parts, global bias
    nd = length(model.defs);
    d.w = 0;
    d.i = model.len +1;
    d.anchor = round([0 0 0]);
    model.defs(nd+1) = d;
    model.len = model.len + numel(d.w);
    
    % def of this component
    c(1).defid = nd + 1;
    
    % non-root parts
    for j = 1:length(defs{i})
        nd = length(model.defs);
        d.w = [0.01 0 0.01 0];
        d.i = model.len +1;
        d.anchor = round([defs{i}(j,:)+1 0]);
        model.defs(nd+1) = d;
        model.len = model.len + numel(d.w);
        % def of this component
        c(j+1).defid = nd + 1;
    end
    
    % add component
    fid = opts.mixture(i).poolid;
    pa =  opts.mixture(i).pa;
    % ## if above line is wrong, then **add** the following line:
    % ## pa = [0; fid(pa(2:end))];
    
    for j = 1:length(opts.mixture(i).pa)
        c(j).filterid = fid(j);
        c(j).parent = pa(j);
    end
    
    model.components{i} = c;
    clear c;
end
