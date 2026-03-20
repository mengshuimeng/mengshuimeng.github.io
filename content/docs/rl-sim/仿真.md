请你阅读这个文件夹中的四个.py文件，并详细告诉我这四个文件的作用。请再详细告诉我`legged_robot_config.py`中的参数都有什么作用。

```shell
PS D:\code\python\legged_gym\legged_gym\envs\base> dir

    目录: D:\code\python\legged_gym\legged_gym\envs\base

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         2025/9/16     23:09           2680 base_config.py
-a----         2025/9/16     23:09           6274 base_task.py
-a----         2025/9/16     23:09          49297 legged_robot.py
-a----         2025/9/16     23:09          10301 legged_robot_config.py
```

`base_config.py`

```python
# SPDX-FileCopyrightText: Copyright (c) 2021 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Copyright (c) 2021 ETH Zurich, Nikita Rudin

import inspect

class BaseConfig:
    def __init__(self) -> None:
        """ Initializes all member classes recursively. Ignores all namse starting with '__' (buit-in methods)."""
        self.init_member_classes(self)
    
    @staticmethod
    def init_member_classes(obj):
        # iterate over all attributes names
        for key in dir(obj):
            # disregard builtin attributes
            # if key.startswith("__"):
            if key=="__class__":
                continue
            # get the corresponding attribute object
            var =  getattr(obj, key)
            # check if it the attribute is a class
            if inspect.isclass(var):
                # instantate the class
                i_var = var()
                # set the attribute to the instance instead of the type
                setattr(obj, key, i_var)
                # recursively init members of the attribute
                BaseConfig.init_member_classes(i_var)
```

`base_task.py`

```python
# SPDX-FileCopyrightText: Copyright (c) 2021 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Copyright (c) 2021 ETH Zurich, Nikita Rudin

import sys
from isaacgym import gymapi
from isaacgym import gymutil
import numpy as np
import torch

# Base class for RL tasks
class BaseTask():

    def __init__(self, cfg, sim_params, physics_engine, sim_device, headless):
        self.gym = gymapi.acquire_gym()

        self.sim_params = sim_params
        self.physics_engine = physics_engine
        self.sim_device = sim_device
        sim_device_type, self.sim_device_id = gymutil.parse_device_str(self.sim_device)
        self.headless = headless

        # env device is GPU only if sim is on GPU and use_gpu_pipeline=True, otherwise returned tensors are copied to CPU by physX.
        if sim_device_type=='cuda' and sim_params.use_gpu_pipeline:
            self.device = self.sim_device
        else:
            self.device = 'cpu'

        # graphics device for rendering, -1 for no rendering
        self.graphics_device_id = self.sim_device_id
        if self.headless == True:
            self.graphics_device_id = -1

        self.num_envs = cfg.env.num_envs
        self.num_obs = cfg.env.num_observations
        self.num_privileged_obs = cfg.env.num_privileged_obs
        self.num_actions = cfg.env.num_actions

        # optimization flags for pytorch JIT
        torch._C._jit_set_profiling_mode(False)
        torch._C._jit_set_profiling_executor(False)

        # allocate buffers
        self.obs_buf = torch.zeros(self.num_envs, self.num_obs, device=self.device, dtype=torch.float)
        self.rew_buf = torch.zeros(self.num_envs, device=self.device, dtype=torch.float)
        self.reset_buf = torch.ones(self.num_envs, device=self.device, dtype=torch.long)
        self.episode_length_buf = torch.zeros(self.num_envs, device=self.device, dtype=torch.long)
        self.time_out_buf = torch.zeros(self.num_envs, device=self.device, dtype=torch.bool)
        if self.num_privileged_obs is not None:
            self.privileged_obs_buf = torch.zeros(self.num_envs, self.num_privileged_obs, device=self.device, dtype=torch.float)
        else: 
            self.privileged_obs_buf = None
            # self.num_privileged_obs = self.num_obs

        self.extras = {}

        # create envs, sim and viewer
        self.create_sim()
        self.gym.prepare_sim(self.sim)

        # todo: read from config
        self.enable_viewer_sync = True
        self.viewer = None

        # if running with a viewer, set up keyboard shortcuts and camera
        if self.headless == False:
            # subscribe to keyboard shortcuts
            self.viewer = self.gym.create_viewer(
                self.sim, gymapi.CameraProperties())
            self.gym.subscribe_viewer_keyboard_event(
                self.viewer, gymapi.KEY_ESCAPE, "QUIT")
            self.gym.subscribe_viewer_keyboard_event(
                self.viewer, gymapi.KEY_V, "toggle_viewer_sync")

    def get_observations(self):
        return self.obs_buf
    
    def get_privileged_observations(self):
        return self.privileged_obs_buf

    def reset_idx(self, env_ids):
        """Reset selected robots"""
        raise NotImplementedError

    def reset(self):
        """ Reset all robots"""
        self.reset_idx(torch.arange(self.num_envs, device=self.device))
        obs, privileged_obs, _, _, _ = self.step(torch.zeros(self.num_envs, self.num_actions, device=self.device, requires_grad=False))
        return obs, privileged_obs

    def step(self, actions):
        raise NotImplementedError

    def render(self, sync_frame_time=True):
        if self.viewer:
            # check for window closed
            if self.gym.query_viewer_has_closed(self.viewer):
                sys.exit()

            # check for keyboard events
            for evt in self.gym.query_viewer_action_events(self.viewer):
                if evt.action == "QUIT" and evt.value > 0:
                    sys.exit()
                elif evt.action == "toggle_viewer_sync" and evt.value > 0:
                    self.enable_viewer_sync = not self.enable_viewer_sync

            # fetch results
            if self.device != 'cpu':
                self.gym.fetch_results(self.sim, True)

            # step graphics
            if self.enable_viewer_sync:
                self.gym.step_graphics(self.sim)
                self.gym.draw_viewer(self.viewer, self.sim, True)
                if sync_frame_time:
                    self.gym.sync_frame_time(self.sim)
            else:
                self.gym.poll_viewer_events(self.viewer)
```

`legged_robot.py`

