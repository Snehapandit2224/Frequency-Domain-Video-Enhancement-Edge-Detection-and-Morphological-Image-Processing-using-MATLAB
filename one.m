% one.m - Video Noise Removal and Captioning Analysis (Cleaned & Robust)
% This script applies MINIMAL enhancement for images with light noise
% Preserves maximum detail and sharpness

clearvars;
close all;
clc;

%% Step 1: Video setup
videoFile = '12.mp4'; % update if needed

if ~exist(videoFile, 'file')
    error('Video file not found. Please update the videoFile path.');
end

vidObj = VideoReader(videoFile);

outputFolder = 'extracted_frames';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Use frame reading loop (more robust than relying on NumFrames)
fprintf('Reading video: %s\n', videoFile);
frameNumber = 0;
allFrames = {};

% compute approximate total frames from duration * framerate if available
try
    approxTotal = round(vidObj.FrameRate * vidObj.Duration);
catch
    approxTotal = [];
end

while hasFrame(vidObj)
    frameNumber = frameNumber + 1;
    frame = readFrame(vidObj);
    allFrames{frameNumber} = frame;
    
    % Save a subset to avoid too many files
    if isempty(approxTotal)
        saveInterval = 1; % fallback: save all if unknown
    else
        saveInterval = max(1, floor(approxTotal / 50));
    end
    
    if mod(frameNumber, saveInterval) == 0 || frameNumber == 1
        filename = fullfile(outputFolder, sprintf('frame_%04d.png', frameNumber));
        imwrite(frame, filename);
    end
end

if isempty(allFrames)
    error('No frames extracted from video.');
end

fprintf('Extracted %d frames (approx total: %s)\n', numel(allFrames), mat2str(approxTotal));

%% Step 2: Select middle frame
selectedFrameIdx = round(numel(allFrames) / 2);
selectedFrame = allFrames{selectedFrameIdx};

% Convert to grayscale if RGB
if size(selectedFrame, 3) == 3
    grayFrame = rgb2gray(selectedFrame);
else
    grayFrame = selectedFrame;
end

% Convert to double for processing, scale to [0,255] if needed
grayFrame = double(grayFrame);

% Save original noisy frame
imwrite(uint8(grayFrame), 'prenoise.jpg');
fprintf('Saved original frame as prenoise.jpg\n');

%% Step 3: Estimate noise level
fprintf('\n=== Analyzing Image Quality ===\n');
noise_estimate = median(abs(grayFrame(:) - median(grayFrame(:)))) / 0.6745;
image_variance = var(grayFrame(:));
fprintf('Estimated noise level: %.2f\n', noise_estimate);
fprintf('Image variance: %.2f\n', image_variance);

if noise_estimate < 10
    processing_mode = 'minimal';
elseif noise_estimate < 20
    processing_mode = 'light';
else
    processing_mode = 'standard';
end
fprintf('Selected processing mode: %s\n', processing_mode);

%% Step 4: Frequency domain conversion
fprintf('Converting to frequency domain...\n');
F = fft2(grayFrame);
F_shifted = fftshift(F);
magnitude_spectrum = log(1 + abs(F_shifted));

[M, N] = size(grayFrame);
[u, v] = meshgrid(1:N, 1:M);
center_u = ceil(N/2);
center_v = ceil(M/2);
D = sqrt((u - center_u).^2 + (v - center_v).^2);

% Adaptive filter parameters
switch processing_mode
    case 'minimal'
        D0 = 80; n = 1; filter_strength = 0.3;
    case 'light'
        D0 = 60; n = 2; filter_strength = 0.5;
    otherwise
        D0 = 40; n = 2; filter_strength = 0.7;
end

H_butterworth = 1 ./ (1 + (D ./ D0).^(2*n));
H_final = filter_strength * H_butterworth + (1 - filter_strength);

% Apply filter
F_filtered = F_shifted .* H_final;

%% Step 5: Back to spatial
enhanced_freq = real(ifft2(ifftshift(F_filtered)));
enhanced_freq = enhanced_freq - min(enhanced_freq(:));
if max(enhanced_freq(:)) > 0
    enhanced_freq = enhanced_freq ./ max(enhanced_freq(:)) * 255;
end
enhanced_freq = uint8(enhanced_freq);

%% Step 6: Minimal spatial processing (if needed)
if strcmp(processing_mode, 'minimal')
    enhanced_final = enhanced_freq;
elseif strcmp(processing_mode, 'light')
    enhanced_final = medfilt2(enhanced_freq, [3 3]);
else
    enhanced_final = wiener2(enhanced_freq, [3 3]);
end

