# Reinforcement-Learning-Model-for-Go-No-Go-Task
Reinforcement Learning Model for simulating and fitting data for a stop signal task that crosses action (go or no go) 
with valence (win or loss). Fitting estimates the model's free parameters by maximizing negative log likelihood. This procedure is done
using variational laplace, with code from https://github.com/spm/spm.

# MAIN FILE
go_no_go_main.m
Assumes there is a directory of individual subjects' behavioral files whose location is stored in input_dir.
For a subject in input_dir, indicate if you would like to run the scripts on a cluster or pc, as well as if we would like to simulate, fit, 
or simulate then fit the task data. 

# FITTING TASK DATA 
GNG_fit.m -> GNG_inversion_RL.m -> 
Subject data is processed and passed as an argument to the inversion script. Inside the inversion script, the newton function calls the rescorla wagner model 
to get the negative log likelihood of participant's choices under a given set of free parameters. The newton function uses variational laplace to find the free 
parameters that maximize negative log likelihood. Once these parameters are found, model accuracy and average action probability are calculated.

# SIMULATING TASK DATA
GNG_sim.m
Simulates task data and plots it. 

# SIMULATING TASK DATA THEN FITTING IT
GNG_sim.m -> GNG_sim_fit.m
Simulates task data and fits it using the same process described above.