```python
# SPDX-FileCopyrightText: Copyright (c) 2021 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Copyright (c) 2021 ETH Zurich, Nikita Rudin

from legged_gym import LEGGED_GYM_ROOT_DIR, envs
from time import time
from warnings import WarningMessage
import numpy as np
import os

from isaacgym.torch_utils import *
from isaacgym import gymtorch, gymapi, gymutil

import torch
from torch import Tensor
from typing import Tuple, Dict

from legged_gym import LEGGED_GYM_ROOT_DIR
from legged_gym.envs.base.base_task import BaseTask
from legged_gym.utils.terrain import Terrain
from legged_gym.utils.math import quat_apply_yaw, wrap_to_pi, torch_rand_sqrt_float
from legged_gym.utils.helpers import class_to_dict
from .legged_robot_config import LeggedRobotCfg

class LeggedRobot(BaseTask):
    def __init__(self, cfg: LeggedRobotCfg, sim_params, physics_engine, sim_device, headless):
        """ Parses the provided config file,
            calls create_sim() (which creates, simulation, terrain and environments),
            initilizes pytorch buffers used during training

        Args:
            cfg (Dict): Environment config file
            sim_params (gymapi.SimParams): simulation parameters
            physics_engine (gymapi.SimType): gymapi.SIM_PHYSX (must be PhysX)
            device_type (string): 'cuda' or 'cpu'
            device_id (int): 0, 1, ...
            headless (bool): Run without rendering if True
        """
        self.cfg = cfg
        self.sim_params = sim_params
        self.height_samples = None
        self.debug_viz = False
        self.init_done = False
        self._parse_cfg(self.cfg)
        super().__init__(self.cfg, sim_params, physics_engine, sim_device, headless)

        if not self.headless:
            self.set_camera(self.cfg.viewer.pos, self.cfg.viewer.lookat)
        self._init_buffers()
        self._prepare_reward_function()
        self.init_done = True

    def step(self, actions):
        """ Apply actions, simulate, call self.post_physics_step()

        Args:
            actions (torch.Tensor): Tensor of shape (num_envs, num_actions_per_env)
        """
        clip_actions = self.cfg.normalization.clip_actions
        self.actions = torch.clip(actions, -clip_actions, clip_actions).to(self.device)
        # step physics and render each frame
        self.render()
        for _ in range(self.cfg.control.decimation):
            self.torques = self._compute_torques(self.actions).view(self.torques.shape)
            self.gym.set_dof_actuation_force_tensor(self.sim, gymtorch.unwrap_tensor(self.torques))
            self.gym.simulate(self.sim)
            if self.device == 'cpu':
                self.gym.fetch_results(self.sim, True)
            self.gym.refresh_dof_state_tensor(self.sim)
        self.post_physics_step()

        # return clipped obs, clipped states (None), rewards, dones and infos
        clip_obs = self.cfg.normalization.clip_observations
        self.obs_buf = torch.clip(self.obs_buf, -clip_obs, clip_obs)
        if self.privileged_obs_buf is not None:
            self.privileged_obs_buf = torch.clip(self.privileged_obs_buf, -clip_obs, clip_obs)
        return self.obs_buf, self.privileged_obs_buf, self.rew_buf, self.reset_buf, self.extras

    def post_physics_step(self):
        """ check terminations, compute observations and rewards
            calls self._post_physics_step_callback() for common computations 
            calls self._draw_debug_vis() if needed
        """
        self.gym.refresh_actor_root_state_tensor(self.sim)
        self.gym.refresh_net_contact_force_tensor(self.sim)

        self.episode_length_buf += 1
        self.common_step_counter += 1

        # prepare quantities
        self.base_quat[:] = self.root_states[:, 3:7]
        self.base_lin_vel[:] = quat_rotate_inverse(self.base_quat, self.root_states[:, 7:10])
        self.base_ang_vel[:] = quat_rotate_inverse(self.base_quat, self.root_states[:, 10:13])
        self.projected_gravity[:] = quat_rotate_inverse(self.base_quat, self.gravity_vec)

        self._post_physics_step_callback()

        # compute observations, rewards, resets, ...
        self.check_termination()
        self.compute_reward()
        env_ids = self.reset_buf.nonzero(as_tuple=False).flatten()
        self.reset_idx(env_ids)
        self.compute_observations() # in some cases a simulation step might be required to refresh some obs (for example body positions)

        self.last_actions[:] = self.actions[:]
        self.last_dof_vel[:] = self.dof_vel[:]
        self.last_root_vel[:] = self.root_states[:, 7:13]

        if self.viewer and self.enable_viewer_sync and self.debug_viz:
            self._draw_debug_vis()

    def check_termination(self):
        """ Check if environments need to be reset
        """
        self.reset_buf = torch.any(torch.norm(self.contact_forces[:, self.termination_contact_indices, :], dim=-1) > 1., dim=1)
        self.time_out_buf = self.episode_length_buf > self.max_episode_length # no terminal reward for time-outs
        self.reset_buf |= self.time_out_buf

    def reset_idx(self, env_ids):
        """ Reset some environments.
            Calls self._reset_dofs(env_ids), self._reset_root_states(env_ids), and self._resample_commands(env_ids)
            [Optional] calls self._update_terrain_curriculum(env_ids), self.update_command_curriculum(env_ids) and
            Logs episode info
            Resets some buffers

        Args:
            env_ids (list[int]): List of environment ids which must be reset
        """
        if len(env_ids) == 0:
            return
        # update curriculum
        if self.cfg.terrain.curriculum:
            self._update_terrain_curriculum(env_ids)
        # avoid updating command curriculum at each step since the maximum command is common to all envs
        if self.cfg.commands.curriculum and (self.common_step_counter % self.max_episode_length==0):
            self.update_command_curriculum(env_ids)
        
        # reset robot states
        self._reset_dofs(env_ids)
        self._reset_root_states(env_ids)

        self._resample_commands(env_ids)

        # reset buffers
        self.last_actions[env_ids] = 0.
        self.last_dof_vel[env_ids] = 0.
        self.feet_air_time[env_ids] = 0.
        self.episode_length_buf[env_ids] = 0
        self.reset_buf[env_ids] = 1
        # fill extras
        self.extras["episode"] = {}
        for key in self.episode_sums.keys():
            self.extras["episode"]['rew_' + key] = torch.mean(self.episode_sums[key][env_ids]) / self.max_episode_length_s
            self.episode_sums[key][env_ids] = 0.
        # log additional curriculum info
        if self.cfg.terrain.curriculum:
            self.extras["episode"]["terrain_level"] = torch.mean(self.terrain_levels.float())
        if self.cfg.commands.curriculum:
            self.extras["episode"]["max_command_x"] = self.command_ranges["lin_vel_x"][1]
        # send timeout info to the algorithm
        if self.cfg.env.send_timeouts:
            self.extras["time_outs"] = self.time_out_buf
    
    def compute_reward(self):
        """ Compute rewards
            Calls each reward function which had a non-zero scale (processed in self._prepare_reward_function())
            adds each terms to the episode sums and to the total reward
        """
        self.rew_buf[:] = 0.
        for i in range(len(self.reward_functions)):
            name = self.reward_names[i]
            rew = self.reward_functions[i]() * self.reward_scales[name]
            self.rew_buf += rew
            self.episode_sums[name] += rew
        if self.cfg.rewards.only_positive_rewards:
            self.rew_buf[:] = torch.clip(self.rew_buf[:], min=0.)
        # add termination reward after clipping
        if "termination" in self.reward_scales:
            rew = self._reward_termination() * self.reward_scales["termination"]
            self.rew_buf += rew
            self.episode_sums["termination"] += rew
    
    def compute_observations(self):
        """ Computes observations
        """
        self.obs_buf = torch.cat((  self.base_lin_vel * self.obs_scales.lin_vel,
                                    self.base_ang_vel  * self.obs_scales.ang_vel,
                                    self.projected_gravity,
                                    self.commands[:, :3] * self.commands_scale,
                                    (self.dof_pos - self.default_dof_pos) * self.obs_scales.dof_pos,
                                    self.dof_vel * self.obs_scales.dof_vel,
                                    self.actions
                                    ),dim=-1)
        # add perceptive inputs if not blind
        if self.cfg.terrain.measure_heights:
            heights = torch.clip(self.root_states[:, 2].unsqueeze(1) - 0.5 - self.measured_heights, -1, 1.) * self.obs_scales.height_measurements
            self.obs_buf = torch.cat((self.obs_buf, heights), dim=-1)
        # add noise if needed
        if self.add_noise:
            self.obs_buf += (2 * torch.rand_like(self.obs_buf) - 1) * self.noise_scale_vec

    def create_sim(self):
        """ Creates simulation, terrain and evironments
        """
        self.up_axis_idx = 2 # 2 for z, 1 for y -> adapt gravity accordingly
        self.sim = self.gym.create_sim(self.sim_device_id, self.graphics_device_id, self.physics_engine, self.sim_params)
        mesh_type = self.cfg.terrain.mesh_type
        if mesh_type in ['heightfield', 'trimesh']:
            self.terrain = Terrain(self.cfg.terrain, self.num_envs)
        if mesh_type=='plane':
            self._create_ground_plane()
        elif mesh_type=='heightfield':
            self._create_heightfield()
        elif mesh_type=='trimesh':
            self._create_trimesh()
        elif mesh_type is not None:
            raise ValueError("Terrain mesh type not recognised. Allowed types are [None, plane, heightfield, trimesh]")
        self._create_envs()

    def set_camera(self, position, lookat):
        """ Set camera position and direction
        """
        cam_pos = gymapi.Vec3(position[0], position[1], position[2])
        cam_target = gymapi.Vec3(lookat[0], lookat[1], lookat[2])
        self.gym.viewer_camera_look_at(self.viewer, None, cam_pos, cam_target)

    #------------- Callbacks --------------
    def _process_rigid_shape_props(self, props, env_id):
        """ Callback allowing to store/change/randomize the rigid shape properties of each environment.
            Called During environment creation.
            Base behavior: randomizes the friction of each environment

        Args:
            props (List[gymapi.RigidShapeProperties]): Properties of each shape of the asset
            env_id (int): Environment id

        Returns:
            [List[gymapi.RigidShapeProperties]]: Modified rigid shape properties
        """
        if self.cfg.domain_rand.randomize_friction:
            if env_id==0:
                # prepare friction randomization
                friction_range = self.cfg.domain_rand.friction_range
                num_buckets = 64
                bucket_ids = torch.randint(0, num_buckets, (self.num_envs, 1))
                friction_buckets = torch_rand_float(friction_range[0], friction_range[1], (num_buckets,1), device='cpu')
                self.friction_coeffs = friction_buckets[bucket_ids]

            for s in range(len(props)):
                props[s].friction = self.friction_coeffs[env_id]
        return props

    def _process_dof_props(self, props, env_id):
        """ Callback allowing to store/change/randomize the DOF properties of each environment.
            Called During environment creation.
            Base behavior: stores position, velocity and torques limits defined in the URDF

        Args:
            props (numpy.array): Properties of each DOF of the asset
            env_id (int): Environment id

        Returns:
            [numpy.array]: Modified DOF properties
        """
        if env_id==0:
            self.dof_pos_limits = torch.zeros(self.num_dof, 2, dtype=torch.float, device=self.device, requires_grad=False)
            self.dof_vel_limits = torch.zeros(self.num_dof, dtype=torch.float, device=self.device, requires_grad=False)
            self.torque_limits = torch.zeros(self.num_dof, dtype=torch.float, device=self.device, requires_grad=False)
            for i in range(len(props)):
                self.dof_pos_limits[i, 0] = props["lower"][i].item()
                self.dof_pos_limits[i, 1] = props["upper"][i].item()
                self.dof_vel_limits[i] = props["velocity"][i].item()
                self.torque_limits[i] = props["effort"][i].item()
                # soft limits
                m = (self.dof_pos_limits[i, 0] + self.dof_pos_limits[i, 1]) / 2
                r = self.dof_pos_limits[i, 1] - self.dof_pos_limits[i, 0]
                self.dof_pos_limits[i, 0] = m - 0.5 * r * self.cfg.rewards.soft_dof_pos_limit
                self.dof_pos_limits[i, 1] = m + 0.5 * r * self.cfg.rewards.soft_dof_pos_limit
        return props

    def _process_rigid_body_props(self, props, env_id):
        # if env_id==0:
        #     sum = 0
        #     for i, p in enumerate(props):
        #         sum += p.mass
        #         print(f"Mass of body {i}: {p.mass} (before randomization)")
        #     print(f"Total mass {sum} (before randomization)")
        # randomize base mass
        if self.cfg.domain_rand.randomize_base_mass:
            rng = self.cfg.domain_rand.added_mass_range
            props[0].mass += np.random.uniform(rng[0], rng[1])
        return props
    
    def _post_physics_step_callback(self):
        """ Callback called before computing terminations, rewards, and observations
            Default behaviour: Compute ang vel command based on target and heading, compute measured terrain heights and randomly push robots
        """
        # 
        env_ids = (self.episode_length_buf % int(self.cfg.commands.resampling_time / self.dt)==0).nonzero(as_tuple=False).flatten()
        self._resample_commands(env_ids)
        if self.cfg.commands.heading_command:
            forward = quat_apply(self.base_quat, self.forward_vec)
            heading = torch.atan2(forward[:, 1], forward[:, 0])
            self.commands[:, 2] = torch.clip(0.5*wrap_to_pi(self.commands[:, 3] - heading), -1., 1.)

        if self.cfg.terrain.measure_heights:
            self.measured_heights = self._get_heights()
        if self.cfg.domain_rand.push_robots and  (self.common_step_counter % self.cfg.domain_rand.push_interval == 0):
            self._push_robots()

    def _resample_commands(self, env_ids):
        """ Randommly select commands of some environments

        Args:
            env_ids (List[int]): Environments ids for which new commands are needed
        """
        self.commands[env_ids, 0] = torch_rand_float(self.command_ranges["lin_vel_x"][0], self.command_ranges["lin_vel_x"][1], (len(env_ids), 1), device=self.device).squeeze(1)
        self.commands[env_ids, 1] = torch_rand_float(self.command_ranges["lin_vel_y"][0], self.command_ranges["lin_vel_y"][1], (len(env_ids), 1), device=self.device).squeeze(1)
        if self.cfg.commands.heading_command:
            self.commands[env_ids, 3] = torch_rand_float(self.command_ranges["heading"][0], self.command_ranges["heading"][1], (len(env_ids), 1), device=self.device).squeeze(1)
        else:
            self.commands[env_ids, 2] = torch_rand_float(self.command_ranges["ang_vel_yaw"][0], self.command_ranges["ang_vel_yaw"][1], (len(env_ids), 1), device=self.device).squeeze(1)

        # set small commands to zero
        self.commands[env_ids, :2] *= (torch.norm(self.commands[env_ids, :2], dim=1) > 0.2).unsqueeze(1)

    def _compute_torques(self, actions):
        """ Compute torques from actions.
            Actions can be interpreted as position or velocity targets given to a PD controller, or directly as scaled torques.
            [NOTE]: torques must have the same dimension as the number of DOFs, even if some DOFs are not actuated.

        Args:
            actions (torch.Tensor): Actions

        Returns:
            [torch.Tensor]: Torques sent to the simulation
        """
        #pd controller
        actions_scaled = actions * self.cfg.control.action_scale
        control_type = self.cfg.control.control_type
        if control_type=="P":
            torques = self.p_gains*(actions_scaled + self.default_dof_pos - self.dof_pos) - self.d_gains*self.dof_vel
        elif control_type=="V":
            torques = self.p_gains*(actions_scaled - self.dof_vel) - self.d_gains*(self.dof_vel - self.last_dof_vel)/self.sim_params.dt
        elif control_type=="T":
            torques = actions_scaled
        else:
            raise NameError(f"Unknown controller type: {control_type}")
        return torch.clip(torques, -self.torque_limits, self.torque_limits)

    def _reset_dofs(self, env_ids):
        """ Resets DOF position and velocities of selected environmments
        Positions are randomly selected within 0.5:1.5 x default positions.
        Velocities are set to zero.

        Args:
            env_ids (List[int]): Environemnt ids
        """
        self.dof_pos[env_ids] = self.default_dof_pos * torch_rand_float(0.5, 1.5, (len(env_ids), self.num_dof), device=self.device)
        self.dof_vel[env_ids] = 0.

        env_ids_int32 = env_ids.to(dtype=torch.int32)
        self.gym.set_dof_state_tensor_indexed(self.sim,
                                              gymtorch.unwrap_tensor(self.dof_state),
                                              gymtorch.unwrap_tensor(env_ids_int32), len(env_ids_int32))
    def _reset_root_states(self, env_ids):
        """ Resets ROOT states position and velocities of selected environmments
            Sets base position based on the curriculum
            Selects randomized base velocities within -0.5:0.5 [m/s, rad/s]
        Args:
            env_ids (List[int]): Environemnt ids
        """
        # base position
        if self.custom_origins:
            self.root_states[env_ids] = self.base_init_state
            self.root_states[env_ids, :3] += self.env_origins[env_ids]
            self.root_states[env_ids, :2] += torch_rand_float(-1., 1., (len(env_ids), 2), device=self.device) # xy position within 1m of the center
        else:
            self.root_states[env_ids] = self.base_init_state
            self.root_states[env_ids, :3] += self.env_origins[env_ids]
        # base velocities
        self.root_states[env_ids, 7:13] = torch_rand_float(-0.5, 0.5, (len(env_ids), 6), device=self.device) # [7:10]: lin vel, [10:13]: ang vel
        env_ids_int32 = env_ids.to(dtype=torch.int32)
        self.gym.set_actor_root_state_tensor_indexed(self.sim,
                                                     gymtorch.unwrap_tensor(self.root_states),
                                                     gymtorch.unwrap_tensor(env_ids_int32), len(env_ids_int32))

    def _push_robots(self):
        """ Random pushes the robots. Emulates an impulse by setting a randomized base velocity. 
        """
        max_vel = self.cfg.domain_rand.max_push_vel_xy
        self.root_states[:, 7:9] = torch_rand_float(-max_vel, max_vel, (self.num_envs, 2), device=self.device) # lin vel x/y
        self.gym.set_actor_root_state_tensor(self.sim, gymtorch.unwrap_tensor(self.root_states))

    def _update_terrain_curriculum(self, env_ids):
        """ Implements the game-inspired curriculum.

        Args:
            env_ids (List[int]): ids of environments being reset
        """
        # Implement Terrain curriculum
        if not self.init_done:
            # don't change on initial reset
            return
        distance = torch.norm(self.root_states[env_ids, :2] - self.env_origins[env_ids, :2], dim=1)
        # robots that walked far enough progress to harder terains
        move_up = distance > self.terrain.env_length / 2
        # robots that walked less than half of their required distance go to simpler terrains
        move_down = (distance < torch.norm(self.commands[env_ids, :2], dim=1)*self.max_episode_length_s*0.5) * ~move_up
        self.terrain_levels[env_ids] += 1 * move_up - 1 * move_down
        # Robots that solve the last level are sent to a random one
        self.terrain_levels[env_ids] = torch.where(self.terrain_levels[env_ids]>=self.max_terrain_level,
                                                   torch.randint_like(self.terrain_levels[env_ids], self.max_terrain_level),
                                                   torch.clip(self.terrain_levels[env_ids], 0)) # (the minumum level is zero)
        self.env_origins[env_ids] = self.terrain_origins[self.terrain_levels[env_ids], self.terrain_types[env_ids]]
    
    def update_command_curriculum(self, env_ids):
        """ Implements a curriculum of increasing commands

        Args:
            env_ids (List[int]): ids of environments being reset
        """
        # If the tracking reward is above 80% of the maximum, increase the range of commands
        if torch.mean(self.episode_sums["tracking_lin_vel"][env_ids]) / self.max_episode_length > 0.8 * self.reward_scales["tracking_lin_vel"]:
            self.command_ranges["lin_vel_x"][0] = np.clip(self.command_ranges["lin_vel_x"][0] - 0.5, -self.cfg.commands.max_curriculum, 0.)
            self.command_ranges["lin_vel_x"][1] = np.clip(self.command_ranges["lin_vel_x"][1] + 0.5, 0., self.cfg.commands.max_curriculum)


    def _get_noise_scale_vec(self, cfg):
        """ Sets a vector used to scale the noise added to the observations.
            [NOTE]: Must be adapted when changing the observations structure

        Args:
            cfg (Dict): Environment config file

        Returns:
            [torch.Tensor]: Vector of scales used to multiply a uniform distribution in [-1, 1]
        """
        noise_vec = torch.zeros_like(self.obs_buf[0])
        self.add_noise = self.cfg.noise.add_noise
        noise_scales = self.cfg.noise.noise_scales
        noise_level = self.cfg.noise.noise_level
        noise_vec[:3] = noise_scales.lin_vel * noise_level * self.obs_scales.lin_vel
        noise_vec[3:6] = noise_scales.ang_vel * noise_level * self.obs_scales.ang_vel
        noise_vec[6:9] = noise_scales.gravity * noise_level
        noise_vec[9:12] = 0. # commands
        noise_vec[12:24] = noise_scales.dof_pos * noise_level * self.obs_scales.dof_pos
        noise_vec[24:36] = noise_scales.dof_vel * noise_level * self.obs_scales.dof_vel
        noise_vec[36:48] = 0. # previous actions
        if self.cfg.terrain.measure_heights:
            noise_vec[48:235] = noise_scales.height_measurements* noise_level * self.obs_scales.height_measurements
        return noise_vec

    #----------------------------------------
    def _init_buffers(self):
        """ Initialize torch tensors which will contain simulation states and processed quantities
        """
        # get gym GPU state tensors
        actor_root_state = self.gym.acquire_actor_root_state_tensor(self.sim)
        dof_state_tensor = self.gym.acquire_dof_state_tensor(self.sim)
        net_contact_forces = self.gym.acquire_net_contact_force_tensor(self.sim)
        self.gym.refresh_dof_state_tensor(self.sim)
        self.gym.refresh_actor_root_state_tensor(self.sim)
        self.gym.refresh_net_contact_force_tensor(self.sim)

        # create some wrapper tensors for different slices
        self.root_states = gymtorch.wrap_tensor(actor_root_state)
        self.dof_state = gymtorch.wrap_tensor(dof_state_tensor)
        self.dof_pos = self.dof_state.view(self.num_envs, self.num_dof, 2)[..., 0]
        self.dof_vel = self.dof_state.view(self.num_envs, self.num_dof, 2)[..., 1]
        self.base_quat = self.root_states[:, 3:7]

        self.contact_forces = gymtorch.wrap_tensor(net_contact_forces).view(self.num_envs, -1, 3) # shape: num_envs, num_bodies, xyz axis

        # initialize some data used later on
        self.common_step_counter = 0
        self.extras = {}
        self.noise_scale_vec = self._get_noise_scale_vec(self.cfg)
        self.gravity_vec = to_torch(get_axis_params(-1., self.up_axis_idx), device=self.device).repeat((self.num_envs, 1))
        self.forward_vec = to_torch([1., 0., 0.], device=self.device).repeat((self.num_envs, 1))
        self.torques = torch.zeros(self.num_envs, self.num_actions, dtype=torch.float, device=self.device, requires_grad=False)
        self.p_gains = torch.zeros(self.num_actions, dtype=torch.float, device=self.device, requires_grad=False)
        self.d_gains = torch.zeros(self.num_actions, dtype=torch.float, device=self.device, requires_grad=False)
        self.actions = torch.zeros(self.num_envs, self.num_actions, dtype=torch.float, device=self.device, requires_grad=False)
        self.last_actions = torch.zeros(self.num_envs, self.num_actions, dtype=torch.float, device=self.device, requires_grad=False)
        self.last_dof_vel = torch.zeros_like(self.dof_vel)
        self.last_root_vel = torch.zeros_like(self.root_states[:, 7:13])
        self.commands = torch.zeros(self.num_envs, self.cfg.commands.num_commands, dtype=torch.float, device=self.device, requires_grad=False) # x vel, y vel, yaw vel, heading
        self.commands_scale = torch.tensor([self.obs_scales.lin_vel, self.obs_scales.lin_vel, self.obs_scales.ang_vel], device=self.device, requires_grad=False,) # TODO change this
        self.feet_air_time = torch.zeros(self.num_envs, self.feet_indices.shape[0], dtype=torch.float, device=self.device, requires_grad=False)
        self.last_contacts = torch.zeros(self.num_envs, len(self.feet_indices), dtype=torch.bool, device=self.device, requires_grad=False)
        self.base_lin_vel = quat_rotate_inverse(self.base_quat, self.root_states[:, 7:10])
        self.base_ang_vel = quat_rotate_inverse(self.base_quat, self.root_states[:, 10:13])
        self.projected_gravity = quat_rotate_inverse(self.base_quat, self.gravity_vec)
        if self.cfg.terrain.measure_heights:
            self.height_points = self._init_height_points()
        self.measured_heights = 0

        # joint positions offsets and PD gains
        self.default_dof_pos = torch.zeros(self.num_dof, dtype=torch.float, device=self.device, requires_grad=False)
        for i in range(self.num_dofs):
            name = self.dof_names[i]
            angle = self.cfg.init_state.default_joint_angles[name]
            self.default_dof_pos[i] = angle
            found = False
            for dof_name in self.cfg.control.stiffness.keys():
                if dof_name in name:
                    self.p_gains[i] = self.cfg.control.stiffness[dof_name]
                    self.d_gains[i] = self.cfg.control.damping[dof_name]
                    found = True
            if not found:
                self.p_gains[i] = 0.
                self.d_gains[i] = 0.
                if self.cfg.control.control_type in ["P", "V"]:
                    print(f"PD gain of joint {name} were not defined, setting them to zero")
        self.default_dof_pos = self.default_dof_pos.unsqueeze(0)

    def _prepare_reward_function(self):
        """ Prepares a list of reward functions, whcih will be called to compute the total reward.
            Looks for self._reward_<REWARD_NAME>, where <REWARD_NAME> are names of all non zero reward scales in the cfg.
        """
        # remove zero scales + multiply non-zero ones by dt
        for key in list(self.reward_scales.keys()):
            scale = self.reward_scales[key]
            if scale==0:
                self.reward_scales.pop(key) 
            else:
                self.reward_scales[key] *= self.dt
        # prepare list of functions
        self.reward_functions = []
        self.reward_names = []
        for name, scale in self.reward_scales.items():
            if name=="termination":
                continue
            self.reward_names.append(name)
            name = '_reward_' + name
            self.reward_functions.append(getattr(self, name))

        # reward episode sums
        self.episode_sums = {name: torch.zeros(self.num_envs, dtype=torch.float, device=self.device, requires_grad=False)
                             for name in self.reward_scales.keys()}

    def _create_ground_plane(self):
        """ Adds a ground plane to the simulation, sets friction and restitution based on the cfg.
        """
        plane_params = gymapi.PlaneParams()
        plane_params.normal = gymapi.Vec3(0.0, 0.0, 1.0)
        plane_params.static_friction = self.cfg.terrain.static_friction
        plane_params.dynamic_friction = self.cfg.terrain.dynamic_friction
        plane_params.restitution = self.cfg.terrain.restitution
        self.gym.add_ground(self.sim, plane_params)
    
    def _create_heightfield(self):
        """ Adds a heightfield terrain to the simulation, sets parameters based on the cfg.
        """
        hf_params = gymapi.HeightFieldParams()
        hf_params.column_scale = self.terrain.cfg.horizontal_scale
        hf_params.row_scale = self.terrain.cfg.horizontal_scale
        hf_params.vertical_scale = self.terrain.cfg.vertical_scale
        hf_params.nbRows = self.terrain.tot_cols
        hf_params.nbColumns = self.terrain.tot_rows 
        hf_params.transform.p.x = -self.terrain.cfg.border_size 
        hf_params.transform.p.y = -self.terrain.cfg.border_size
        hf_params.transform.p.z = 0.0
        hf_params.static_friction = self.cfg.terrain.static_friction
        hf_params.dynamic_friction = self.cfg.terrain.dynamic_friction
        hf_params.restitution = self.cfg.terrain.restitution

        self.gym.add_heightfield(self.sim, self.terrain.heightsamples, hf_params)
        self.height_samples = torch.tensor(self.terrain.heightsamples).view(self.terrain.tot_rows, self.terrain.tot_cols).to(self.device)

    def _create_trimesh(self):
        """ Adds a triangle mesh terrain to the simulation, sets parameters based on the cfg.
        # """
        tm_params = gymapi.TriangleMeshParams()
        tm_params.nb_vertices = self.terrain.vertices.shape[0]
        tm_params.nb_triangles = self.terrain.triangles.shape[0]

        tm_params.transform.p.x = -self.terrain.cfg.border_size 
        tm_params.transform.p.y = -self.terrain.cfg.border_size
        tm_params.transform.p.z = 0.0
        tm_params.static_friction = self.cfg.terrain.static_friction
        tm_params.dynamic_friction = self.cfg.terrain.dynamic_friction
        tm_params.restitution = self.cfg.terrain.restitution
        self.gym.add_triangle_mesh(self.sim, self.terrain.vertices.flatten(order='C'), self.terrain.triangles.flatten(order='C'), tm_params)   
        self.height_samples = torch.tensor(self.terrain.heightsamples).view(self.terrain.tot_rows, self.terrain.tot_cols).to(self.device)

    def _create_envs(self):
        """ Creates environments:
             1. loads the robot URDF/MJCF asset,
             2. For each environment
                2.1 creates the environment, 
                2.2 calls DOF and Rigid shape properties callbacks,
                2.3 create actor with these properties and add them to the env
             3. Store indices of different bodies of the robot
        """
        asset_path = self.cfg.asset.file.format(LEGGED_GYM_ROOT_DIR=LEGGED_GYM_ROOT_DIR)
        asset_root = os.path.dirname(asset_path)
        asset_file = os.path.basename(asset_path)

        asset_options = gymapi.AssetOptions()
        asset_options.default_dof_drive_mode = self.cfg.asset.default_dof_drive_mode
        asset_options.collapse_fixed_joints = self.cfg.asset.collapse_fixed_joints
        asset_options.replace_cylinder_with_capsule = self.cfg.asset.replace_cylinder_with_capsule
        asset_options.flip_visual_attachments = self.cfg.asset.flip_visual_attachments
        asset_options.fix_base_link = self.cfg.asset.fix_base_link
        asset_options.density = self.cfg.asset.density
        asset_options.angular_damping = self.cfg.asset.angular_damping
        asset_options.linear_damping = self.cfg.asset.linear_damping
        asset_options.max_angular_velocity = self.cfg.asset.max_angular_velocity
        asset_options.max_linear_velocity = self.cfg.asset.max_linear_velocity
        asset_options.armature = self.cfg.asset.armature
        asset_options.thickness = self.cfg.asset.thickness
        asset_options.disable_gravity = self.cfg.asset.disable_gravity

        robot_asset = self.gym.load_asset(self.sim, asset_root, asset_file, asset_options)
        self.num_dof = self.gym.get_asset_dof_count(robot_asset)
        self.num_bodies = self.gym.get_asset_rigid_body_count(robot_asset)
        dof_props_asset = self.gym.get_asset_dof_properties(robot_asset)
        rigid_shape_props_asset = self.gym.get_asset_rigid_shape_properties(robot_asset)

        # save body names from the asset
        body_names = self.gym.get_asset_rigid_body_names(robot_asset)
        self.dof_names = self.gym.get_asset_dof_names(robot_asset)
        self.num_bodies = len(body_names)
        self.num_dofs = len(self.dof_names)
        feet_names = [s for s in body_names if self.cfg.asset.foot_name in s]
        penalized_contact_names = []
        for name in self.cfg.asset.penalize_contacts_on:
            penalized_contact_names.extend([s for s in body_names if name in s])
        termination_contact_names = []
        for name in self.cfg.asset.terminate_after_contacts_on:
            termination_contact_names.extend([s for s in body_names if name in s])

        base_init_state_list = self.cfg.init_state.pos + self.cfg.init_state.rot + self.cfg.init_state.lin_vel + self.cfg.init_state.ang_vel
        self.base_init_state = to_torch(base_init_state_list, device=self.device, requires_grad=False)
        start_pose = gymapi.Transform()
        start_pose.p = gymapi.Vec3(*self.base_init_state[:3])

        self._get_env_origins()
        env_lower = gymapi.Vec3(0., 0., 0.)
        env_upper = gymapi.Vec3(0., 0., 0.)
        self.actor_handles = []
        self.envs = []
        for i in range(self.num_envs):
            # create env instance
            env_handle = self.gym.create_env(self.sim, env_lower, env_upper, int(np.sqrt(self.num_envs)))
            pos = self.env_origins[i].clone()
            pos[:2] += torch_rand_float(-1., 1., (2,1), device=self.device).squeeze(1)
            start_pose.p = gymapi.Vec3(*pos)
                
            rigid_shape_props = self._process_rigid_shape_props(rigid_shape_props_asset, i)
            self.gym.set_asset_rigid_shape_properties(robot_asset, rigid_shape_props)
            actor_handle = self.gym.create_actor(env_handle, robot_asset, start_pose, self.cfg.asset.name, i, self.cfg.asset.self_collisions, 0)
            dof_props = self._process_dof_props(dof_props_asset, i)
            self.gym.set_actor_dof_properties(env_handle, actor_handle, dof_props)
            body_props = self.gym.get_actor_rigid_body_properties(env_handle, actor_handle)
            body_props = self._process_rigid_body_props(body_props, i)
            self.gym.set_actor_rigid_body_properties(env_handle, actor_handle, body_props, recomputeInertia=True)
            self.envs.append(env_handle)
            self.actor_handles.append(actor_handle)

        self.feet_indices = torch.zeros(len(feet_names), dtype=torch.long, device=self.device, requires_grad=False)
        for i in range(len(feet_names)):
            self.feet_indices[i] = self.gym.find_actor_rigid_body_handle(self.envs[0], self.actor_handles[0], feet_names[i])

        self.penalised_contact_indices = torch.zeros(len(penalized_contact_names), dtype=torch.long, device=self.device, requires_grad=False)
        for i in range(len(penalized_contact_names)):
            self.penalised_contact_indices[i] = self.gym.find_actor_rigid_body_handle(self.envs[0], self.actor_handles[0], penalized_contact_names[i])

        self.termination_contact_indices = torch.zeros(len(termination_contact_names), dtype=torch.long, device=self.device, requires_grad=False)
        for i in range(len(termination_contact_names)):
            self.termination_contact_indices[i] = self.gym.find_actor_rigid_body_handle(self.envs[0], self.actor_handles[0], termination_contact_names[i])

    def _get_env_origins(self):
        """ Sets environment origins. On rough terrain the origins are defined by the terrain platforms.
            Otherwise create a grid.
        """
        if self.cfg.terrain.mesh_type in ["heightfield", "trimesh"]:
            self.custom_origins = True
            self.env_origins = torch.zeros(self.num_envs, 3, device=self.device, requires_grad=False)
            # put robots at the origins defined by the terrain
            max_init_level = self.cfg.terrain.max_init_terrain_level
            if not self.cfg.terrain.curriculum: max_init_level = self.cfg.terrain.num_rows - 1
            self.terrain_levels = torch.randint(0, max_init_level+1, (self.num_envs,), device=self.device)
            self.terrain_types = torch.div(torch.arange(self.num_envs, device=self.device), (self.num_envs/self.cfg.terrain.num_cols), rounding_mode='floor').to(torch.long)
            self.max_terrain_level = self.cfg.terrain.num_rows
            self.terrain_origins = torch.from_numpy(self.terrain.env_origins).to(self.device).to(torch.float)
            self.env_origins[:] = self.terrain_origins[self.terrain_levels, self.terrain_types]
        else:
            self.custom_origins = False
            self.env_origins = torch.zeros(self.num_envs, 3, device=self.device, requires_grad=False)
            # create a grid of robots
            num_cols = np.floor(np.sqrt(self.num_envs))
            num_rows = np.ceil(self.num_envs / num_cols)
            xx, yy = torch.meshgrid(torch.arange(num_rows), torch.arange(num_cols))
            spacing = self.cfg.env.env_spacing
            self.env_origins[:, 0] = spacing * xx.flatten()[:self.num_envs]
            self.env_origins[:, 1] = spacing * yy.flatten()[:self.num_envs]
            self.env_origins[:, 2] = 0.

    def _parse_cfg(self, cfg):
        self.dt = self.cfg.control.decimation * self.sim_params.dt
        self.obs_scales = self.cfg.normalization.obs_scales
        self.reward_scales = class_to_dict(self.cfg.rewards.scales)
        self.command_ranges = class_to_dict(self.cfg.commands.ranges)
        if self.cfg.terrain.mesh_type not in ['heightfield', 'trimesh']:
            self.cfg.terrain.curriculum = False
        self.max_episode_length_s = self.cfg.env.episode_length_s
        self.max_episode_length = np.ceil(self.max_episode_length_s / self.dt)

        self.cfg.domain_rand.push_interval = np.ceil(self.cfg.domain_rand.push_interval_s / self.dt)

    def _draw_debug_vis(self):
        """ Draws visualizations for dubugging (slows down simulation a lot).
            Default behaviour: draws height measurement points
        """
        # draw height lines
        if not self.terrain.cfg.measure_heights:
            return
        self.gym.clear_lines(self.viewer)
        self.gym.refresh_rigid_body_state_tensor(self.sim)
        sphere_geom = gymutil.WireframeSphereGeometry(0.02, 4, 4, None, color=(1, 1, 0))
        for i in range(self.num_envs):
            base_pos = (self.root_states[i, :3]).cpu().numpy()
            heights = self.measured_heights[i].cpu().numpy()
            height_points = quat_apply_yaw(self.base_quat[i].repeat(heights.shape[0]), self.height_points[i]).cpu().numpy()
            for j in range(heights.shape[0]):
                x = height_points[j, 0] + base_pos[0]
                y = height_points[j, 1] + base_pos[1]
                z = heights[j]
                sphere_pose = gymapi.Transform(gymapi.Vec3(x, y, z), r=None)
                gymutil.draw_lines(sphere_geom, self.gym, self.viewer, self.envs[i], sphere_pose) 

    def _init_height_points(self):
        """ Returns points at which the height measurments are sampled (in base frame)

        Returns:
            [torch.Tensor]: Tensor of shape (num_envs, self.num_height_points, 3)
        """
        y = torch.tensor(self.cfg.terrain.measured_points_y, device=self.device, requires_grad=False)
        x = torch.tensor(self.cfg.terrain.measured_points_x, device=self.device, requires_grad=False)
        grid_x, grid_y = torch.meshgrid(x, y)

        self.num_height_points = grid_x.numel()
        points = torch.zeros(self.num_envs, self.num_height_points, 3, device=self.device, requires_grad=False)
        points[:, :, 0] = grid_x.flatten()
        points[:, :, 1] = grid_y.flatten()
        return points

    def _get_heights(self, env_ids=None):
        """ Samples heights of the terrain at required points around each robot.
            The points are offset by the base's position and rotated by the base's yaw

        Args:
            env_ids (List[int], optional): Subset of environments for which to return the heights. Defaults to None.

        Raises:
            NameError: [description]

        Returns:
            [type]: [description]
        """
        if self.cfg.terrain.mesh_type == 'plane':
            return torch.zeros(self.num_envs, self.num_height_points, device=self.device, requires_grad=False)
        elif self.cfg.terrain.mesh_type == 'none':
            raise NameError("Can't measure height with terrain mesh type 'none'")

        if env_ids:
            points = quat_apply_yaw(self.base_quat[env_ids].repeat(1, self.num_height_points), self.height_points[env_ids]) + (self.root_states[env_ids, :3]).unsqueeze(1)
        else:
            points = quat_apply_yaw(self.base_quat.repeat(1, self.num_height_points), self.height_points) + (self.root_states[:, :3]).unsqueeze(1)

        points += self.terrain.cfg.border_size
        points = (points/self.terrain.cfg.horizontal_scale).long()
        px = points[:, :, 0].view(-1)
        py = points[:, :, 1].view(-1)
        px = torch.clip(px, 0, self.height_samples.shape[0]-2)
        py = torch.clip(py, 0, self.height_samples.shape[1]-2)

        heights1 = self.height_samples[px, py]
        heights2 = self.height_samples[px+1, py]
        heights3 = self.height_samples[px, py+1]
        heights = torch.min(heights1, heights2)
        heights = torch.min(heights, heights3)

        return heights.view(self.num_envs, -1) * self.terrain.cfg.vertical_scale

    #------------ reward functions----------------
    def _reward_lin_vel_z(self):
        # Penalize z axis base linear velocity
        return torch.square(self.base_lin_vel[:, 2])
    
    def _reward_ang_vel_xy(self):
        # Penalize xy axes base angular velocity
        return torch.sum(torch.square(self.base_ang_vel[:, :2]), dim=1)
    
    def _reward_orientation(self):
        # Penalize non flat base orientation
        return torch.sum(torch.square(self.projected_gravity[:, :2]), dim=1)

    def _reward_base_height(self):
        # Penalize base height away from target
        base_height = torch.mean(self.root_states[:, 2].unsqueeze(1) - self.measured_heights, dim=1)
        return torch.square(base_height - self.cfg.rewards.base_height_target)
    
    def _reward_torques(self):
        # Penalize torques
        return torch.sum(torch.square(self.torques), dim=1)

    def _reward_dof_vel(self):
        # Penalize dof velocities
        return torch.sum(torch.square(self.dof_vel), dim=1)
    
    def _reward_dof_acc(self):
        # Penalize dof accelerations
        return torch.sum(torch.square((self.last_dof_vel - self.dof_vel) / self.dt), dim=1)
    
    def _reward_action_rate(self):
        # Penalize changes in actions
        return torch.sum(torch.square(self.last_actions - self.actions), dim=1)
    
    def _reward_collision(self):
        # Penalize collisions on selected bodies
        return torch.sum(1.*(torch.norm(self.contact_forces[:, self.penalised_contact_indices, :], dim=-1) > 0.1), dim=1)
    
    def _reward_termination(self):
        # Terminal reward / penalty
        return self.reset_buf * ~self.time_out_buf
    
    def _reward_dof_pos_limits(self):
        # Penalize dof positions too close to the limit
        out_of_limits = -(self.dof_pos - self.dof_pos_limits[:, 0]).clip(max=0.) # lower limit
        out_of_limits += (self.dof_pos - self.dof_pos_limits[:, 1]).clip(min=0.)
        return torch.sum(out_of_limits, dim=1)

    def _reward_dof_vel_limits(self):
        # Penalize dof velocities too close to the limit
        # clip to max error = 1 rad/s per joint to avoid huge penalties
        return torch.sum((torch.abs(self.dof_vel) - self.dof_vel_limits*self.cfg.rewards.soft_dof_vel_limit).clip(min=0., max=1.), dim=1)

    def _reward_torque_limits(self):
        # penalize torques too close to the limit
        return torch.sum((torch.abs(self.torques) - self.torque_limits*self.cfg.rewards.soft_torque_limit).clip(min=0.), dim=1)

    def _reward_tracking_lin_vel(self):
        # Tracking of linear velocity commands (xy axes)
        lin_vel_error = torch.sum(torch.square(self.commands[:, :2] - self.base_lin_vel[:, :2]), dim=1)
        return torch.exp(-lin_vel_error/self.cfg.rewards.tracking_sigma)
    
    def _reward_tracking_ang_vel(self):
        # Tracking of angular velocity commands (yaw) 
        ang_vel_error = torch.square(self.commands[:, 2] - self.base_ang_vel[:, 2])
        return torch.exp(-ang_vel_error/self.cfg.rewards.tracking_sigma)

    def _reward_feet_air_time(self):
        # Reward long steps
        # Need to filter the contacts because the contact reporting of PhysX is unreliable on meshes
        contact = self.contact_forces[:, self.feet_indices, 2] > 1.
        contact_filt = torch.logical_or(contact, self.last_contacts) 
        self.last_contacts = contact
        first_contact = (self.feet_air_time > 0.) * contact_filt
        self.feet_air_time += self.dt
        rew_airTime = torch.sum((self.feet_air_time - 0.5) * first_contact, dim=1) # reward only on first contact with the ground
        rew_airTime *= torch.norm(self.commands[:, :2], dim=1) > 0.1 #no reward for zero command
        self.feet_air_time *= ~contact_filt
        return rew_airTime
    
    def _reward_stumble(self):
        # Penalize feet hitting vertical surfaces
        return torch.any(torch.norm(self.contact_forces[:, self.feet_indices, :2], dim=2) >\
             5 *torch.abs(self.contact_forces[:, self.feet_indices, 2]), dim=1)
        
    def _reward_stand_still(self):
        # Penalize motion at zero commands
        return torch.sum(torch.abs(self.dof_pos - self.default_dof_pos), dim=1) * (torch.norm(self.commands[:, :2], dim=1) < 0.1)

    def _reward_feet_contact_forces(self):
        # penalize high contact forces
        return torch.sum((torch.norm(self.contact_forces[:, self.feet_indices, :], dim=-1) -  self.cfg.rewards.max_contact_force).clip(min=0.), dim=1)

```

