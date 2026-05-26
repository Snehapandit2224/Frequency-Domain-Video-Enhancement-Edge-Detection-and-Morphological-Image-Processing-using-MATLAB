# Frequency Domain Video Enhancement and Image Processing using MATLAB

This repository contains implementations of advanced image and video processing techniques using MATLAB, including frequency-domain noise removal, image captioning analysis, edge detection, and morphological transformations.

---


# Assignment Overview

The project contains two major tasks:

1. Video Noise Removal and Captioning Analysis
2. Edge Detection and Morphological Transformations

---

# Question 1 — Video Noise Removal and Captioning Analysis

## Objective
Enhance noisy video frames using frequency-domain filtering and analyze the effect of enhancement on AI-generated image captions.

## Input
- Video File:
  - `12.mp4`

## Workflow
1. Extract frames from video
2. Select middle frame
3. Convert frame to frequency domain using FFT
4. Apply adaptive Butterworth low-pass filtering
5. Perform image enhancement and denoising
6. Save:
   - `prenoise.jpg`
   - `postnoise.jpg`
7. Generate captions using BLIP / BLIP2
8. Analyze semantic changes after enhancement

## Enhancement Techniques
- FFT-based frequency filtering
- Adaptive Butterworth Low-Pass Filter
- Wiener filtering
- Non-Local Means filtering
- Bilateral filtering
- Histogram Equalization

## Captioning Analysis
The project compares captions before and after enhancement to evaluate:
- Semantic preservation
- Noise reduction impact
- Detail retention
- Caption robustness

## Key Result
Frequency-domain filtering successfully reduced noise while preserving scene understanding with only minimal semantic drift.

---

# Question 2 — Edge Detection and Morphological Transformations

## Input
- Image File:
  - `00012.jpg`

## Part A — Edge Detection

### Methods Implemented
- Sobel
- Roberts
- Prewitt
- Laplacian of Gaussian (LoG)

### Output Files
- `edge_sobel.jpg`
- `edge_robert.jpg`
- `edge_prewitt.jpg`
- `edge_laplacian.jpg`

### Key Observation
Sobel edge detection best preserved meaningful edges while reducing sensitivity to low-light noise.

---

## Part B — Morphological Operations

### Operations Implemented
- Erosion
- Dilation
- Opening
- Closing

### Output Files
- `morph_erosion.jpg`
- `morph_dilation.jpg`
- `morph_opening.jpg`
- `morph_closing.jpg`

### Key Observation
Closing operation best preserved the original image structure while smoothing gaps and reducing distortion.

---

# Technologies Used

- MATLAB
- Image Processing Toolbox
- FFT (Fast Fourier Transform)
- Frequency-Domain Filtering
- Morphological Image Processing
- BLIP / BLIP2 Captioning Models

---

# Running the Project

## Run Question 1

```matlab
run('one.m')
```

## Run Question 2

```matlab
run('two.m')
```

---

# Concepts Covered

## Video Processing
- Frame extraction
- Frequency-domain enhancement
- Adaptive filtering
- Image quality analysis

## Edge Detection
- Gradient-based edge detection
- Laplacian edge operators
- Thresholding

## Morphology
- Structuring elements
- Shape preservation
- Noise reduction

## AI Vision
- Image captioning
- Semantic analysis
- Caption robustness evaluation

---

# Results Summary

| Task | Best Method |
|------|------|
| Noise Removal | Frequency-domain Butterworth Filtering |
| Edge Detection | Sobel Operator |
| Morphology | Closing Operation |

---

# Learning Outcomes

- Understanding FFT-based denoising
- Comparing edge detection techniques
- Applying morphology for image refinement
- Evaluating image enhancement using AI captioning
- Working with low-light and noisy imagery

---

# Academic Purpose

This repository was created for Digital Image Processing coursework and is intended for educational and research purposes only.
