function model = model_train(name,pos,neg)

globals;
spos = split(pos);
k    = min(length(neg),200);
kneg = neg(1:k);

% train the parts
file = [cachedir name, '_partpool'];
try
    load(file);
catch
    % If you don't have matlab parallel computing toolbox installed, 
    % comment out "matlabpool(4)" and "matlabpool close",
    % and replace "parfor" with "for"
    matlabpool(5);
    N = opts.partpoolsize;
    sbin = opts.sbin;
    models = cell(N,1);
    parfor i = 1:N
        models{i} = initmodel(spos{i},sbin);
        models{i} = train([name '_p' num2str(i)], models{i}, spos{i}, kneg, 4);
    end
    matlabpool close;
    save(file, 'models');
end

% compute initial deformation
file = [cachedir name '_defs'];
try
    load(file);
catch
    defs = buildmixturedefs(pos,models);
    save(file, 'defs');
end

% build global mixture models
file = [cachedir name '_mix'];
try
    load(file);
catch
    model = buildmixturemodel(models,defs);
    model = train(name, model, pos, kneg, 1);
    save(file, 'model');
end

% update model using full set of negatives.
file = [cachedir name '_final'];
try
    load(file);
catch
    model = train(name, model, pos, neg,2);
    save(file,'model');
end
