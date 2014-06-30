PhotoVision
===========

An application that searches through a folder recursively for images of a certain person described using multiple images. The application returns all images found, seperating them into good looking images where the person is smiling and the eyes are open, group pictures and other photos. 

##The problem
The challenge of finding images of a certain person within a database of photos can be split up into multiple parts iterated over all images in the database:

- Process query images
- Detecting faces
- Perform face verification using Active Appearance Models assuming we already have a shape and texture model
    - Fit the model onto any found faces
    - Allign the features 
    - Represent the face's appearance
- Classify the similarity and verify
- Verify whether the person is smiling
- Group all similar photo's 

##The solution



##Implementation

###Used libraries and data
Intraface provides the matlab code for face recognition using OpenCV. However it only recognizes the frontalfaces and does not recognize any profile faces. Intraface initialized the models using certain set parameters: the minimum face score for recognized faces, its minimum neighbors, the minimum face-image ratio an a flag whether or not to compute the pose

###Own implementations




##Experiments



##Results