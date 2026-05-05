---
title: ICT Project Concept
description: An AI interaction concept for ethnic clothing recognition, cultural introduction, and similar-item search
---

## Overview

This concept explores an AI-based ethnic clothing recognition system. A user uploads or captures a clothing image, and the system returns a recognition result, cultural introduction, and optional similar-item search results.

## Web Scenario

- The user uploads a clothing image.
- A vision model detects or classifies the clothing type and visual features.
- The page presents a generated cultural introduction.
- Future extensions may include 3D preview, masonry-style similar-image results, and external search links.

## Edge Device Scenario

- The user stands in front of a camera and presses a recognition button.
- The device captures an image and runs recognition.
- A speaker reads the result and cultural introduction.
- A QR code lets the user continue browsing details on a phone.

## Technical Route

- Vision model: YOLO or classification models for clothing detection and recognition.
- Dataset: image collection, annotation, cleaning, and train/validation split.
- Web interface: upload, recognition results, cultural text, and search entry.
- Edge device: Orange Pi, camera, buttons, fill light, speaker, and QR-code display.
- Cloud functions: search API, cultural text generation, and aggregated result pages.

## Risks

- Dataset quality and annotation cost may be high.
- Similar clothing and complex backgrounds may reduce recognition reliability.
- Edge devices require careful tradeoffs between speed, visual effects, and stability.
- Cultural descriptions should be accurate and traceable rather than fully free-generated.

## Next Steps

- Build a minimal demo with image upload, recognition, cultural introduction, and result display.
- Validate a small number of categories before scaling up.
- Design the web interaction and device-side workflow.
- Turn references, model choices, and hardware requirements into an execution checklist.
