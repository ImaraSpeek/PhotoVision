  input = './data/front.jpg';
  input2 = './data/side.jpg';
  mode = 'auto';
  
  % read image from input file
  im=imread(input);
  imside=imread(input2);
  
  % check whether the image is too big
  if size(im, 1) > 600
      im = cv.resize(im, (600 / size(im, 1)));
  end
  
  if size(imside, 1) > 600
      imside = cv.resize(imside, (600 / size(imside, 1)));
  end
  
  % load model and parameters, type 'help xx_initialize' for more details
  [Models,option] = xx_initialize;

    % own implemented face detect function, detects 2 more faces
    faces = detect_matfaces( im );
    
    % frontal view and points
    subplot(2, 2, 1), imshow(im); hold on;
    for i = 1:length(faces)
      output = xx_track_detect(Models,im,faces{i},option);
      if ~isempty(output.pred)
        plot(output.pred(:,1),output.pred(:,2),'g*','markersize',2); 
      end
    end
    
fixedPoints  = [faces{1}(1) faces{1}(2); (faces{1}(1) + faces{1}(3)) faces{1}(2); ...
                            faces{1}(1) (faces{1}(2) + faces{1}(4)); (faces{1}(1) + faces{1}(3)) (faces{1}(2) + faces{1}(4)); ...
                            double(output.pred(21,1)) double(output.pred(21,2)); double(output.pred(22,1)) double(output.pred(22,2)); ...
                            double(output.pred(24,1)) double(output.pred(24,2)); double(output.pred(25,1)) double(output.pred(25,2)); ...
                            double(output.pred(27,1)) double(output.pred(27,2)); double(output.pred(28,1)) double(output.pred(28,2)); ...
                            double(output.pred(30,1)) double(output.pred(30,2)); double(output.pred(31,1)) double(output.pred(31,2)); ...
                            double(output.pred(41,1)) double(output.pred(41,2)); double(output.pred(14,1)) double(output.pred(14,2)); ];

facesside = detect_matfaces( imside );
subplot(2, 2, 2), imshow(imside); hold on;
    for i = 1:length(faces)
      output2 = xx_track_detect(Models,imside,facesside{i},option);
      if ~isempty(output2.pred)
        plot(output2.pred(:,1),output2.pred(:,2),'g*','markersize',2); 
      end
    end                        
                        
for f=1:10    
    facesside = detect_matfaces( imside );
    % profile view
    subplot(2, 2, 3), imshow(imside); hold on;
      
        for i = 1:length(facesside)
            output2 = xx_track_detect(Models,imside,facesside{i},option);
          if ~isempty(output2.pred)
            plot(output2.pred(:,1),output2.pred(:,2),'g*','markersize',2);
            plot(fixedPoints(:,1),fixedPoints(:,2),'r*','markersize',2); 

            % first select the mean control points and the examples control points
            movingPoints = [facesside{1}(1) facesside{1}(2); (facesside{1}(1) + facesside{1}(3)) facesside{1}(2); ...
                            facesside{1}(1) (facesside{1}(2) + facesside{1}(4)); (facesside{1}(1) + facesside{1}(3)) (facesside{1}(2) + facesside{1}(4)); ...
                            double(output2.pred(21,1)) double(output2.pred(21,2)); double(output2.pred(22,1)) double(output2.pred(22,2)); ...
                            double(output2.pred(24,1)) double(output2.pred(24,2)); double(output2.pred(25,1)) double(output2.pred(25,2)); ...
                            double(output2.pred(27,1)) double(output2.pred(27,2)); double(output2.pred(28,1)) double(output2.pred(28,2)); ...
                            double(output2.pred(30,1)) double(output2.pred(30,2)); double(output2.pred(31,1)) double(output2.pred(31,2)); ...
                            double(output2.pred(41,1)) double(output2.pred(41,2)); double(output2.pred(14,1)) double(output2.pred(14,2));];
            % generate the piecewise affine transformation
            tform = fitgeotrans(movingPoints,fixedPoints,'Affine');
            %tform = cp2tform(movingPoints, fixedPoints, 'piecewise linear');
            imside = imwarp(imside,tform,'OutputView',imref2d(size(im)));
            
          end
        end
end   
    falsecolorOverlay = imfuse(im,imside);
    subplot(2,2,4), imshow(falsecolorOverlay,'InitialMagnification','fit');
    %subplot(1,3,3), imshow(Jregistered);
    
    %facesside = detect_matfaces( imside );
    %subplot(1,3,2), imshow(imside); hold on;
%     output3 = xx_track_detect(Models,imside,facesside{1},option);
%            if ~isempty(output3.pred)
%             plot(output3.pred(:,1),output3.pred(:,2),'g*','markersize',2);
%             plot(fixedPoints(:,1),fixedPoints(:,2),'r*','markersize',2); 
%           end
    hold off