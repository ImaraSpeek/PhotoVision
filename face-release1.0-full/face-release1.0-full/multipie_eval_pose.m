function [accu errtol] = multipie_eval_pose(boxes,test)
globals;

mix2view = opts.viewpoint;

% number of test images
N = length(test);

posEst = zeros(N,1);
posGt = zeros(N,1);

for i = 1:N
    % ground truth
    posGt(i) = mix2view(test(i).gmixid);
    
    % detection is empty
    if isempty(boxes{i})
        % Missed detection has infinite pose estimation error
        posEst(i) = nan;
        continue;
    end
    
    b = boxes{i}(1);
    % detection is not overlapping with groundtruth
    if ~testoverlap(b.xy,test(i).pts,0.5)
        % Missed detection has infinite pose estimation error
        posEst(i) = nan;
        continue;
    end

    posEst(i) = mix2view(b.c);
end

% cumulative pose error curve
poseerror = abs(posGt-posEst);
errtol = 0:15:90;
accu = cumsum(hist(poseerror,errtol))/N;

figure;
plot(errtol,accu,'b','linewidth',3);
grid on;
xlabel('Pose estimation error (in degrees)','fontsize',14);
ylabel('Fraction of the num. of testing faces','fontsize',14);
title('Pose estimation','fontsize',14);
set(gca,'fontsize',14);
set(gca,'xtick',errtol);


function ov = testoverlap(box,pts,thresh)
boxc = [mean(box(:,[1 3]),2) mean(box(:,[2 4]),2)];

b1 = [min(boxc(:,1)) min(boxc(:,2)) max(boxc(:,1)) max(boxc(:,2))];
b2 = [min(pts(:,1)) min(pts(:,2)) max(pts(:,1)) max(pts(:,2))];

bi=[max(b1(1),b2(1)) ; max(b1(2),b2(2)) ; min(b1(3),b2(3)) ; min(b1(4),b2(4))];
iw=bi(3)-bi(1)+1;
ih=bi(4)-bi(2)+1;
if iw>0 && ih>0
    % compute overlap as area of intersection / area of union
    ua=(b1(3)-b1(1)+1)*(b1(4)-b1(2)+1)+...
        (b2(3)-b2(1)+1)*(b2(4)-b2(2)+1)-...
        iw*ih;
    ov=iw*ih/ua;
end
ov = (ov>thresh);
