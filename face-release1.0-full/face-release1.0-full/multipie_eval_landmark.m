function [accu errtol] = multipie_eval_landmark(boxes,test)
globals;

% number of test images
N = length(test);

% mean error
err = nan(N,1);

for i = 1:N % loop over all test images
    % ground truth
    pts = test(i).pts;
    
    % face size
    w = max(pts(:,1))-min(pts(:,1))+1;
    h = max(pts(:,2))-min(pts(:,2))+1;
    siz = (w+h)/2;
    
    % detection is empty
    if isempty(boxes{i})
        % Missed detection has infinite localization error
        err(i) = nan;
        continue;
    end
    
    b = boxes{i}(1);
    % detection is not overlapping with groundtruth
    if ~testoverlap(b.xy,test(i).pts,0.5)
        % Missed detection has infinite localization error
        err(i) = nan;
        continue;
    end
    
    % detection
    bs = b.xy;
    det = [mean(bs(:,[1 3]),2) mean(bs(:,[2 4]),2)];
    
    % the numbers of parts are different
    if(size(det,1)~=size(pts,1))
        err(i) = nan;
        continue;
    end
    
    dif = pts-det;
    e = (dif(:,1).^2+dif(:,2).^2).^0.5;
    err_in_pixel = mean(e);
    err(i) = err_in_pixel/siz;
end


% plot localization cumulative error
figure;
% sre  = sort(SRE(~isnan(SRE)));
errtol  = sort(err);
accu = linspace(0,1,length(err));
plot(errtol,accu,'b','linewidth',3);
grid on;
xlabel('Average localization error as fraction of face size','fontsize',14);
ylabel('Fraction of the num. of testing faces','fontsize',14);
title('Landmark localization','fontsize',14);
set(gca,'fontsize',14);


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