% Optional gentle sharpening if smoothing was done
if ~strcmp(processing_mode, 'minimal')
    gaussian_blur = imgaussfilt(enhanced_final, 0.5);
    unsharp_mask = double(enhanced_final) - double(gaussian_blur);
    sharpness_boost = 0.3;
    enhanced_final = enhanced_final + uint8(sharpness_boost * unsharp_mask);
end

%% Step 7: Alternative versions and saving
version1 = enhanced_freq;
if exist('imnlmfilt', 'file')
    version2 = imnlmfilt(uint8(grayFrame), 'DegreeOfSmoothing', 2);
else
    version2 = enhanced_final;
end
if exist('imbilatfilt', 'file')
    version3 = imbilatfilt(uint8(grayFrame), 'DegreeOfSmoothing', 2);
else
    version3 = enhanced_final;
end
version4 = histeq(uint8(grayFrame));

imwrite(version1, 'postnoise_freq_only.jpg');
imwrite(version2, 'postnoise_nlm.jpg');
imwrite(version3, 'postnoise_bilateral.jpg');
imwrite(version4, 'postnoise_contrast.jpg');
imwrite(enhanced_final, 'postnoise.jpg');

fprintf('Saved prenoise.jpg and postnoise (and alternatives).\n');

%% Step 8: Visualization & metrics (keeps your plotting approach)
figure('Position', [50, 50, 1600, 1000]);
% ... (retain your plotting code here) ...
subplot(2,3,1);
imshow(uint8(grayFrame));
title('Original (prenoise.jpg)');

subplot(2,3,2);
imshow(version1);
title('Frequency Filtered (postnoise\_freq\_only.jpg)');

subplot(2,3,3);
imshow(version2);
title('NLM (postnoise\_nlm.jpg)');

subplot(2,3,4);
imshow(version3);
title('Bilateral (postnoise\_bilateral.jpg)');

subplot(2,3,5);
imshow(version4);
title('Contrast Enhanced (postnoise\_contrast.jpg)');

subplot(2,3,6);
imshow(enhanced_final);
title('Final Output (postnoise.jpg)');

sgtitle('Video Noise Removal — Comparison of Enhancement Methods');

% For brevity in this version, reuse your plotting code block from original script.
% Save a comparison figure if desired:
try
    saveas(gcf, 'minimal_processing_comparison.png');
    fprintf('Saved comparison figure: minimal_processing_comparison.png\n');
catch
    warning('Couldn''t save the comparison figure automatically.');
end

%% Step 9: Quality metrics printed to console
% Compute sharpness for versions (Original, Freq, NLM, Bilateral, Final)
versions = {uint8(grayFrame), version1, version2, version3, enhanced_final};
version_names = {'Original', 'Freq', 'NLM', 'Bilateral', 'Final'};
sharpness_values = zeros(1, length(versions));

for i = 1:length(versions)
    [Gx, Gy] = gradient(double(versions{i}));
    sharpness_values(i) = mean(sqrt(Gx(:).^2 + Gy(:).^2));
end

fprintf('\nVersion    SharpnessRetained(%%)\n');
for i = 1:length(versions)
    retain_pct = 100 * sharpness_values(i) / sharpness_values(1);
    fprintf('%-10s  %7.2f%%\n', version_names{i}, retain_pct);
end

fprintf('\nScript finished. Use prenoise.jpg and postnoise.jpg for BLIP2 captioning tests.\n');

