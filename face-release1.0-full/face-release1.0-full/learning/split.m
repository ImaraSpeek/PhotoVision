function spos = split(pos)
% split parts into part pool
globals;

spos = cell(opts.partpoolsize,1);
for i = 1:length(pos)
    gmixid = pos(i).gmixid;
    % map new ordered part in the tree to part pool
    partids_inpool = opts.mixture(gmixid).poolid;
    
    for j = 1:length(partids_inpool)
        s.im = pos(i).im;
        s.gmixid = 1;
        s.box.x1 = pos(i).box(j).x1;
        s.box.y1 = pos(i).box(j).y1;
        s.box.x2 = pos(i).box(j).x2;
        s.box.y2 = pos(i).box(j).y2;
        spos{partids_inpool(j)} = [spos{partids_inpool(j)} s];
    end
    
end