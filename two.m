%%TASK 2:
%% A.Edge Detection Script (Sobel, Robert, Prewitt, Laplacian)

% --- 1. Setup and Load Image ---
clc; clear; close all;

% Define the input filename (must be in the same directory or specify full path)
inputFileName = '00012.jpg';

% Define a single threshold value for the gradient-based detectors (Sobel, Prewitt, Robert).
% NOTE: This value needs to be tuned based on the image's overall contrast.
% For the dark image provided, a lower threshold (e.g., 0.05) is usually better 
% when the image data type is normalized to [0, 1].
ThresholdValue = 0.05; 

% Load the image and convert it to grayscale
I = imread(inputFileName);
if size(I, 3) == 3
    I_gray = rgb2gray(I);
else
    I_gray = I;
end

% Convert the image to 'double' for floating-point precision, normalized to [0, 1]
I_double = im2double(I_gray);

% --- Optional: Pre-processing for Dark Images (Recommended) ---
% Use histogram equalization (CLAHE) to boost contrast in the dark areas
I_enhanced = adapthisteq(I_double);

% Optional: Apply a small Gaussian filter to reduce noise before detection
I_processed = imgaussfilt(I_enhanced, 0.5); 


% --- 2. Apply Edge Detection and Thresholding ---

% 2a. Sobel Edge Detection
% Syntax: edge(I, 'sobel', threshold)
BW_sobel = edge(I_processed, 'sobel', ThresholdValue);
imwrite(BW_sobel, 'edge_sobel.jpg');

% 2b. Prewitt Edge Detection
% Syntax: edge(I, 'prewitt', threshold)
BW_prewitt = edge(I_processed, 'prewitt', ThresholdValue);
imwrite(BW_prewitt, 'edge_prewitt.jpg');

% 2c. Roberts Edge Detection
% Syntax: edge(I, 'roberts', threshold)
BW_robert = edge(I_processed, 'roberts', ThresholdValue);
imwrite(BW_robert, 'edge_robert.jpg');

% 2d. Laplacian of Gaussian (LoG) Edge Detection
% The 'log' method finds zero-crossings after smoothing with a Gaussian filter.
% The threshold is applied to the magnitude of the zero-crossing.
% Sigma (standard deviation) is set to 1.5, adjust as needed.
SigmaValue = 1.5; 
BW_laplacian = edge(I_processed, 'log', ThresholdValue, SigmaValue);
imwrite(BW_laplacian, 'edge_laplacian.jpg');


%% --- 3. Display Results for Comparison ---

figure('Name', 'Thresholded Edge Detection Results');

subplot(2, 2, 1);
imshow(BW_sobel);
title('1. Sobel Edge Map (edge\_sobel.jpg)');

subplot(2, 2, 2);
imshow(BW_prewitt);
title('2. Prewitt Edge Map (edge\_prewitt.jpg)');

subplot(2, 2, 3);
imshow(BW_robert);
title('3. Robert Edge Map (edge\_robert.jpg)');

subplot(2, 2, 4);
imshow(BW_laplacian);
title('4. Laplacian (LoG) Edge Map (edge\_laplacian.jpg)');

disp('All four thresholded edge maps have been created and saved.');

%% --- 4. Explanation (Which method best preserved the edges) ---

%{
    Based on the theoretical analysis of a dark, blurry, and potentially noisy image:
    
    The Sobel operator is expected to best preserve the edges.

    Why Sobel?
    1. Noise Reduction: Sobel uses a 3x3 kernel which incorporates smoothing (weighting center pixels higher)
       concurrently with differentiation, making it very effective at suppressing the noise inherent in
       low-light photography while retaining the strong boundary changes (edges).
    2. Edge Cohesion: It generally produces strong, continuous, and well-defined edges, which is better
       for object recognition (like the sign in the image).
    
    Why others might be worse:
    - Robert: Uses a 2x2 kernel, providing minimal smoothing. It is extremely sensitive to noise and would 
      likely produce fragmented or noisy edges.
    - Laplacian: A second-order derivative highly sensitive to noise. While pre-smoothing (LoG) helps, 
      it often detects zero-crossings that correspond to small, non-significant intensity variations, 
      potentially over-segmenting the image with noise.
%}

%B. Morphological Transformation Script
%-------------------------------------------
% Convert to a binary image. Morphological operations are often clearest
% and most standardly applied to binary or grayscale images.
% Since the image is dark, we might need a low threshold or simply work 
% on the grayscale, but for clear morphological effects, binary is typical.
% Let's use Otsu's method to find an automatic threshold for binarization:
T = graythresh(I_gray);
I_binary = imbinarize(I_gray, T);


% --- 2. Define Structuring Element (Kernel) ---

% A simple 3x3 square is a standard choice for general-purpose operations.
% The 'strel' function creates the kernel.
SE = strel('square', 3);


% --- 3. Apply Morphological Operations ---

% 3a. Erosion
% Erodes object boundaries, shrinking bright regions and expanding dark regions.
BW_erosion = imerode(I_binary, SE);
imwrite(BW_erosion, 'morph_erosion.jpg');

% 3b. Dilation
% Expands object boundaries, expanding bright regions and shrinking dark regions.
BW_dilation = imdilate(I_binary, SE);
imwrite(BW_dilation, 'morph_dilation.jpg');

% 3c. Opening (Erosion followed by Dilation)
% Smooths contours, removes small objects (noise), and breaks narrow connections.
BW_opening = imopen(I_binary, SE);
imwrite(BW_opening, 'morph_opening.jpg');

% 3d. Closing (Dilation followed by Erosion)
% Smooths contours, fills small holes, and connects nearby objects.
BW_closing = imclose(I_binary, SE);
imwrite(BW_closing, 'morph_closing.jpg');


%% --- 4. Display Results for Comparison ---

figure('Name', 'Morphological Transformation Results');

subplot(2, 3, 1);
imshow(I_binary);
title('Original Binary Image');

subplot(2, 3, 2);
imshow(BW_erosion);
title('1. Erosion (morph\_erosion.jpg)');

subplot(2, 3, 3);
imshow(BW_dilation);
title('2. Dilation (morph\_dilation.jpg)');

subplot(2, 3, 5);
imshow(BW_opening);
title('3. Opening (morph\_opening.jpg)');

subplot(2, 3, 6);
imshow(BW_closing);
title('4. Closing (morph\_closing.jpg)');

disp('All four morphological transformation images have been created and saved.');