`legged_robot_config.py`

```python
# SPDX-FileCopyrightText: Copyright (c) 2021 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Copyright (c) 2021 ETH Zurich, Nikita Rudin

from .base_config import BaseConfig

class LeggedRobotCfg(BaseConfig):
    class env:
        num_envs = 4096
        num_observations = 235
        num_privileged_obs = None # if not None a priviledge_obs_buf will be returned by step() (critic obs for assymetric training). None is returned otherwise 
        num_actions = 12
        env_spacing = 3.  # not used with heightfields/trimeshes 
        send_timeouts = True # send time out information to the algorithm
        episode_length_s = 20 # episode length in seconds

    class terrain:
        mesh_type = 'trimesh' # "heightfield" # none, plane, heightfield or trimesh
        horizontal_scale = 0.1 # [m]
        vertical_scale = 0.005 # [m]
        border_size = 25 # [m]
        curriculum = True
        static_friction = 1.0
        dynamic_friction = 1.0
        restitution = 0.
        # rough terrain only:
        measure_heights = True
        measured_points_x = [-0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0., 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8] # 1mx1.6m rectangle (without center line)
        measured_points_y = [-0.5, -0.4, -0.3, -0.2, -0.1, 0., 0.1, 0.2, 0.3, 0.4, 0.5]
        selected = False # select a unique terrain type and pass all arguments
        terrain_kwargs = None # Dict of arguments for selected terrain
        max_init_terrain_level = 5 # starting curriculum state
        terrain_length = 8.
        terrain_width = 8.
        num_rows= 10 # number of terrain rows (levels)
        num_cols = 20 # number of terrain cols (types)
        # terrain types: [smooth slope, rough slope, stairs up, stairs down, discrete]
        terrain_proportions = [0.1, 0.1, 0.35, 0.25, 0.2]
        # trimesh only:
        slope_treshold = 0.75 # slopes above this threshold will be corrected to vertical surfaces

    class commands:
        curriculum = False
        max_curriculum = 1.
        num_commands = 4 # default: lin_vel_x, lin_vel_y, ang_vel_yaw, heading (in heading mode ang_vel_yaw is recomputed from heading error)
        resampling_time = 10. # time before command are changed[s]
        heading_command = True # if true: compute ang vel command from heading error
        class ranges:
            lin_vel_x = [-1.0, 1.0] # min max [m/s]
            lin_vel_y = [-1.0, 1.0]   # min max [m/s]
            ang_vel_yaw = [-1, 1]    # min max [rad/s]
            heading = [-3.14, 3.14]

    class init_state:
        pos = [0.0, 0.0, 1.] # x,y,z [m]
        rot = [0.0, 0.0, 0.0, 1.0] # x,y,z,w [quat]
        lin_vel = [0.0, 0.0, 0.0]  # x,y,z [m/s]
        ang_vel = [0.0, 0.0, 0.0]  # x,y,z [rad/s]
        default_joint_angles = { # target angles when action = 0.0
            "joint_a": 0., 
            "joint_b": 0.}

    class control:
        control_type = 'P' # P: position, V: velocity, T: torques
        # PD Drive parameters:
        stiffness = {'joint_a': 10.0, 'joint_b': 15.}  # [N*m/rad]
        damping = {'joint_a': 1.0, 'joint_b': 1.5}     # [N*m*s/rad]
        # action scale: target angle = actionScale * action + defaultAngle
        action_scale = 0.5
        # decimation: Number of control action updates @ sim DT per policy DT
        decimation = 4

    class asset:
        file = ""
        name = "legged_robot"  # actor name
        foot_name = "None" # name of the feet bodies, used to index body state and contact force tensors
        penalize_contacts_on = []
        terminate_after_contacts_on = []
        disable_gravity = False
        collapse_fixed_joints = True # merge bodies connected by fixed joints. Specific fixed joints can be kept by adding " <... dont_collapse="true">
        fix_base_link = False # fixe the base of the robot
        default_dof_drive_mode = 3 # see GymDofDriveModeFlags (0 is none, 1 is pos tgt, 2 is vel tgt, 3 effort)
        self_collisions = 0 # 1 to disable, 0 to enable...bitwise filter
        replace_cylinder_with_capsule = True # replace collision cylinders with capsules, leads to faster/more stable simulation
        flip_visual_attachments = True # Some .obj meshes must be flipped from y-up to z-up
        
        density = 0.001
        angular_damping = 0.
        linear_damping = 0.
        max_angular_velocity = 1000.
        max_linear_velocity = 1000.
        armature = 0.
        thickness = 0.01

    class domain_rand:
        randomize_friction = True
        friction_range = [0.5, 1.25]
        randomize_base_mass = False
        added_mass_range = [-1., 1.]
        push_robots = True
        push_interval_s = 15
        max_push_vel_xy = 1.

    class rewards:
        class scales:
            termination = -0.0
            tracking_lin_vel = 1.0
            tracking_ang_vel = 0.5
            lin_vel_z = -2.0
            ang_vel_xy = -0.05
            orientation = -0.
            torques = -0.00001
            dof_vel = -0.
            dof_acc = -2.5e-7
            base_height = -0. 
            feet_air_time =  1.0
            collision = -1.
            feet_stumble = -0.0 
            action_rate = -0.01
            stand_still = -0.

        only_positive_rewards = True # if true negative total rewards are clipped at zero (avoids early termination problems)
        tracking_sigma = 0.25 # tracking reward = exp(-error^2/sigma)
        soft_dof_pos_limit = 1. # percentage of urdf limits, values above this limit are penalized
        soft_dof_vel_limit = 1.
        soft_torque_limit = 1.
        base_height_target = 1.
        max_contact_force = 100. # forces above this value are penalized

    class normalization:
        class obs_scales:
            lin_vel = 2.0
            ang_vel = 0.25
            dof_pos = 1.0
            dof_vel = 0.05
            height_measurements = 5.0
        clip_observations = 100.
        clip_actions = 100.

    class noise:
        add_noise = True
        noise_level = 1.0 # scales other values
        class noise_scales:
            dof_pos = 0.01
            dof_vel = 1.5
            lin_vel = 0.1
            ang_vel = 0.2
            gravity = 0.05
            height_measurements = 0.1

    # viewer camera:
    class viewer:
        ref_env = 0
        pos = [10, 0, 6]  # [m]
        lookat = [11., 5, 3.]  # [m]

    class sim:
        dt =  0.005
        substeps = 1
        gravity = [0., 0. ,-9.81]  # [m/s^2]
        up_axis = 1  # 0 is y, 1 is z

        class physx:
            num_threads = 10
            solver_type = 1  # 0: pgs, 1: tgs
            num_position_iterations = 4
            num_velocity_iterations = 0
            contact_offset = 0.01  # [m]
            rest_offset = 0.0   # [m]
            bounce_threshold_velocity = 0.5 #0.5 [m/s]
            max_depenetration_velocity = 1.0
            max_gpu_contact_pairs = 2**23 #2**24 -> needed for 8000 envs and more
            default_buffer_size_multiplier = 5
            contact_collection = 2 # 0: never, 1: last sub-step, 2: all sub-steps (default=2)

class LeggedRobotCfgPPO(BaseConfig):
    seed = 1
    runner_class_name = 'OnPolicyRunner'
    class policy:
        init_noise_std = 1.0
        actor_hidden_dims = [512, 256, 128]
        critic_hidden_dims = [512, 256, 128]
        activation = 'elu' # can be elu, relu, selu, crelu, lrelu, tanh, sigmoid
        # only for 'ActorCriticRecurrent':
        # rnn_type = 'lstm'
        # rnn_hidden_size = 512
        # rnn_num_layers = 1
        
    class algorithm:
        # training params
        value_loss_coef = 1.0
        use_clipped_value_loss = True
        clip_param = 0.2
        entropy_coef = 0.01
        num_learning_epochs = 5
        num_mini_batches = 4 # mini batch size = num_envs*nsteps / nminibatches
        learning_rate = 1.e-3 #5.e-4
        schedule = 'adaptive' # could be adaptive, fixed
        gamma = 0.99
        lam = 0.95
        desired_kl = 0.01
        max_grad_norm = 1.

    class runner:
        policy_class_name = 'ActorCritic'
        algorithm_class_name = 'PPO'
        num_steps_per_env = 24 # per iteration
        max_iterations = 1500 # number of policy updates

        # logging
        save_interval = 50 # check for potential saves every this many iterations
        experiment_name = 'test'
        run_name = ''
        # load and resume
        resume = False
        load_run = -1 # -1 = last run
        checkpoint = -1 # -1 = last saved model
        resume_path = None # updated from load_run and chkpt
```





