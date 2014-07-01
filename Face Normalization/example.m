% Description:
% This script gets a facial still image, produced by desktop scanners
% and extracts a standard normalized image, according to ISO standard 
% for E-passport applications, based on the position of eyes. Built-in
% functions use 'eyefinder' function, which is included in Machine
% Perception Toolbox, University of California San Diego. For copyright
% notes, please refer to readme.txt.

% Original version by Amir Hossein Omidvarnia,  October 2007
% Email: aomidvar@ece.ut.ac.ir

clear all
clc
close all

% [inputfilename,dirname] = uigetfile('*.*');
% inputfilename = [dirname, inputfilename];
% im = imread(inputfilename); % For example: 'input.jpg'

im = imread('input.jpg');

[canon_image, init_cropping] = faceNormalization(im);
imshow(canon_image)
figure, imshow(init_cropping)
