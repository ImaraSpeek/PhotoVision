function pos = point2box(pos)

globals;

boxsize = zeros(1,length(pos));

for n = 1:length(pos)
    gmixid = pos(n).gmixid;
    points = pos(n).pts;
    % parent nodes
    pa = opts.mixture(gmixid).pa;
    
    len = zeros(1,length(pa)-1);
    for i = 1:length(pa)-1
        len(i) = norm(abs(points(i+1,1:2)-points(pa(i+1),1:2)));
    end
    boxsize(n) = quantile(len,0.8);
end

% build boxes
PLOT = 0;
for n = 1:length(pos)
    points = pos(n).pts;
    boxlen = boxsize(n);
    for p = 1:size(points,1)
        pos(n).box(p).x1 = points(p,1) - boxlen/2;
        pos(n).box(p).y1 = points(p,2) - boxlen/2;
        pos(n).box(p).x2 = points(p,1) + boxlen/2;
        pos(n).box(p).y2 = points(p,2) + boxlen/2;
    end
    
    if PLOT
        figure(1); clf;
        im = imread(pos(n).im);
        imshow(im);hold on;
        for p = 1:size(points,1)
            rectangle('Position',[pos(n).box(p).x1,pos(n).box(p).y1,pos(n).box(p).x2-pos(n).box(p).x1,pos(n).box(p).y2-pos(n).box(p).y1],'EdgeColor','b','linewidth',2)
            text(points(p,1),points(p,2),num2str(p));
        end
        drawnow;
        figure(2); clf;
        imshow(im);hold on;
        for p = 1:size(points,1)
            plot(points(p,1),points(p,2),'b.','markersize',14);
            text(points(p,1),points(p,2),num2str(p));
        end
        drawnow;
    end
end