# `legged_robot.py` 代码解析

## 整体思路

`LeggedRobot` 类是用于腿式机器人强化学习环境的核心实现，基于 NVIDIA Isaac Gym 框架。其主要功能包括：

1. **仿真环境管理**：创建和维护机器人、地形及物理仿真环境。
2. **动作执行与物理模拟**：将智能体输出的动作转换为关节扭矩，并驱动物理引擎进行仿真。
3. **观测与奖励计算**：根据机器人状态计算观测值和奖励函数。
4. **环境重置与课程学习**：支持动态调整地形难度和任务复杂度（curriculum learning）。
5. **域随机化（Domain Randomization）**：通过随机化摩擦力、质量等参数提高策略泛化能力。

代码结构遵循模块化设计，通过回调函数处理机器人属性配置，并利用 PyTorch 张量实现 GPU 加速的并行计算。

---

## 核心方法详解

### 初始化与环境创建

```python
def __init__(self, cfg: LeggedRobotCfg, sim_params, physics_engine, sim_device, headless):
```
- **功能**：初始化环境配置，创建物理仿真环境，加载机器人模型。
- **关键步骤**：
  1. 解析配置文件 (`_parse_cfg`)
  2. 调用父类 `BaseTask` 初始化
  3. 构建地形 (`create_sim`)
  4. 初始化缓冲区 (`_init_buffers`)
  5. 准备奖励函数 (`_prepare_reward_function`)

