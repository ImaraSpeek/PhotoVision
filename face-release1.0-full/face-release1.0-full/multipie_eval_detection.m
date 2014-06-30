function [ap prec rec] = multipie_eval_detection(boxes,test)

overlap = 0.5;

% number of test images
N = length(test);

% ground truth
gtids = cell(N,1);
for i = 1:N
    gtids(i) = {test(i).im};
end
gt(length(gtids))=struct('BB',[],'diff',[],'det',[]);
npos=length(test);
for i = 1:N
    x1 = min(test(i).pts(:,1));
    y1 = min(test(i).pts(:,2));
    x2 = max(test(i).pts(:,1));
    y2 = max(test(i).pts(:,2));
    b = [x1 y1 x2 y2];
    gt(i).BB = b';
    gt(i).det = false;
end

% detection
nn = sum(cellfun('length',boxes));
b1 = zeros(nn,1);
b2 = zeros(nn,1);
b3 = zeros(nn,1);
b4 = zeros(nn,1);
confidence = zeros(nn,1);
ids = cell(nn,1);
cc = 0;
for i = 1:length(boxes)
    bbox = boxes{i};
    for j = 1:length(bbox)
        cc = cc+1;
        ids(cc) = gtids(i);
        confidence(cc) = bbox(j).s;
        xx = mean(bbox(j).xy(:,[1 3]),2);
        yy = mean(bbox(j).xy(:,[2 4]),2);
        b1(cc) = min(xx);
        b2(cc) = min(yy);
        b3(cc) = max(xx);
        b4(cc) = max(yy);
    end
end
BB=[b1 b2 b3 b4]';

% sort detections by decreasing confidence
[sc,si]=sort(-confidence);
ids=ids(si);
BB=BB(:,si);

% assign detections to ground truth objects
nd=length(confidence);
tp=zeros(nd,1);
fp=zeros(nd,1);
for d=1:nd
    
    % find ground truth image
    i=strmatch(ids{d},gtids,'exact');
    if isempty(i)
        error('unrecognized image "%s"',ids{d});
    elseif length(i)>1
        error('multiple image "%s"',ids{d});
    end
    
    % assign detection to ground truth object if any
    bb=BB(:,d);
    ovmax=-inf;
    for j=1:size(gt(i).BB,2)
        bbgt=gt(i).BB(:,j);
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
        if iw>0 && ih>0
            % compute overlap as area of intersection / area of union
            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                iw*ih;
            ov=iw*ih/ua;
            if ov>ovmax
                ovmax=ov;
                jmax=j;
            end
        end
    end
    % assign detection as true positive/don't care/false positive
    if ovmax>=overlap
        if ~gt(i).det(jmax)
            tp(d)=1;            % true positive
            gt(i).det(jmax)=true;
        else
            fp(d)=1;            % false positive (multiple detection)
        end
    else
        fp(d)=1;                % false positive
    end
end

% compute precision/recall
fp=cumsum(fp);
tp=cumsum(tp);
rec=tp/npos;
prec=tp./(fp+tp);

% compute average precision
ap=0;
for t=0:0.01:1
    p=max(prec(rec>=t));
    if isempty(p)
        p=0;
    end
    ap=ap+p/101;
end

% plot precision/recall
figure;
plot(rec,prec,'-','linewidth',3);
grid on;
xlabel('recall','fontsize',14);
ylabel('precision','fontsize',14);
title(sprintf('ap=%f',ap),'fontsize',14);
set(gca,'fontsize',14);

