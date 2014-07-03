function boxes = model_test(name,model,ims)
globals;

boxes = cell(length(ims),1);

% matlabpool(6);
for i = 1:length(ims),
    fprintf('%s: testing: %d/%d\n', name, i, length(ims));
    tic
    im = imread(ims(i).im);
    bs = detect_test(im, model, model.thresh);
    if ~isempty(bs)
        bs = clipboxes(im, bs);
        bs = nms_face(bs,0.3);
        % keep the highest scoring one
        boxes{i} = bs(1);
        showboxes(im, boxes{i});
        print(sprintf('%stest%.4d',figdir,i),'-djpeg');
    else
        boxes{i} = [];
    end
    toc
end
% matlabpool close;

function boxes = clipboxes(im, boxes)
% Clips boxes to image boundary.
imy = size(im,1);
imx = size(im,2);
for i = 1:length(boxes),
    b = boxes(i).xy;
    b(:,1) = max(b(:,1), 1);
    b(:,2) = max(b(:,2), 1);
    b(:,3) = min(b(:,3), imx);
    b(:,4) = min(b(:,4), imy);
    boxes(i).xy = b;
end