```python
def create_sim(self):
```
- **功能**：创建物理仿真环境和地形。
- **实现**：
  - 支持平面、高度场（heightfield）和三角网格（trimesh）地形
  - 调用 `_create_envs` 创建多个并行环境实例

---

### 核心控制循环

```python
def step(self, actions):
```
- **功能**：执行一步环境交互
- **流程**：
  1. 动作裁剪 (`torch.clip`)
  2. 执行 `decimation` 次物理模拟步（降低控制频率）
  3. 调用 `post_physics_step()` 处理后续计算
  4. 返回观测、奖励和终止标志

```python
def post_physics_step(self):
```
- **功能**：物理模拟后的处理
- **关键操作**：
  - 更新机器人状态（线速度、角速度、重力投影）
  - 调用 `_post_physics_step_callback`（命令重采样、地形高度测量）
  - 检查终止条件 (`check_termination`)
  - 计算奖励 (`compute_reward`)
  - 环境重置 (`reset_idx`)
  - 生成观测值 (`compute_observations`)

---

### 环境管理与重置

```python
def reset_idx(self, env_ids):
```
- **功能**：重置指定环境
- **关键逻辑**：
  - 地形课程更新 (`_update_terrain_curriculum`)
  - 命令范围课程更新 (`update_command_curriculum`)
  - 重置 DOF 状态 (`_reset_dofs`)
  - 重置根状态 (`_reset_root_states`)
  - 缓冲区清零

```python
def _reset_dofs(self, env_ids):
```
- **功能**：随机化关节位置（在默认值 ±50% 范围内）

```python
def _reset_root_states(self, env_ids):
```
- **功能**：重置机器人根部状态（位置、速度）

---

### 奖励函数系统

```python
def compute_reward(self):
```
- **功能**：聚合所有奖励项
- **机制**：
  - 遍历所有非零奖励项（如 `_reward_lin_vel_z`, `_reward_tracking_lin_vel`）
  - 应用缩放系数并累加
  - 支持仅保留正奖励（`only_positive_rewards`）

**典型奖励项示例**：
```python
def _reward_tracking_lin_vel(self):
    # 线速度跟踪奖励
    lin_vel_error = torch.sum(torch.square(self.commands[:, :2] - self.base_lin_vel[:, :2]), dim=1)
    return torch.exp(-lin_vel_error/self.cfg.rewards.tracking_sigma)
```

---

### 物理属性回调函数

```python
def _process_rigid_shape_props(self, props, env_id):
```
- **功能**：随机化摩擦系数（domain randomization）

```python
def _process_dof_props(self, props, env_id):
```
- **功能**：存储 DOF 限制（位置、速度、扭矩）

```python
def _process_rigid_body_props(self, props, env_id):
```
- **功能**：随机化机器人基础质量

---

### 地形与高度测量

```python
def _get_heights(self, env_ids=None):
```
- **功能**：获取机器人周围地形高度
- **实现**：
  - 基于 base 姿态变换采样点
  - 使用双线性插值计算高度
  - 支持多种地形类型（heightfield/trimesh）

```python
def _init_height_points(self):
```
- **功能**：初始化高度测量点（网格布局）

---

## 关键数据流

1. **动作 → 扭矩**  
   `actions` → `_compute_torques` (PD 控制器) → `gym.set_dof_actuation_force_tensor`

2. **观测生成**  
   `compute_observations` 组合以下信息：
   - 基础速度
   - 重力投影
   - 命令值
   - 关节状态
   - 地形高度（可选）

3. **奖励计算**  
   各奖励项通过独立函数实现，最终通过 `compute_reward` 聚合

---

## 课程学习（Curriculum Learning）

```python
def _update_terrain_curriculum(self, env_ids):
```
- **机制**：
  - 根据机器人移动距离动态调整地形难度
  - 达到阈值时升级/降级地形级别
  - 最终地形由 `terrain_levels` 和 `terrain_types` 控制

```python
def update_command_curriculum(self, env_ids):
```
- **机制**：
  - 根据线速度跟踪表现扩展命令范围
  - 提高最大前进速度阈值

---

## 域随机化（Domain Randomization）

- **摩擦系数**：每个环境独立随机化
- **基础质量**：在默认值基础上添加随机质量
- **初始状态扰动**：位置、速度的随机偏移
- **传感器噪声**：观测值添加随机噪声（`_get_noise_scale_vec`）

---

## 性能优化

- **Decimation**：降低控制频率（`control.decimation`），减少 GPU 负载
- **批量操作**：使用 PyTorch 张量批量处理多个环境
- **内存优化**：通过 `gymtorch.wrap_tensor` 直接操作 GPU 内存

---

## 调试与可视化

```python
def _draw_debug_vis(self):
```
- **功能**：绘制高度测量点（黄色小球）
- **条件**：仅在启用 `debug_viz` 时生效

---

该实现完整覆盖了腿式机器人强化学习环境的关键要素，通过模块化设计实现了灵活的配置和高效的并行计算。









---

对，你的理解很对 —— 这份 `LeggedRobot` 类的代码可以清晰地分成几个职责区块（或者“模块”/“区域”），每一块负责不同的工作。下面我按“区域”把所有重要函数/方法按职责分类并逐一说明它们的作用、输入、处理和输出，以及相互关系与注意点。为了方便阅读我会先给出总体分区列表，再对每个区块内的方法逐个解释（中文、务实、直白）。

# 总体分区（高层）

1. **初始化 / 主流程相关**：`__init__`, `step`, `post_physics_step`，负责生命周期和主循环。
2. **仿真创建与环境管理**：`create_sim`, `_create_envs`, `_create_ground_plane`, `_create_heightfield`, `_create_trimesh`, `_get_env_origins`。
3. **状态/缓冲区初始化**：`_init_buffers`, `_init_height_points`。
4. **回调 / 属性处理**（在创建环境时被调用）：`_process_rigid_shape_props`, `_process_dof_props`, `_process_rigid_body_props`。
5. **控制器（从 action 到 torques）**：`_compute_torques`。
6. **重置与扰动**：`reset_idx`, `_reset_dofs`, `_reset_root_states`, `_push_robots`。
7. **命令/课程（curriculum）管理**：`_resample_commands`, `_post_physics_step_callback`, `_update_terrain_curriculum`, `update_command_curriculum`。
8. **观测与噪声**：`compute_observations`, `_get_noise_scale_vec`。
9. **高度测量相关**：`_init_height_points`, `_get_heights`, `_draw_debug_vis`。
10. **奖励体系**：`_prepare_reward_function`（构造器），以及一堆 `_reward_*` 函数（实际的奖励项）。
11. **配置解析 / 工具**：`_parse_cfg` 等小工具函数。

下面我按上面的分区逐一详细说明每个方法（含输入、处理、输出、注意点）。

------

# 1. 初始化 / 主流程相关

### `__init__(self, cfg, sim_params, physics_engine, sim_device, headless)`

- **作用**：构造函数，解析配置，调用父类创建仿真环境（通过 `super()`），设置摄像头，初始化缓冲区与奖励函数表。
- **输入**：`cfg`（配置对象 `LeggedRobotCfg`）、`sim_params`（gym 的 SimParams）、`physics_engine`（物理后端）、`sim_device`、`headless`（是否无头）。
- **处理**：
  - 保存 cfg、sim_params 等；
  - `_parse_cfg(cfg)` 解析一些派生变量（如 `dt`, `max_episode_length`）；
  - 调用 `super().__init__`（父类 `BaseTask` 会负责 `create_sim()` 的调用与 viewer 等）；
  - 若非 headless，设置相机；
  - `_init_buffers()`：初始化所有 torch 缓冲区（非常关键）；
  - `_prepare_reward_function()`：准备 reward 函数列表和缩放；
  - 标记 `init_done = True`。
- **输出**：无（对象初始化完毕）。
- **注意**：很多后续方法依赖 `_init_buffers()` 中的张量已存在（例如 `self.dof_pos`, `self.root_states`），因此初始化顺序很关键。

### `step(self, actions)`

- **作用**：主执行步骤 —— 接收动作、执行控制、推进物理、多步子步（decimation），然后返回观测/奖励/重置信息给训练算法。
- **输入**：`actions`，形状通常 `(num_envs, num_actions)` 的 torch.Tensor。
- **处理**：
  - 对 actions 做剪切（`clip_actions`）并移到正确设备；
  - `render()`（如果开启渲染）；
  - 循环 `decimation` 次：计算 torques（`_compute_torques`），把 torques 写入 gym 的 DOF actuation，调用 `gym.simulate()`，取回状态（CPU 模式时需要 `fetch_results`），刷新 DOF 状态张量；
  - 调用 `post_physics_step()`（处理观测、奖励、重置等）；
  - 对输出 obs 做裁剪，返回 `(obs_buf, privileged_obs_buf, rew_buf, reset_buf, extras)`。
- **输出**：五元组（obs、privileged obs 或 None、reward、done/reset 布尔、额外信息 `extras`）。
- **注意**：`decimation` 控制动作的更新频率 vs. 仿真步长的比例；`step` 是训练循环调用的入口。

### `post_physics_step(self)`

- **作用**：物理推进后统一的后处理 —— 刷新根状态/接触力、更新各种速度/姿态量、调用回调、检查终止、计算奖励、重置、计算观测等。
- **输入**：无（使用内部张量）。
- **处理**：
  - `gym.refresh_actor_root_state_tensor`, `gym.refresh_net_contact_force_tensor`；
  - 更新内部计数器（`episode_length_buf`, `common_step_counter`）；
  - 计算 `base_quat`, `base_lin_vel`, `base_ang_vel`, `projected_gravity`（把全局速度换算到 base frame）；
  - `_post_physics_step_callback()` 调用（定期采样命令、测高度、随机推等）；
  - `check_termination()`、`compute_reward()`；
  - 找到需要重置的 env（`reset_buf.nonzero()`），调用 `reset_idx(env_ids)`；
  - `compute_observations()`；
  - 记录 `last_actions`, `last_dof_vel`, `last_root_vel`；
  - 可选 debug 可视化 `_draw_debug_vis()`。
