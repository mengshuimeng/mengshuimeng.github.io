---
title: What Is DOF
description: A beginner-friendly explanation of degree of freedom in robotics and simulation code.
slug: what-is-dof
---

# What Is DOF

DOF means Degree of Freedom. In robotics, it refers to an independent direction or joint variable that can move.

## Simple Examples

- A single rotating joint has 1 DOF.
- A linear slider has 1 DOF.
- A 6-axis robotic arm usually has 6 DOF.

## Why DOF Matters In Code

Many robotics and simulation variables are shaped around the number of degrees of freedom:

- `dof_pos` for joint position
- `dof_vel` for joint velocity
- `num_dof` for the total joint count
- `torque_limits` for per-joint control limits

## Why It Matters In Learning And Control

- More DOF usually means a larger action space.
- More DOF often makes control and reinforcement learning harder.
- Observations, actions, and control gains are usually defined per DOF.

## A Good Mental Model

Treat each DOF as one independent joint variable the robot or simulator needs to track and control.
