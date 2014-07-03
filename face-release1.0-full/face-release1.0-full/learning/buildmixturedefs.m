function def = buildmixturedefs(pos,models)

globals;

gmixids = [pos.gmixid];

maxsize = models{1}.maxsize;
assert(maxsize(1)==maxsize(2));

boxsize = zeros(1,length(pos));
for n = 1:length(pos)
    boxsize(n) = pos(n).box(1).x2-pos(n).box(1).x1+1;
end

for i = 1:length(opts.mixture)
    idx = find(gmixids==i);
    pa = opts.mixture(i).pa;
    
    % find the points in order
    nparts = length(opts.mixture(i).poolid);
    points = zeros(nparts,2,length(idx));
    for j = 1:length(idx)
        scale0 = boxsize(idx(j))/maxsize(1);
        points(:,:,j) = pos(idx(j)).pts/scale0;
    end
    
    def_temp = zeros(size(points,1)-1,size(points,2),size(points,3));
    for k = 1:length(pa)-1
        % child to parent
        def_temp(k,:,:) = points(k+1,:,:)-points(pa(k+1),:,:);
    end
    
    def{i} = mean(def_temp,3);
    
end