- **输出**：无（内部状态更新并准备好输出）。

------

# 2. 仿真创建与环境管理

### `create_sim(self)`

- **作用**：实际创建 gym/IsaacGym 的 `sim`，并创建地形与环境。
- **输入**：无（使用 `self.sim_params`, `self.cfg`）。
- **处理**：
  - 设置 `up_axis_idx`（这里用 z=2）；
  - `gym.create_sim(...)` 创建仿真对象；
  - 根据 `cfg.terrain.mesh_type` 选择构建地形 (`Terrain`、plane、heightfield、trimesh)；
  - 调用 `_create_envs()` 在场景里实例化每个 robot 环境。
- **输出**：无（创建 `self.sim`, `self.terrain`, `self.envs` 等）。

### `_create_envs(self)`

- **作用**：加载 robot asset（URDF/MJCF），并对每个 env 创建 actor，设置 DOF/刚体属性，记录 body/dof 索引。
- **输入**：无（使用 `self.cfg.asset`、`self.env_origins` 等）。
- **处理**：
  - 组合 asset_path，设置 `gymapi.AssetOptions`（来自 cfg.asset）；
  - `gym.load_asset(...)` 得到 `robot_asset`，并读取 DOF/刚体数量与属性；
  - 识别 body 名称、dof 名称，找出 feet、penalized contact、termination contact 的名字集合；
  - 将 `base_init_state` 变为 torch 张量；
  - 调用 `_get_env_origins()` 得到每个 env 的起点；
  - 循环 `num_envs`：`gym.create_env` -> `self._process_rigid_shape_props` -> `gym.set_asset_rigid_shape_properties` -> `gym.create_actor` -> `_process_dof_props` -> `gym.set_actor_dof_properties` -> `_process_rigid_body_props` -> `gym.set_actor_rigid_body_properties`；
  - 记录 `feet_indices`, `penalised_contact_indices`, `termination_contact_indices`（用于接触检测与奖励/终止判定）。
- **输出**：无（内部数据结构填充完毕）。

### `_create_ground_plane`, `_create_heightfield`, `_create_trimesh`

- **作用**：根据 cfg 创建不同类型地面（平面/高度图/三角网格），并把材质摩擦/弹性参数写入。
- **输入**：`self.terrain`（对于 heightfield/trimesh）和 `cfg.terrain`。
- **处理**：
  - 创建相应的 gym 参数对象，设置 scale, nbRows/nbColumns, transform, friction/restitution 等；
  - 调用 `gym.add_ground` / `gym.add_heightfield` / `gym.add_triangle_mesh`；
  - 对 heightfield/trimesh 保存 `self.height_samples` 为张量以便后续查询。
- **输出**：无。

### `_get_env_origins(self)`

- **作用**：确定每个 env 的初始位置（在粗糙地形时来自 terrain 平台，否则生成网格排列），并初始化 `terrain_levels`、`terrain_types`。
- **输入**：`cfg.terrain` 与 `num_envs` 等。
- **处理**：
  - 如果是 heightfield/trimesh：从 `self.terrain.env_origins` 中读取平台 origin，并随机化初始 terrain level；
  - 否则创建按 `env_spacing` 的网格排列位置。
- **输出**：无（写 `self.env_origins` 等）。

------

# 3. 状态/缓冲区初始化

### `_init_buffers(self)`

- **作用**：把 gym 的状态张量包装成 torch 张量，并创建所有训练/计算需要的中间缓存（obs_buf、rew_buf、各种速度、动作历史、PD gains 等）。非常关键。
- **输入**：需要 `self.sim` 已创建（即在 `create_sim()` 之后或由父类在合适时机调用）。
- **处理**：
  - `gym.acquire_actor_root_state_tensor`, `gym.acquire_dof_state_tensor`, `gym.acquire_net_contact_force_tensor`，并 `wrap_tensor` 成 torch 张量（`self.root_states`, `self.dof_state`, `self.contact_forces`）；
  - 从 `dof_state` 切片得到 `dof_pos`, `dof_vel`；从 `root_states` 切片得到 `base_quat` 等；
  - 初始化 `self.torques`, `self.p_gains`, `self.d_gains`, `self.actions`, `self.last_actions` 等；
  - 通过 `cfg.init_state.default_joint_angles` 设置 `self.default_dof_pos`；根据 `cfg.control.stiffness/damping` 填 `p_gains/d_gains`（按 dof 名称匹配）。
- **输出**：无（初始化一堆关键张量）。
- **注意**：
  - 这里把很多东西放在 GPU（或 CPU），确保 device 一致；
  - `self.dof_names`、`self.num_dofs` 等必须先被填好（由 `_create_envs`）。

### `_init_height_points(self)`

- **作用**：根据 cfg 中提供的 `measured_points_x` / `measured_points_y` 在 base frame 生成一批测高点坐标，返回 `(num_envs, n_points, 3)` 的张量（x,y,z，其中 z 暂为 0）。
- **输入**：`cfg.terrain.measured_points_x/y`、`num_envs`。
- **处理**：网格化 x,y，flatten 后填充到每个 env 的 points（x,y列），z 默认 0。
- **输出**：`self.height_points`，并记录 `self.num_height_points`。

------

# 4. 回调 / 属性处理（环境创建阶段会调用）

### `_process_rigid_shape_props(self, props, env_id)`

- **作用**：可用于随机化每个 env 中每个 shape 的摩擦等刚体形状参数。默认实现：若 `cfg.domain_rand.randomize_friction`，为每个 env 选一个摩擦系数并写入 `props[s].friction`。
- **输入**：`props`（asset 的 rigid shape properties 列表/数组），`env_id`。
- **处理**：
  - 当 `env_id == 0` 时会为整个批次构造 friction_buckets 与 bucket_ids；
  - 用 `self.friction_coeffs[env_id]` 给每个 shape 的 friction 赋值。
- **输出**：返回修改后的 `props`（供 `gym.set_asset_rigid_shape_properties` 使用）。
- **扩展点**：用户可以覆写或在子类中修改来随机化 restitution、摩擦各向异性等。

### `_process_dof_props(self, props, env_id)`

- **作用**：在创建 actor 时对 DOF 属性做进一步处理或记录（例如读取 URDF 给出的 pos/vel/torque limits 并写入到 `self.dof_pos_limits`、`self.dof_vel_limits`、`self.torque_limits`）。
- **输入**：`props`（每个 DOF 的属性结构），`env_id`。
- **处理**：
  - 仅在 `env_id==0` 时填充 `dof_pos_limits`, `dof_vel_limits`, `torque_limits`；同时基于 cfg.rewards.soft_dof_pos_limit 调整软限制区间。
- **输出**：返回可能修改过的 `props`（继续被写回到 actor）。

### `_process_rigid_body_props(self, props, env_id)`

- **作用**：对 asset 刚体属性（质量等）进行随机化，比如随机增加 base mass（`cfg.domain_rand.randomize_base_mass`）。
- **输入**：`props`（刚体属性列表），`env_id`。
- **处理**：如果允许随机化，在 `props[0].mass` 上加一个随机量。
- **输出**：返回修改后的 `props`。

------

# 5. 控制器（action -> torques）

### `_compute_torques(self, actions)`

- **作用**：将网络输出的 actions 转换为实际发送给 simu 的扭矩（torques）。支持三类 control type：P（位置 PD）、V（速度 PD）、T（直接扭矩）。
- **输入**：`actions`（`(num_envs, num_actions)`，通常 -1..1，随后乘以 `cfg.control.action_scale`）。
- **处理**：
  - `actions_scaled = actions * action_scale`；
  - 若 `control_type=="P"`：`torques = p_gains * (actions_scaled + default_dof_pos - dof_pos) - d_gains * dof_vel`（目标角度 = actions_scaled + default）；
  - 若 `"V"`：`torques = p_gains*(actions_scaled - dof_vel) - d_gains*(dof_vel - last_dof_vel)/sim_dt`（目标速度）；
  - 若 `"T"`：`torques = actions_scaled`（直接把 scaled action 当作扭矩）；
  - 最后 clip 到 `[-torque_limits, torque_limits]`。
- **输出**：`torques` 张量，shape 与 `num_actions` 对应。
- **注意**：`p_gains/d_gains` 是每个 DOF 的比例/微分增益；PD 控制用法和单位必须与 URDF 的关节定义匹配。

------

# 6. 重置与扰动

### `reset_idx(self, env_ids)`

- **作用**：对一组需要 reset 的 env 执行重置步骤（环境课程更新、命令重采样、DOF/ROOT 状态重置、缓冲清零、统计上报）。
- **输入**：`env_ids`（tensor或长列表，含要重置的 env id）。
- **处理**：
  - 可选地调用 `_update_terrain_curriculum(env_ids)` 与 `update_command_curriculum(env_ids)`；
  - 调用 `_reset_dofs(env_ids)`, `_reset_root_states(env_ids)`，`_resample_commands(env_ids)`；
  - 清零 `last_actions`, `last_dof_vel`, `feet_air_time` 等，并设置 `episode_length_buf[env_ids]=0`、`reset_buf[env_ids]=1`；
  - 填写 `extras["episode"]`：每个 reward 的平均值与课程信息（terrain_level、max_command_x）；
  - 如果 cfg.env.send_timeouts 则 `extras["time_outs"] = self.time_out_buf`。
- **输出**：无（状态被重置）。

### `_reset_dofs(self, env_ids)`

- **作用**：将指定 env 的各关节位置设为 `default_dof_pos` 的随机比例（0.5~1.5倍），速度清零，并把其 DOF 状态写回仿真。
- **输入**：`env_ids`。
- **处理**：通过 `torch_rand_float` 生成随机系数，写 `self.dof_pos[env_ids]` 和 `self.dof_vel[env_ids]`，再调用 `gym.set_dof_state_tensor_indexed`。
- **输出**：无。

### `_reset_root_states(self, env_ids)`

- **作用**：重置根（base）位姿与速度。
- **输入**：`env_ids`。
- **处理**：
  - 若 `custom_origins`（rough terrain），则把 `root_states[env_ids] = base_init_state` 并加上 terrain origin（并在 xy 上小幅随机偏移）；否则只加 env_origins；
  - `root_states[env_ids, 7:13]`（线速度与角速度）被随机化在 [-0.5,0.5]；
  - 写回仿真 `gym.set_actor_root_state_tensor_indexed`。
- **输出**：无。

### `_push_robots(self)`

- **作用**：模拟突的外力：通过一次性设置 base 的线速度来“推”机器人（作为域随机的一部分），在训练中强化鲁棒性。
- **输入**：无（使用 cfg.domain_rand.max_push_vel_xy）。
- **处理**：`root_states[:, 7:9] = rand(-max_vel, max_vel)`，写回 root states。
- **输出**：无。

------

# 7. 命令 / 课程（Curriculum）管理

### `_resample_commands(self, env_ids)`

- **作用**：为指定 env 重新采样控制命令（线速度 x/y、角速度或 heading），作为训练任务的输入命令。
- **输入**：`env_ids`。
- **处理**：
  - 用 `torch_rand_float` 在 `command_ranges` 范围内采样 `lin_vel_x`, `lin_vel_y`；
  - 如果 `heading_command` 为真，采样 `heading` 到 `commands[:,3]`；否则采样 `ang_vel_yaw` 到 `commands[:,2]`；
  - 把小幅命令（norm < 0.2）设为 0（避免无意义的小动作）。
- **输出**：无（修改 `self.commands`）。

### `_post_physics_step_callback(self)`

- **作用**：物理步之后的额外处理（在 `post_physics_step` 中被调用）：定期重采样命令、如果使用 heading 模式则把 heading 转换为 yaw 角速度命令、测高度、周期性推机器人。
- **输入**：无（使用内部计时器与 cfg）。
- **处理**：
  - 计算满足 `resampling_time` 的 env_ids 并调用 `_resample_commands`；
  - 若 `heading_command`，依据 base 方向和 heading 计算 yaw 速度命令 `commands[:,2]`；
  - 若 `measure_heights`，调用 `_get_heights()` 更新 `measured_heights`；
  - 若开启 `push_robots` 并到达 `push_interval`，调用 `_push_robots()`。
- **输出**：无（更新 commands / heights / 推动）。

### `_update_terrain_curriculum(self, env_ids)` 与 `update_command_curriculum(self, env_ids)`

- **作用**：实现课程学习逻辑：根据机器人是否完成任务（走远、追踪奖励高）来调整 terrain level 或命令难度（扩大 command 范围）。
- **输入**：`env_ids`（待调整的 env 索引）。
- **处理**：
  - `_update_terrain_curriculum`：比较机器人行走距离与 `terrain.env_length / 2` 判断 move_up 或 move_down，更新 `terrain_levels`，并把成功的送到下一级或随机回溯；更新 `env_origins`；
  - `update_command_curriculum`：若 `tracking_lin_vel` 的平均成绩超过阈值（0.8 * scale），则扩展 `command_ranges["lin_vel_x"]`（上下限分别扩展）。
- **输出**：无（修改课程相关参数）。

------

# 8. 观测与噪声

### `compute_observations(self)`

- **作用**：构建每个 env 的观测向量 `obs_buf`（包含基座线/角速度、重力投影、命令、关节位置偏差、关节速度、上一步动作）并追加地形测高与噪声。
- **输入**：内部状态张量（`base_lin_vel`, `base_ang_vel`, `projected_gravity`, `commands`, `dof_pos`, `default_dof_pos`, `dof_vel`, `actions` 等）。
- **处理**：
  - `torch.cat` 把各个部分按顺序拼接（并乘以 `obs_scales` 进行归一化）；
  - 若 `cfg.terrain.measure_heights`：计算 `heights = clip(root_z - 0.5 - measured_heights, -1,1) * obs_scales.height_measurements` 并拼接到 obs；
  - 若 `add_noise`：把噪声向量（由 `_get_noise_scale_vec` 返回）乘随机均匀噪声并加到 obs。
