function [DETS,PTS,DESCS,confs]=extfacedescs(opts,I,debug)


    imname = ['face_detects/' num2str(sum(I(:))) '.mat'];
    if isempty(dir(imname))

        if nargin<3
            debug=false;
        end

        % Detect face and convert detections to strange Zisserman format
        faces = FastFaceDetect(I);
        faces = faces{1};
        DETS = zeros(size(faces));
        DETS(1,:) = (faces(2,:) + faces(1,:)) / 2;
        DETS(2,:) = (faces(4,:) + faces(3,:)) / 2;
        DETS(3,:) = ((faces(2,:) - faces(1,:)) + (faces(4,:) - faces(3,:))) / 4;
        DETS(4,:) = 1;

        PTS=zeros(0,0,size(DETS,2));
        DESCS=zeros(0,size(DETS,2));
        confs = zeros(1, size(DETS, 2));
        for i=1:size(DETS,2)

            [P, confs(i)]=findparts(opts.model, I, DETS(:,i));
            PTS(1:size(P,1),1:size(P,2),i)=P;
            if debug
                figure(1);
                imagesc(I);
                hold on;
                plot(DETS(1, i) + DETS(3, i) * [-1 1 1 -1 -1], ...
                     DETS(2, i) + DETS(3, i) * [-1 -1 1 1 -1], 'y-', 'linewidth', 1);
                cmap = jet(size(PTS, 2));
                for j=1:size(PTS, 2)
                    plot(PTS(1,j,i), PTS(2,j,i), 'y+', 'markersize', 10, 'linewidth', 1, 'color', cmap(j,:));
                    text(PTS(1,j,i), PTS(2,j,i), num2str(j));
                end
                colorbar
                hold off;
                axis image;
                colormap gray;
                pause
            end 
        end
        save(imname, 'DETS', 'PTS', 'DESCS', 'confs');
    else
        load(imname);
    end