% one.m - Video Noise Removal and Captioning Analysis (Minimal Processing)
% This script applies MINIMAL enhancement for images with light noise
% Preserves maximum detail and sharpness
%{ 
clear all;
close all;
clc;

%% Step 1: Extract frames from video
% Specify the video file path (update this path to your video file)
videoFile = '12.mp4'; % Change this to your video file path

% Check if video file exists
if ~exist(videoFile, 'file')
    error('Video file not found. Please update the videoFile path.');
end

% Create a VideoReader object
vidObj = VideoReader(videoFile);

% Create a folder to save the frames
outputFolder = 'extracted_frames';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Get video information
totalFrames = vidObj.NumFrames;
frameRate = vidObj.FrameRate;
duration = vidObj.Duration;

fprintf('Video Information:\n');
fprintf('  Total Frames: %d\n', totalFrames);
fprintf('  Frame Rate: %.2f fps\n', frameRate);
fprintf('  Duration: %.2f seconds\n', duration);

% Extract ALL frames
frameNumber = 1;
allFrames = {};

fprintf('\nExtracting ALL frames from video...\n');
while hasFrame(vidObj)
    frame = readFrame(vidObj);
    allFrames{frameNumber} = frame;
    
    % Save every Nth frame (to avoid too many files)
    % Adjust this number based on your needs
    saveInterval = max(1, floor(totalFrames / 50)); % Save ~50 frames
    if mod(frameNumber, saveInterval) == 0 || frameNumber == 1
        filename = fullfile(outputFolder, sprintf('frame_%04d.png', frameNumber));
        imwrite(frame, filename);
    end
    
    % Progress indicator
    if mod(frameNumber, 100) == 0
        fprintf('  Processed %d/%d frames (%.1f%%)\n', ...
            frameNumber, totalFrames, 100*frameNumber/totalFrames);
    end
    
    frameNumber = frameNumber + 1;
end

fprintf('Successfully extracted ALL %d frames.\n', frameNumber - 1);

%% Step 2: Select a middle frame for processing
selectedFrameIdx = round(length(allFrames) / 2);
selectedFrame = allFrames{selectedFrameIdx};

% Convert to grayscale if RGB
if size(selectedFrame, 3) == 3
    grayFrame = rgb2gray(selectedFrame);
else
    grayFrame = selectedFrame;
end

% Convert to double for processing
grayFrame = double(grayFrame);

% Save the original noisy frame
imwrite(uint8(grayFrame), 'prenoise.jpg');
fprintf('Saved original frame as prenoise.jpg\n');

%% Step 3: Analyze noise level first
fprintf('\n=== Analyzing Image Quality ===\n');

% Estimate noise level using robust median absolute deviation
noise_estimate = median(abs(grayFrame(:) - median(grayFrame(:)))) / 0.6745;
fprintf('Estimated noise level: %.2f\n', noise_estimate);

% Calculate image variance (indicator of detail)
image_variance = var(grayFrame(:));
fprintf('Image variance: %.2f\n', image_variance);

% Determine if aggressive processing is needed
if noise_estimate < 10
    fprintf('==> Image has LOW noise. Using MINIMAL processing.\n');
    processing_mode = 'minimal';
elseif noise_estimate < 20
    fprintf('==> Image has MODERATE noise. Using LIGHT processing.\n');
    processing_mode = 'light';
else
    fprintf('==> Image has HIGH noise. Using STANDARD processing.\n');
    processing_mode = 'standard';
end

%% Step 4: Convert to frequency domain
fprintf('\nConverting to frequency domain...\n');

% Apply 2D FFT
F = fft2(grayFrame);
F_shifted = fftshift(F);

% Get magnitude spectrum
magnitude_spectrum = log(1 + abs(F_shifted));

%% Step 5: ADAPTIVE filtering based on noise level
fprintf('Applying adaptive filtering...\n');

[M, N] = size(grayFrame);
[u, v] = meshgrid(1:N, 1:M);
center_u = ceil(N/2);
center_v = ceil(M/2);
D = sqrt((u - center_u).^2 + (v - center_v).^2);

% Design filter based on noise level
switch processing_mode
    case 'minimal'
        % Very light filtering - preserve maximum detail
        D0 = 80;  % Very high cutoff
        n = 1;    % Low order
        filter_strength = 0.3;
        
    case 'light'
        % Light filtering
        D0 = 60;
        n = 2;
        filter_strength = 0.5;
        
    case 'standard'
        % Standard filtering
        D0 = 40;
        n = 2;
        filter_strength = 0.7;
end

% Butterworth filter
H_butterworth = 1 ./ (1 + (D / D0).^(2*n));

% Apply partial filtering to preserve detail
H_final = filter_strength * H_butterworth + (1 - filter_strength);

% Filter in frequency domain
F_filtered = F_shifted .* H_final;

%% Step 6: Convert back to spatial domain
enhanced_freq = real(ifft2(ifftshift(F_filtered)));
enhanced_freq = enhanced_freq - min(enhanced_freq(:));
enhanced_freq = enhanced_freq / max(enhanced_freq(:)) * 255;
enhanced_freq = uint8(enhanced_freq);

%% Step 7: MINIMAL spatial processing
fprintf('Applying minimal spatial enhancement...\n');

% Option 1: No additional filtering (recommended for low noise)
if strcmp(processing_mode, 'minimal')
    fprintf('Mode: MINIMAL - Using frequency filter only.\n');
    enhanced_final = enhanced_freq;
    
% Option 2: Very light median filter (for light noise)
elseif strcmp(processing_mode, 'light')
    fprintf('Mode: LIGHT - Adding gentle median filter.\n');
    enhanced_final = medfilt2(enhanced_freq, [3 3]);
    
% Option 3: Standard Wiener filter (for high noise)
else
    fprintf('Mode: STANDARD - Using Wiener filter.\n');
    enhanced_final = wiener2(enhanced_freq, [3 3]);
end

%% Step 8: Optional sharpness enhancement
% Only apply if we did any smoothing
if ~strcmp(processing_mode, 'minimal')
    fprintf('Applying compensatory sharpening...\n');
    
    % Gentle unsharp masking
    gaussian_blur = imgaussfilt(enhanced_final, 0.5);
    unsharp_mask = double(enhanced_final) - double(gaussian_blur);
    sharpness_boost = 0.3; % Very gentle
    enhanced_final = enhanced_final + uint8(sharpness_boost * unsharp_mask);
end

%% Step 9: Create alternative versions
fprintf('Creating alternative versions...\n');

% Version 1: Frequency domain only
version1 = enhanced_freq;

% Version 2: With Non-Local Means (if available)
if exist('imnlmfilt', 'file')
    version2 = imnlmfilt(uint8(grayFrame), 'DegreeOfSmoothing', 2);
    fprintf('Created NLM version (best for preserving details).\n');
else
    version2 = enhanced_final;
end

% Version 3: Bilateral filter (if available)
if exist('imbilatfilt', 'file')
    version3 = imbilatfilt(uint8(grayFrame), 'DegreeOfSmoothing', 2);
    fprintf('Created bilateral filter version.\n');
else
    version3 = enhanced_final;
end

% Version 4: Simple contrast enhancement only
version4 = histeq(uint8(grayFrame));

%% Step 10: Save all versions
imwrite(version1, 'postnoise_freq_only.jpg');
imwrite(version2, 'postnoise_nlm.jpg');
imwrite(version3, 'postnoise_bilateral.jpg');
imwrite(version4, 'postnoise_contrast.jpg');
imwrite(enhanced_final, 'postnoise.jpg');

fprintf('\n=== Saved Files ===\n');
fprintf('  prenoise.jpg - Original frame\n');
fprintf('  postnoise.jpg - Final enhanced (RECOMMENDED)\n');
fprintf('  postnoise_freq_only.jpg - Frequency filter only\n');
fprintf('  postnoise_nlm.jpg - Non-Local Means\n');
fprintf('  postnoise_bilateral.jpg - Bilateral filter\n');
fprintf('  postnoise_contrast.jpg - Contrast enhancement only\n');

%% Step 11: Comprehensive comparison visualization
figure('Position', [50, 50, 1600, 1000]);

% Row 1: All versions comparison
subplot(3, 5, 1);
imshow(uint8(grayFrame));
title('Original', 'FontSize', 9, 'FontWeight', 'bold');

subplot(3, 5, 2);
imshow(version1);
title('Frequency Filter', 'FontSize', 9);

subplot(3, 5, 3);
imshow(version2);
title('Non-Local Means', 'FontSize', 9);

subplot(3, 5, 4);
imshow(version3);
title('Bilateral Filter', 'FontSize', 9);

subplot(3, 5, 5);
imshow(enhanced_final);
title('Final (Adaptive)', 'FontSize', 9, 'FontWeight', 'bold');

% Row 2: Frequency analysis
subplot(3, 5, 6);
imshow(magnitude_spectrum, []);
title('Original Spectrum', 'FontSize', 9);
colormap(gca, 'jet');

subplot(3, 5, 7);
imshow(H_final);
title(sprintf('Filter (D0=%d)', D0), 'FontSize', 9);

subplot(3, 5, 8);
magnitude_filtered = log(1 + abs(F_filtered));
imshow(magnitude_filtered, []);
title('Filtered Spectrum', 'FontSize', 9);
colormap(gca, 'jet');

subplot(3, 5, 9);
difference = abs(double(grayFrame) - double(enhanced_final));
imshow(difference, []);
title('Difference Map', 'FontSize', 9);
colormap(gca, 'hot');

subplot(3, 5, 10);
% Sharpness comparison
versions = {uint8(grayFrame), version1, version2, version3, enhanced_final};
version_names = {'Original', 'Freq', 'NLM', 'Bilateral', 'Final'};
sharpness_values = zeros(1, 5);

for i = 1:5
    [Gx, Gy] = gradient(double(versions{i}));
    sharpness_values(i) = mean(sqrt(Gx(:).^2 + Gy(:).^2));
end

bar(sharpness_values);
set(gca, 'XTickLabel', version_names, 'FontSize', 8);
ylabel('Sharpness');
title('Sharpness Comparison', 'FontSize', 9);
grid on;

% Row 3: Detail preservation
subplot(3, 5, 11);
imshow([uint8(grayFrame), enhanced_final]);
title('Side-by-Side', 'FontSize', 9);

subplot(3, 5, 12);
edge_original = edge(uint8(grayFrame), 'canny', 0.2);
edge_enhanced = edge(enhanced_final, 'canny', 0.2);
imshow([edge_original, edge_enhanced]);
title('Edge Maps', 'FontSize', 9);

subplot(3, 5, 13);
% Zoom into detail region
roi_size = 60;
cy = round(M/2);
cx = round(N/2);
roi_y = max(1,cy-roi_size):min(M,cy+roi_size);
roi_x = max(1,cx-roi_size):min(N,cx+roi_size);
imshow([uint8(grayFrame(roi_y,roi_x)), enhanced_final(roi_y,roi_x)]);
title('Detail Zoom', 'FontSize', 9);

subplot(3, 5, 14);
% Histogram comparison
histogram(grayFrame(:), 50, 'FaceColor', 'r', 'FaceAlpha', 0.5);
hold on;
histogram(enhanced_final(:), 50, 'FaceColor', 'b', 'FaceAlpha', 0.5);
legend('Original', 'Enhanced', 'FontSize', 7);
title('Intensity Distribution', 'FontSize', 9);

subplot(3, 5, 15);
% Quality metrics display
metrics_text = {
    sprintf('Mode: %s', upper(processing_mode)),
    sprintf('D0: %d', D0),
    sprintf('Strength: %.1f', filter_strength),
    '',
    sprintf('Noise Est: %.2f', noise_estimate),
    sprintf('Sharpness Retained: %.1f%%', ...
        100*sharpness_values(5)/sharpness_values(1))
};
text(0.1, 0.9, metrics_text, 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'FontSize', 8, 'FontName', 'FixedWidth');
axis off;
title('Processing Info', 'FontSize', 9);

saveas(gcf, 'minimal_processing_comparison.png');
fprintf('Saved comparison figure.\n');

%% Step 12: Calculate detailed metrics
fprintf('\n=== Quality Metrics ===\n');

original_uint8 = uint8(grayFrame);

% Compare all versions
fprintf('\nComparing all versions to original:\n');
fprintf('%-20s %8s %8s %8s %10s\n', 'Version', 'PSNR', 'SSIM', 'Sharpness', 'Retained');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:5
    curr_version = versions{i};
    psnr_val = psnr(curr_version, original_uint8);
    ssim_val = ssim(curr_version, original_uint8);
    sharp_val = sharpness_values(i);
    retain_pct = 100 * sharp_val / sharpness_values(1);
    
    fprintf('%-20s %8.2f %8.4f %8.2f %9.1f%%\n', ...
        version_names{i}, psnr_val, ssim_val, sharp_val, retain_pct);
end

%% Step 13: Recommendations
fprintf('\n=== RECOMMENDATIONS ===\n');

% Find best version based on sharpness retention
[max_sharp, best_idx] = max(sharpness_values(2:end));
best_versions = {'postnoise_freq_only.jpg', 'postnoise_nlm.jpg', ...
                 'postnoise_bilateral.jpg', 'postnoise.jpg'};

fprintf('\nBest version for detail preservation: %s\n', best_versions{best_idx});
fprintf('Sharpness retention: %.1f%%\n', 100*max_sharp/sharpness_values(1));

fprintf('\nRECOMMENDATION:\n');
if sharpness_values(5) / sharpness_values(1) > 0.9
    fprintf('  ✓ Good detail preservation! Use postnoise.jpg\n');
elseif best_idx == 2 && exist('imnlmfilt', 'file')
    fprintf('  → Try postnoise_nlm.jpg for better detail retention\n');
else
    fprintf('  → Your original image has good quality!\n');
    fprintf('  → Consider using postnoise_contrast.jpg for simple enhancement\n');
end

fprintf('\n=== NEXT STEPS ===\n');
fprintf('1. Compare prenoise.jpg with all postnoise_*.jpg versions\n');
fprintf('2. Choose the version that looks best visually\n');
fprintf('3. Upload prenoise.jpg and your chosen postnoise.jpg to BLIP2\n');
fprintf('4. Generate captions and compare\n');
fprintf('5. Update Analysis.txt\n');

fprintf('\n=== If Enhancement Seems Unnecessary ===\n');
fprintf('Your original image may already be good quality!\n');
fprintf('In Analysis.txt, you can note that:\n');
fprintf('  - Original had minimal noise\n');
fprintf('  - Aggressive filtering reduced quality\n');
fprintf('  - Light enhancement or no enhancement was optimal\n');
%}