- **输出**：`self.obs_buf`（形状 `(num_envs, obs_dim)`）。
- **注意**：obs 的结构必须与训练网络的 `num_observations` 匹配。

### `_get_noise_scale_vec(self, cfg)`

- **作用**：构建与 `obs_buf[0]` 同形状的噪声尺度向量，用于按元素缩放均匀噪声。
- **输入**：`cfg.noise` 和 `self.obs_scales`。
- **处理**：根据 cfg 分段设置不同观测部分的噪声量（lin_vel, ang_vel, gravity, dof_pos, dof_vel, height_measurements 等）。
- **输出**：噪声尺度向量 `noise_vec`。

------

# 9. 高度测量 / 可视化

### `_init_height_points(self)`（已在「缓冲区初始化」中解释）

- **作用**：生成相对于 base 的测高点网格（x,y）, 返回 `(num_envs, n_points, 3)`。

### `_get_heights(self, env_ids=None)`

- **作用**：在地形上采样指定点的高度值（将 base frame 的点转换到 world/heightfield 索引并从 `self.height_samples` 中取值）。
- **输入**：`env_ids`（可选，若不传则对所有 env 采样）。
- **处理**：
  - 若地形类型为 plane 返回零高度；若 none 抛错；
  - 通过 `quat_apply_yaw` 把 base 的 yaw 旋转应用到测点（得到世界坐标），再加上 `root_states[:, :3]` 得到全局点坐标；
  - 为了索引 height samples 做偏移、缩放（`border_size`, `horizontal_scale`），然后转成整数索引并 clip 到合法范围；
  - 从 `height_samples` 中获取 3 个相邻格子的高度 (`heights1/2/3`) 并取 min（作者用了 min，以避免某些网格边界问题？）；
  - reshape 回 `(num_envs, -1)` 并乘 `vertical_scale` 返回物理高度值。
- **输出**：`heights`，shape `(num_envs, num_height_points)`。
- **注意**：采样时需要确保 `self.height_samples` 已经初始化（在创建 heightfield/trimesh 时有赋值）。

### `_draw_debug_vis(self)`

- **作用**：基于 `measured_heights` 在 viewer 中绘制小球或线，用于调试高度采样。
- **输入**：viewer 已存在且 `terrain.measure_heights` 为 True。
- **处理**：按 env 循环，通过 `gymutil.draw_lines` 在位置处画 wireframe sphere。
- **输出**：无（仅用于可视化）。

------

# 10. 奖励体系（reward）

### `_prepare_reward_function(self)`

- **作用**：从 cfg 中读取 reward scales，把非零的 reward 加入到 `self.reward_functions` 列表（映射到 `_reward_` 前缀的函数），并把 scale 乘以 `dt`（时间增量）以便用作每步累加。还初始化 `episode_sums` 用于统计。
- **输入**：`self.reward_scales` 已由 `_parse_cfg` 从 cfg 转换得到。
- **处理**：
  - 删除 scale==0 的项（节省计算）；
  - 每个非 `termination` 的 reward 名称拼接 `_reward_<name>`，取函数引用放到 `reward_functions`；
  - 每个 scale *= self.dt；
  - 初始化 `episode_sums`（用于后续平均/记录）。
- **输出**：无（但填充 `reward_functions`, `reward_names`, `episode_sums`）。

### `_reward_*`（一系列）

- **作用**：每个 `_reward_xxx` 计算一个原始的 reward 项（未乘 scale），返回形状 `(num_envs,)` 的张量。常见项包括：
  - `_reward_lin_vel_z`：惩罚 z 方向线速度（`base_lin_vel[:,2]^2`）；
  - `_reward_ang_vel_xy`：惩罚 x,y 轴角速度（`sum(square(base_ang_vel[:, :2]), dim=1)`）；
  - `_reward_orientation`：惩罚倾斜（`projected_gravity` 的 xy 分量平方和）；
  - `_reward_tracking_lin_vel`：速度追踪（用 exp(-error/tracking_sigma)）；
  - `_reward_feet_air_time`：奖励更长的步态空中时间（复杂、基于接触过滤）；
  - 还有扭矩、关节速度/加速度限制、碰撞惩罚、终止惩罚等。
- **输入**：使用类内已存在的各种张量（`self.base_lin_vel`、`self.commands`、`self.contact_forces` 等）。
- **处理**：按定义做数学计算并返回 `(num_envs,)`。
- **输出**：每个 reward 函数返回单独项，`compute_reward()` 中会把它们乘以对应的 scale 并累加到 `self.rew_buf` 与 `episode_sums`。

### `compute_reward(self)`

- **作用**：遍历 `self.reward_functions`，调用每个 reward，乘以 scale 并叠加；可选地把负值裁为 0（`only_positive_rewards`）；最后把 `termination` reward（若存在）加上。
- **输入**：无（使用 `self.reward_functions` 与 `self.reward_scales`）。
- **处理**：
  - `self.rew_buf[:] = 0.`；
  - 对于每个 reward 调用并累加到 `rew_buf` 与 `episode_sums`；
  - 可选 clip（只保留正 reward）；
  - 终止奖励在之后单独加。
- **输出**：写入 `self.rew_buf`, `self.episode_sums`。

------

# 11. 配置解析 / 工具

### `_parse_cfg(self, cfg)`

- **作用**：从 cfg 读取并计算一些派生量（例如 `dt = control.decimation * sim_params.dt`、`max_episode_length = ceil(episode_length_s / dt)`、把 reward scales/command ranges 用 `class_to_dict` 转成字典等）。
- **输入**：`cfg`。
- **处理**：如上，主要是把易用的变量存在实例中。并把 `cfg.domain_rand.push_interval_s` 转换为 step 数。
- **输出**：无（填内部变量）。

------

# 结论 / 你可以如何理解这份架构（要点）

- **是的**，可以把整个类看成若干“功能区”：
  - 主循环/接口层（`step`, `post_physics_step`） —— 对外（训练代码）交互；
  - 仿真与环境创建层 —— 把 URDF/MJCF 加进模拟，建立地形；
  - 状态缓冲层 —— 把 gym 的原始张量包装成 torch，用于高效并行计算；
  - 回调/随机化层 —— 在资产创建或每次 step 时注入域随机、摩擦随机、推力随机、命令随机等；
  - 控制器层 —— action 到 torque 的映射；
  - 观测与噪声层 —— 构建 agent 的观测向量；
  - 奖励层 —— 计算并组合不同奖励项。
- 这种模块化使得你可以 **单独替换/扩展**任意一个区域：比如想改 reward，只加/改 `_reward_xxx` 并在 cfg 中设置 scale；想改命令/课程策略就改 `_resample_commands` 或 `update_command_curriculum`；想改动作表示（从 P 改到 T）只改 cfg.control.control_type。

# 实战建议 / 注意点（务实）

- 修改 reward 函数的时候要注意 **返回 shape 必须是 `(num_envs,)`**，且不要忘了 `_prepare_reward_function` 会把 scale 乘以 `dt`；scale 为 0 的项会被剔除。
- `obs_buf` 的构成必须和训练网络的输入维度 `env.num_observations` 对齐，否则会维度错配。
- 在多环境并行训练时（大规模 `num_envs`），确保 tensor device（CPU/GPU）一致，避免频繁的 device copy。
- `self.dof_names` 与 `cfg.control.stiffness` 的匹配是基于字符串包含（`if dof_name in name`），如果你的 dof 名称与 cfg 不匹配，会出现 `p_gains` 为 0 的警告。
- `height` 采样、`terrain` 相关的索引逻辑（取最小的三个邻近格）是实现细节，若你使用较粗/细格子或不同边界策略，需留意边界条件（clip 的部分）。

------

如果你愿意，我可以接着做两件事（选其一或两个都做）：

1. 把上面按“区域”整理成一张简化的函数调用关系图（文本版或伪代码流程图），帮助你快速定位函数调用链；
2. 给出一个**修改 reward 或加入新的回调** 的示例代码片段，演示如何安全地扩展（并说明要修改哪些 cfg 字段）。

你想先看哪一个？







下面我按 **每个 `class` 一个一节** 来解释 `LeggedRobotCfg`（和 `LeggedRobotCfgPPO`）里每个字段的语义、单位、典型取值、对仿真/训练的影响以及注意事项。为了易读，每个字段会给出「作用 / 含义」、「单位/类型 / 典型范围」和「影响与提示」。

------

# env（环境总体参数）

- **num_envs**
  - 含义：并行环境数量（同时在 GPU/CPU 上模拟的独立机器人实例数）。
  - 类型/典型值：整数（示例 4096）。
  - 影响：越多并行样本速度越高（样本效率），但显著增加显存/内存和物理碰撞计算负担。选择受硬件限制。
- **num_observations**
  - 含义：每个环境的观测向量长度（神经网络输入维度）。
  - 类型：整数（示例 235）。
  - 影响：必须与 agent 的网络输入一致。改动需同步网络结构。
- **num_privileged_obs**
  - 含义：是否使用 privilege observations（用于不对称训练，给 critic 更多信息）。`None` 表示不使用。
  - 类型：整数或 None。
  - 影响：若不为 None，`step()` 会返回 `privileged_obs_buf`。用于带辅助信息的 critic。
- **num_actions**
  - 含义：每个环境的动作维度（网络输出数）。
  - 类型：整数（示例 12）。
  - 影响：要和机器人 actuated DOFs 或控制策略一致。
- **env_spacing**
  - 含义：在平面/非自定义地形时，环境网格之间的间距（m）。多个 env 在场景中布置成网格时使用。
  - 单位：米（示例 3.0）。
  - 影响：过小会导致 env 之间互相干扰（碰撞/渲染问题），过大浪费空间。
- **send_timeouts**
  - 含义：是否在 `extras` 中报告超时信息。
  - 类型：bool。
  - 影响：若 True，训练算法可以区分是超时结束还是被终止（有助于奖励/统计分析）。
- **episode_length_s**
  - 含义：单个 episode 的时长（秒）。
  - 单位：秒（示例 20）。
  - 影响：与 `dt`、`decimation` 联合决定步数（`max_episode_length = ceil(episode_length_s / dt)`）。太短可能无法学习长任务，太长训练收敛慢。

------

# terrain（地形与地形课程参数）

- **mesh_type**
  - 含义：地形类型，选项：`none、plane、heightfield、trimesh`。`trimesh` 表示使用三角网格地形。
  - 影响：不同地形影响碰撞、接触报告、测高逻辑等。
- **horizontal_scale / vertical_scale**
  - 含义：高度图网格的水平/垂直缩放（将离散高度样本转换为米）。
  - 单位：米（示例 horizontal 0.1 m, vertical 0.005 m）。
  - 影响：控制 terrain 的物理尺寸与分辨率。vertical_scale 小会把样本高度压缩。
- **border_size**
  - 含义：高度图或三角网格的边界偏移量（用于坐标变换/索引）。
  - 单位：米（示例 25）。
- **curriculum**
  - 含义：是否启用地形课程学习（逐步增加难度）。
  - 类型：bool。
  - 影响：若 True，会使用 `_update_terrain_curriculum` 动态调整 `terrain_levels`。
- **static_friction / dynamic_friction / restitution**
  - 含义：地面静/动摩擦系数和弹性系数。
  - 影响：直接影响接触力和走路稳定性。域随机时这些可随机化。
- **measure_heights**
  - 含义：是否启用机器人周围点位的高度测量（作为观测的一部分）。
  - 影响：若 True，观测向量会包含地形高度信息（提高感知但增加 obs 维度）。
- **measured_points_x / measured_points_y**
  - 含义：以 base frame 为参考的测高采样点列表（x、y 坐标的集合，组成采样网格）。
  - 单位：米（示例数组）。
  - 影响：决定观测中高度信息的空间分辨率与覆盖区域。
- **selected / terrain_kwargs**
  - 含义：用于手动选择具体 terrain 类型及其参数（高级用法）。
  - 类型：bool / dict。
- **max_init_terrain_level**
  - 含义：初始地形难度等级的最大值（课程起始），用于随机初始化 terrain_levels。
- **terrain_length / terrain_width**
  - 含义：单个地形平台的尺寸（m），用于粗糙地形布局。
- **num_rows / num_cols**
  - 含义：地形集合的行数（等级）与列数（类型）—— 用于把多种地形以矩阵方式组织（课程中不同列代表不同地形类型）。
  - 影响：影响 `terrain_origins` 布局与 `terrain_levels` 取值范围。
- **terrain_proportions**
  - 含义：各类地形在生成时的占比（例如：斜坡、台阶等）。
  - 影响：用于生成 terrain 时的概率分配（用于多样化训练集）。
- **slope_treshold**
  - 含义：仅 trimesh 时使用，高于该坡度阈值的斜面会被修正为垂直面（防止穿透/不稳定接触）。
  - 影响：控制地形可行走表面与不可行走区域的分界。

------

# commands（外部运动命令 / 任务参数）

- **curriculum**
  - 含义：是否对命令范围使用课程学习（逐步增大 max command）。
  - 影响：如果 True，`update_command_curriculum` 会根据表现扩大命令范围。
- **max_curriculum**
  - 含义：命令课程允许的最大线速度（或范围扩展界限）。
  - 影响：限制课程中 `lin_vel_x` 的上限。
- **num_commands**
  - 含义：命令矢量的长度（例如 [lin_vel_x, lin_vel_y, ang_vel_yaw, heading]）。
  - 影响：决定 `self.commands` 的维度以及 `compute_observations` 中拼接的位置。
- **resampling_time**
  - 含义：命令在多少秒后重采样（s）。
  - 单位：秒（示例 10s）。
  - 影响：命令变化频率影响学习难度与策略鲁棒性。
- **heading_command**
  - 含义：是否使用 heading 模式（用 heading 错误计算 yaw 角速度命令）。
  - 影响：若 True，`commands[:,3]` 存 heading，`_post_physics_step_callback` 会把 heading 转换为 yaw 速度命令。
- **ranges.lin_vel_x / lin_vel_y / ang_vel_yaw / heading**
  - 含义：各命令的最小/最大值范围（例：线速度→m/s，角速度→rad/s，heading→rad）。
  - 影响：训练时 agent 需要在此范围内跟踪命令；课程策略会扩展/收窄这些范围。

