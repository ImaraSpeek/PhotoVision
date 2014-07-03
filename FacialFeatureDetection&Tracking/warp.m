  clear all

  input = './data/front.jpg';
  input2 = './data/laurens.jpg';
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

  
%------------------------------------------------------------------------------------------------------------------------------  
  

    % own implemented face detect function, detects 2 more faces
    faces = detect_matfaces( im );
    
    % frontal view and points
    subplot(2, 2, 1), imshow(im); hold on;
    for i = 1:length(faces)
      output = xx_track_detect(Models,im,faces{i},option);
      if ~isempty(output.pred)
        plot(output.pred(:,1),output.pred(:,2),'g*','markersize',5); 
      end
    end

fixedPoints  = [output.pred(20,1) output.pred(20,2); output.pred(29,1) output.pred(29,2); ...
                output.pred(14,1) output.pred(14,2); output.pred(15,1) output.pred(15,2); ...
                output.pred(19,1) output.pred(19,2); ];
convexPoints = [output.pred(1,1) output.pred(1,2); output.pred(2,1) output.pred(2,2); ...
                output.pred(3,1) output.pred(3,2); output.pred(4,1) output.pred(4,2); ...
                output.pred(5,1) output.pred(5,2); output.pred(6,1) output.pred(6,2); ...
                output.pred(7,1) output.pred(7,2); output.pred(8,1) output.pred(8,2); ...
                output.pred(9,1) output.pred(9,2); output.pred(10,1) output.pred(10,2); ...
                output.pred(20,1) output.pred(20,2); output.pred(29,1) output.pred(29,2); ...
                output.pred(32,1) output.pred(32,2); output.pred(38,1) output.pred(38,2); ...
                output.pred(39,1) output.pred(39,2); output.pred(40,1) output.pred(40,2); ...
                output.pred(41,1) output.pred(41,2); output.pred(42,1) output.pred(42,2); ...
                output.pred(43,1) output.pred(43,2);];            
plot(fixedPoints(:,1),fixedPoints(:,2),'r*','markersize',5); 
%plot(convexPoints(:,1),convexPoints(:,2),'y*','markersize',5); hold off;

%draw line for features
% the nose
line([output.pred(11,1) output.pred(14,1)],[output.pred(11,2) output.pred(14,2)]);
% between the eyes
line([output.pred(23,1) output.pred(26,1)],[output.pred(23,2) output.pred(26,2)]);

baseEyes = sqrt(abs(output.pred(11,1) - output.pred(14,1)).^2 + abs((output.pred(11,2) - output.pred(14,2)).^2));
baseNose = sqrt(abs(output.pred(23,1) - output.pred(26,1)).^2 + abs((output.pred(23,2) - output.pred(26,2)).^2));
baseRatio = baseNose / baseEyes;


%------------------------------------------------------------------------------------------------------------------------------


% check if a face is detected to perform a warp later on
facedetected = false;
facesside = detect_matfaces( imside );
if (~cellfun('isempty', facesside))
    %insertObjectAnnotation(imside,'rectangle',facesside{1},'Face');
    subplot(2, 2, 2), imshow(imside); hold on;
        for i = 1:length(faces)
          output2 = xx_track_detect(Models,imside,facesside{i},option);
          if ~isempty(output2.pred)
            plot(output2.pred(:,1),output2.pred(:,2),'g*','markersize',5); 
                facedetected = true;
                movingfixedPoints  =   [output2.pred(20,1) output2.pred(20,2); output2.pred(29,1) output2.pred(29,2); ...
                                        output2.pred(14,1) output2.pred(14,2); output2.pred(15,1) output2.pred(15,2); ...
                                        output2.pred(19,1) output2.pred(19,2); ];    
                plot(movingfixedPoints(:,1), movingfixedPoints(:,2), 'c*', 'markersize',5);    
          end
        end
else
        error('no face detected in queried image');
end
hold off;

%------------------------------------------------------------------------------------------------------------------------------

% STARTING THE WARP 
if facedetected == true;
    % generate the piecewise affine transformation
    tform = fitgeotrans(movingfixedPoints,fixedPoints,'Affine');
    %tform = cp2tform(movingPoints, fixedPoints, 'piecewise linear');
    imsidewarp = imwarp(imside,tform,'OutputView',imref2d(size(im)));

    faceswarp = detect_matfaces( imsidewarp );
        if (~cellfun('isempty', faceswarp))
        % TODO generalize this
        faceswarp{1} = [(faceswarp{1}(1) - faceswarp{1}(3) / 4) (faceswarp{1}(2) - faceswarp{1}(2) / 4) ...
                        (faceswarp{1}(3) * 1.25) (faceswarp{1}(4) * 1.25)];
        imsidebound = insertObjectAnnotation(imsidewarp,'rectangle',faceswarp{1},'Face');
        for i = 1:length(facesside)
                    output3 = xx_track_detect(Models,imsidewarp,faceswarp{i},option);
           if ~isempty(output3.pred)
                    % first select the mean control points and the examples control points
                    movingPoints  = [output3.pred(20,1) output3.pred(20,2); output3.pred(29,1) output3.pred(29,2); ...
                                     output3.pred(14,1) output3.pred(14,2); output3.pred(15,1) output3.pred(15,2); ...
                                     output3.pred(19,1) output3.pred(19,2); ];
           end
        end 

        % approximate the normalized face

            subplot(2,2,3), imshow(imsidewarp); hold on;
                %insertObjectAnnotation(imsidewarp,'rectangle',faceswarp{1},'Face');
                plot(fixedPoints(:,1),fixedPoints(:,2),'r*','markersize',5);       
                plot(output3.pred(:,1),output3.pred(:,2),'g*','markersize',5);
                plot(movingPoints(:,1),movingPoints(:,2),'c*','markersize',5);
                %draw line for features
                % the nose
                line([output3.pred(11,1) output3.pred(14,1)],[output3.pred(11,2) output3.pred(14,2)]);
                % between the eyes
                line([output3.pred(23,1) output3.pred(26,1)],[output3.pred(23,2) output3.pred(26,2)]);
            hold off;

        queryEyes = sqrt(abs(output3.pred(11,1) - output3.pred(14,1)).^2 + abs((output3.pred(11,2) - output3.pred(14,2)).^2));
        queryNose = sqrt(abs(output3.pred(23,1) - output3.pred(26,1)).^2 + abs((output3.pred(23,2) - output3.pred(26,2)).^2));

        queryRatio = queryNose / queryEyes;

            falsecolorOverlay = imfuse(im,imsidewarp);
            subplot(2,2,4), imshow(falsecolorOverlay,'InitialMagnification','fit'); hold on;
                plot(fixedPoints(:,1),fixedPoints(:,2),'r*','markersize',5); 
                plot(movingPoints(:,1),movingPoints(:,2),'c*','markersize',5);
            hold off
        else
            error('no face is detected in the warp');
        end
           
end