------

# init_state（初始位姿/速度与关节默认角）

- **pos**
  - 含义：机器人 base 的初始位置 [x,y,z]（m）。
- **rot**
  - 含义：初始四元数 [x,y,z,w]（表示朝向）。
- **lin_vel / ang_vel**
  - 含义：初始线速度和角速度向量（m/s，rad/s）。
- **default_joint_angles**
  - 含义：动作为 0 时各关节的目标角度（作为 default_dof_pos），通常以字典形式按 joint 名称给出。
  - 影响：控制策略（尤其 P 控制）会以 `default_joint_angles` 为基准；设置不合理可能导致启动抖动或不自然姿态。

------

# control（控制器相关）

- **control_type**
  - 含义：动作解释类型：`'P'`（位置目标 PD 控制），`'V'`（速度目标 PD 控制），`'T'`（直接扭矩）。
  - 影响：决定 `_compute_torques` 如何将 action 转换为 torques。不同类型对 reward/稳定性影响大。
- **stiffness（比例增益）**
  - 含义：每种关节/关节组的 P（比例）增益（N·m / rad）。
  - 影响：P 太大会引发振荡 / 不稳定；太小控制响应慢。通过 joint 名称匹配给每个 dof 指定 gain。
- **damping（阻尼 / D 增益）**
  - 含义：每关节的 D 增益（N·m·s / rad）。
  - 影响：抵消速度引起的振荡，通常与 stiffness 配合调整。
- **action_scale**
  - 含义：动作缩放系数，目标角度 = action * action_scale + defaultAngle（对于 P 控制）。
  - 影响：控制动作的实际幅度；需要与 default_joint_angles 和关节极限配合。
- **decimation**
  - 含义：策略输出周期对应的仿真子步数（policy 每次更新间隔内仿真步的数量）。
  - 影响：较大 decimation 表示 agent 的动作更新频率更低（每个动作在仿真中持续更多步），有时有利于稳定训练但降低控制精细度。`dt = sim_params.dt * decimation`。

------

# asset（机器人资源 / 资产设置）

- **file**
  - 含义：URDF/MJCF 文件路径（可以使用路径格式化变量）。
  - 影响：指定机器人模型。
- **name**
  - 含义：actor 名称（在 gym 中的标识）。
- **foot_name**
  - 含义：用于识别腿/足的 body 名称子串（用于接触检测/奖励索引）。
  - 影响：确保字符串能匹配到模型里的脚体名，否则脚相关奖励/检测失效。
- **penalize_contacts_on / terminate_after_contacts_on**
  - 含义：分别是要惩罚接触的 body 名称列表和导致终止的接触 body 名称列表（按子串匹配）。
  - 影响：定义哪些碰触算作不良接触或终止条件。
- **disable_gravity / collapse_fixed_joints / fix_base_link**
  - 含义：资产加载时的选项，控制是否禁用重力、是否合并固定关节、是否固定 base（用于测试）。
  - 影响：改变动力学行为或简化模型。
- **default_dof_drive_mode**
  - 含义：DOF 驱动模式（例如 0 none, 1 pos tgt, 2 vel tgt, 3 effort）。与 URDF/physx 驱动对应。
  - 影响：决定如何把 torques/targets 应用到 DOF。
- **self_collisions**
  - 含义：是否启用自碰撞（以及碰撞位掩码设置）。
  - 影响：自碰撞开会增加计算成本，但更真实。
- **replace_cylinder_with_capsule / flip_visual_attachments**
  - 含义：优化碰撞体（用胶囊代替圆柱）和可视化网格方向修正。
  - 影响：能提升仿真稳定性和渲染显示正确性。
- **density, angular_damping, linear_damping, max_angular_velocity, max_linear_velocity, armature, thickness**
  - 含义：资产的物理属性（密度、阻尼、速度上限、骨架惯量调整、碰撞厚度）。
  - 影响：直接影响惯性、稳定性以及碰撞行为。调整需谨慎。

------

# domain_rand（域随机化）

- **randomize_friction**
  - 含义：是否随机化摩擦系数（true/false）。
  - 影响：可以提升策略在不同表面上的鲁棒性。
- **friction_range**
  - 含义：随机摩擦的最小/最大值范围（数组）。
  - 单位：无量纲（摩擦系数）。
  - 影响：范围太宽可能导致训练困难，太窄效果差。
- **randomize_base_mass / added_mass_range**
  - 含义：是否在 base（身体）上随机增加质量，以及增加质量的范围（kg）。
  - 影响：训练得到对负载变化更鲁棒的策略。
- **push_robots / push_interval_s / max_push_vel_xy**
  - 含义：是否周期性对机器人施加“脉冲推力”（通过设置基座速度实现），推的时间间隔（s）和最大线速度（m/s）。
  - 影响：通过随机外力提高鲁棒性；过强或太频繁可能阻碍学习。

------

# rewards（奖励设计）

- **scales（子类）**
  - 这里列出了各个 reward 项的基准 scale（会在 `_prepare_reward_function` 中乘以 `dt`）。例如：
    - `termination`：终止奖励/惩罚（通常用于倒地或触地等）。示例 `-0.0`。
    - `tracking_lin_vel`：线速度跟踪奖励权重（示例 1.0）。
    - `tracking_ang_vel`：角速度跟踪权重（示例 0.5）。
    - 其他项如 `lin_vel_z`（惩罚竖直速度）、`ang_vel_xy`、`torques`、`dof_acc`、`collision`、`feet_air_time` 等。
  - **提示**：scale 的符号与含义重要（正的奖励，负的惩罚）。`_prepare_reward_function` 会把非零 scale 乘以 `dt`（因此 scale 的物理含义是 *每秒* 的权重）。
- **only_positive_rewards**
  - 含义：若 True，则训练步骤中总 reward 会被裁剪为 >= 0（负值变为 0）。
  - 影响：避免 early termination 导致大量负奖励影响训练稳定性，但也会掩盖惩罚信号。
- **tracking_sigma**
  - 含义：用于 tracking reward 计算的 sigma（高斯/指数项扩展因子），例如 `exp(-error/tracking_sigma)`。
  - 影响：sigma 越大，误差容忍度越高；越小则更苛刻。
- **soft_dof_pos_limit / soft_dof_vel_limit / soft_torque_limit**
  - 含义：软限制系数（作为 URDF 上限的比例），超出该比例会被惩罚。
  - 影响：限制策略对关节范围、速度、扭矩的鲁棒使用，避免损伤/非物理动作。
- **base_height_target**
  - 含义：基座高度目标（m），用于 `_reward_base_height` 的目标跟踪。
  - 影响：与机器人体型/默认姿态匹配。
- **max_contact_force**
  - 含义：接触力阈值，超过此值开始惩罚（单位：N）。
  - 影响：约束步态冲击力，防止暴力接触。

------

# normalization（归一化与裁剪）

- **obs_scales**
  - 含义：用于对不同观测分量进行缩放归一（例如 `lin_vel`, `ang_vel`, `dof_pos`, `dof_vel`, `height_measurements`）。
  - 影响：影响观测数值范围，从而影响训练稳定性和网络输入分布。合理归一化很重要。
- **clip_observations**
  - 含义：对观测值的 element-wise 上下界裁剪（绝对值上限）。
  - 单位：与观测值同量纲（示例 100）。
  - 影响：防止数值爆炸和异常值。
- **clip_actions**
  - 含义：对 actions 的裁剪上限（绝对值）。
  - 影响：防止网络输出产生极端动作。

------

# noise（观测噪声）

- **add_noise**
  - 含义：是否给观测添加噪声（uniform in [-1,1] scaled by `_get_noise_scale_vec`）。
  - 影响：提高策略在传感器噪声下的鲁棒性。
- **noise_level**
  - 含义：全局噪声强度缩放（乘子）。
  - 影响：放大/缩小噪声幅度。
- **noise_scales**
  - 含义：对各观测分量的噪声基准尺度（dof_pos, dof_vel, lin_vel, ang_vel, gravity, height_measurements）。
  - 影响：针对不同传感器信号设置不同噪声，模拟现实传感器特性。

------

# viewer（可视化摄像机）

- **ref_env**
  - 含义：参考环境编号（viewer 用哪个 env 的位置作为参考）。
- **pos / lookat**
  - 含义：摄像机位置与目标点（世界坐标，米）。
  - 影响：仅用于可视化调试，无训练语义影响。

------

# sim（物理仿真参数）

- **dt**
  - 含义：仿真主时间步（s）。
  - 影响：与 `control.decimation` 一起决定策略步长 `policy_dt = dt * decimation`。dt 太大可能导致数值不稳定。
- **substeps**
  - 含义：物理内部子步数（每个 sim 主步内的细分步）。
  - 影响：增加子步数可提高稳定性但开销更大。
- **gravity**
  - 含义：重力向量（m/s²）。
  - 影响：直接影响机器人动力学行为。
- **up_axis**
  - 含义：哪一轴作“上”（0: x/y? 注：代码里用 2 表示 z 上），此配置决定坐标系的约定。
  - 注意：代码中 `up_axis_idx = 2`（z-up），cfg 中 `up_axis = 1`（有可能是 y-up）需保持一致，否则会出现坐标/重力方向不匹配。

## sim.physx（PhysX 专项参数）

- **num_threads**
  - 含义：PhysX 使用的 CPU 线程数（仅 CPU 计算相关）。
- **solver_type**
  - 含义：解算器类型（0 pgs，1 tgs 等）。
- **num_position_iterations / num_velocity_iterations**
  - 含义：物理迭代次数，影响接触求解精度与稳定性。
- **contact_offset / rest_offset**
  - 含义：碰撞偏移参数（m），用于接触检测阈值。
- **bounce_threshold_velocity / max_depenetration_velocity**
  - 含义：弹跳阈值速度与最大分离速度限制。
- **max_gpu_contact_pairs, default_buffer_size_multiplier, contact_collection**
  - 含义：GPU contact 缓冲区、缓冲区扩展、接触收集策略（0/1/2 表示何时收集接触信息）。
  - 影响：大规模并行 env（数千）时需要较大的 contact buffer。

------

# LeggedRobotCfgPPO（训练与 PPO 算法相关）

这是训练框架/超参数（与仿真配置分开），包含策略网络、PPO 算法与 runner（训练循环）设置。

## 顶层

- **seed**
  - 含义：随机种子（保证可复现）。
- **runner_class_name**
  - 含义：训练 runner 的类型（例如 OnPolicyRunner）。

## policy（策略/网络结构）

- **init_noise_std**
  - 含义：策略输出初始噪声标准差（用于探索或初始化）。
- **actor_hidden_dims / critic_hidden_dims**
  - 含义：actor / critic 网络的隐藏层维度列表（例如 [512,256,128]）。
  - 影响：网络容量越大拟合能力越强但更易过拟合、训练更慢。
- **activation**
  - 含义：激活函数类型（如 elu, relu 等）。
  - 影响：训练稳定性与收敛性。

（若使用 RNN，会有 rnn_type / rnn_hidden_size / rnn_num_layers 等）

## algorithm（PPO 超参数）

- **value_loss_coef**
  - 含义：价值损失在总损失中的权重。
- **use_clipped_value_loss**
  - 含义：是否对 value loss 使用裁剪（PPO 的常见做法）。
- **clip_param**
  - 含义：PPO 的策略剪切参数 ε（典型 0.1~0.3）。
- **entropy_coef**
  - 含义：熵项权重（鼓励探索）。
- **num_learning_epochs**
  - 含义：每轮更新中使用的 epoch 数（通过数据多次迭代）。
- **num_mini_batches**
  - 含义：将一次 rollout 数据拆分成多少小批量（影响每次更新的小批大小）。
- **learning_rate**
  - 含义：学习率。
- **schedule**
  - 含义：学习率调度策略（adaptive / fixed）。
- **gamma**
  - 含义：折扣因子（通常 0.95~0.999）。
- **lam**
  - 含义：GAE 的 lambda 参数。
- **desired_kl**
  - 含义：如自适应学习率，目标 KL 值。
- **max_grad_norm**
  - 含义：梯度裁剪上限（用于保持训练稳定）。

## runner（训练循环 / 运行配置）

- **policy_class_name / algorithm_class_name**
  - 含义：使用的策略和算法类名（如 ActorCritic, PPO）。
- **num_steps_per_env**
  - 含义：每个环境在一次 rollout 中走多少步（采样长度），决定每次更新的数据量（nsteps）。
- **max_iterations**
  - 含义：总的策略更新次数（迭代次数）。

### 日志与检查点

- **save_interval**
  - 含义：每多少次迭代检查是否需要保存模型。
- **experiment_name / run_name**
  - 含义：记录实验与结果命名（用于日志管理）。
- **resume / load_run / checkpoint / resume_path**
  - 含义：与恢复训练相关的配置（是否从已有 checkpoint 恢复、加载哪个 run 等）。

------

# 最后 — 实用建议（汇总）

1. **一致性**：`num_actions`、`num_observations`、`default_joint_angles`、`dof_names` 与 robot asset 必须一致，否则会出现索引或匹配错误。
2. **单位一致**：速度（m/s）与角速度（rad/s）、位置（m）等要保持一致。`horizontal_scale/vertical_scale` 用于高度map转换，容易搞错。
3. **课程学习**：开启 terrain / command curriculum 可以加速并稳健提升能力，但需要合理的晋级条件（如 tracking reward 阈值）。
4. **域随机**：摩擦、质量、推力等的随机化能大幅提升 sim2real 的鲁棒性，但过强会阻碍收敛。
5. **观测维度**：`measure_heights` 会大幅增加 obs 维度（height map 点数），对应要扩展网络输入或减少其他观测项。
6. **调试**：先用较小 `num_envs` 和较短 `episode_length_s` 做快速迭代，参数稳定后再放大规模。

------

如果你希望，我可以：

- 针对某个 `class`（例如 `rewards` 或 `control`）把每个字段列成表格并给出调参建议（例如如何在真实机器人上设置 `stiffness/damping` 的起点）；或者
- 帮你把 `obs_scales` 和 `num_observations` 对齐（检查当前 cfg 是否与代码中拼接的 obs 结构一致，列出每一段观测的维度）。

你想先看哪一个？