% Function for running the basic Rescorla-Wagner reinforcement learning 
% model.
% 
% Can assess the log-likelihood of a given parameter combination (when 
% provided both rewards and choices), or can simulate behavior for a given 
% parameter combination (when given only rewards and parameters).
%
% Parameters:
%   params:  struct array with fields:
%       .alpha: learning rate (0.0 - 1.0)
%       .beta:  exploration ( > 0.0)
%       .V0:    initial value for expected reward
%       .split_learning (if TRUE, then use alphas below)
%       .alpha_win
%       .alpha_loss
%   rewards: (num_choices x T) matrix, where num_choices is number of 
%            choices and T is number of trials, where rewards(k, t) is the 
%            reward gained for choosing option k at time t.
%   choices: (1 x T) vector, where choices(t) is the selected choice at
%            timepoint t.
% 
% Return Values:
%   expected_reward:(num_choices x T) matrix, where expected_reward(k, t) 
%                   is the expected value for choice k at time t.
%   sim_choices:    (1 x T) vector, where sim_choices(t) is the selecetd
%                   choice at timepoint t, when simulating. NaN when not 
%                   simulating (when choices are provided)
%   P:              A (num_choices x T) matrix, where P(k, t) is the
%                   probability of choosing choice k at time t.
%
% Written by: Samuel Taylor, Laureate Institute for Brain Research (2022)

function [model_output] = RW_model_extended_GNG(params, rewards, states, choices)
    
    % For a N-choice decision task.
    N_CHOICES = 2;
    
    % Extract the total number of trials.
    T = 160;
    
    %Extract the total number of states
    N_STATES = 4;
    % Represents the value function (number of choices X number of trials).
    % Has dimensions for both time and number of choices to keep track of
    % expceted reward over time.
    % dimension 1 is go to win
    % dimension 2 is go to avoid losing
    % dimension 3 is nogo to win
    % dimension 4 is nogo to avoid losing
    expected_reward = zeros(N_CHOICES, T, N_STATES);
    stimulus_value = zeros(1,T,N_STATES);
    
    % Represents the probability distribution of making a particular choice
    % over time.
    P = zeros(N_CHOICES, T);
    
    % If choices are passed in, do not run as simulation, but instead use
    % provided choices (typically used for fitting).
    if (~isnan(choices) & ~isnan(rewards))
        sim = false;
        observations = NaN;
    % If choices are not passed in, run as a simulation instead, selecting
    % choices based on current value of expected reward at that timestep.
    else
        sim = true;
        choices = zeros(1, T);
        rewards = zeros(N_CHOICES, T, N_STATES);
        observations = zeros(1, T);
    end
    
    action_probabilities = zeros(1, T);
    prediction_error_sequence = zeros(1,T);
    stimulus_prediction_error_seq = zeros(1,T);
    % For each trial (timestep)...
    for t = 1:T
        % Transform the expected reward vector to a discrete probability 
        % distribution using a softmax function (which includes `beta` as 
        % an exploration parameter).
        
        if (states(t) == 1 || states(t) ==3)
            Weight_go = expected_reward(2, t,states(t)) + params.beta + params.pi_win*stimulus_value(1,t,states(t));
            Weight_nogo = expected_reward(1, t,states(t));
        elseif (states(t) == 2 || states(t) ==4)
            Weight_go = expected_reward(2, t,states(t)) + params.beta + params.pi_loss*stimulus_value(1,t,states(t));
            Weight_nogo = expected_reward(1, t,states(t));
        end
        

        if ((exp(Weight_go) == inf && exp(Weight_nogo) == inf) || (exp(Weight_go) == 0 && exp(Weight_nogo) == 0))
            P(2, t) = 1/2;
            P(1,t) = 1/2;
        elseif (exp(Weight_go) == inf || exp(Weight_nogo) == 0)
            P(2, t) = 1*(1-params.zeta) + (params.zeta/2);
            P(1,t) = 0*(1-params.zeta) + (params.zeta/2);
        elseif (exp(Weight_nogo) == inf || exp(Weight_go) == 0)
            P(2, t) = 0*(1-params.zeta) + (params.zeta/2);
            P(1,t) = 1*(1-params.zeta) + (params.zeta/2);
        else
            P(2, t) = (exp(Weight_go) / (exp(Weight_go)+exp(Weight_nogo)))*(1-params.zeta) + (params.zeta/2);
            P(1, t) = (exp(Weight_nogo) / (exp(Weight_go)+exp(Weight_nogo)))*(1-params.zeta) + (params.zeta/2);  
        end
        
        % If not simulating, get choice selected at t.
        if ~sim
            choice_at_t = choices(t);
        % If simulating, sample from P(:, t) instead
        else
            choice_at_t = randsample(1:N_CHOICES, 1, true, P(:, t));
            choices(t) = choice_at_t;
            if (states(t) == 1)
                r = rand();
                if choice_at_t == 2
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 1;
                    else
                        rewards(choice_at_t,t, states(t)) = 0;
                    end
                elseif choice_at_t == 1
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 0;
                    else
                        rewards(choice_at_t,t, states(t)) = 1;                    
                    end
                end
            
            elseif (states(t) ==2)
                r = rand();
                if choice_at_t == 2
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 0;
                    else
                        rewards(choice_at_t,t, states(t)) = -1;
                    end
                elseif choice_at_t == 1
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = -1;
                    else
                        rewards(choice_at_t,t, states(t)) = 0;                    
                    end
                end
        
            elseif (states(t) ==3)
                r = rand();
                if choice_at_t == 2
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 0;
                    else
                        rewards(choice_at_t,t, states(t)) = 1;
                    end
                elseif choice_at_t == 1
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 1;
                    else
                        rewards(choice_at_t,t, states(t)) = 0;                    
                    end
                end
                
            elseif (states(t) ==4)
                r = rand();
                if choice_at_t == 2
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = -1;
                    else
                        rewards(choice_at_t,t, states(t)) = 0;
                    end
                elseif choice_at_t == 1
                    if r <= .8
                        rewards(choice_at_t,t, states(t)) = 0;
                    else
                        rewards(choice_at_t,t, states(t)) = -1;                    
                    end
                end   
            end
            observations(t) = rewards(choice_at_t,t, states(t));
        end
        
        % Store the probability of the chosen action being selected at this
        % timepoint.
        action_probabilities(t) = P(choice_at_t, t);
        
        
        % Reward Prediction error is: reward recieved minus the expected reward
        % of the selected choice. Different for rewarding and punishing
        % contexts
        if (states(t) == 1 || states(t) ==3)
            prediction_error = (params.rs*rewards(choice_at_t, t, states(t))) - expected_reward(choice_at_t, t, states(t));
            stimulus_prediction_error = (params.rs*rewards(choice_at_t, t, states(t))) - stimulus_value(1, t, states(t));
        elseif (states(t) == 2 || states(t) ==4)
            prediction_error = (params.la*rewards(choice_at_t, t, states(t))) - expected_reward(choice_at_t, t, states(t));
            stimulus_prediction_error = (params.la*rewards(choice_at_t, t, states(t))) - stimulus_value(1, t, states(t));
        end
        
        prediction_error_sequence(t) = prediction_error;
        stimulus_prediction_error_seq(t) = stimulus_prediction_error;
        % Copy previous expected reward values (to keep unchosen choices at
        % the same value from the previous timestep). Do same for previous 
        % stimulus values
        expected_reward(:, t + 1, :) = expected_reward(:, t,:);
        stimulus_value(:,t+1,:) = stimulus_value(:,t,:);
        
        % Update the expected reward of the selected choice (split or single LR).
        % update the expected reward of a state
        if (states(t) == 1 || states(t) ==3)
            expected_reward(choice_at_t, t + 1, states(t)) = expected_reward(choice_at_t, t,states(t)) + (params.alpha_win * prediction_error);
            stimulus_value(1,t+1,states(t)) = stimulus_value(1,t,states(t)) + (params.alpha_win * stimulus_prediction_error);
        elseif (states(t) == 2 || states(t) ==4)
            expected_reward(choice_at_t, t + 1, states(t)) = expected_reward(choice_at_t, t,states(t)) + (params.alpha_loss * prediction_error);
            stimulus_value(1,t+1,states(t)) = stimulus_value(1,t,states(t)) + (params.alpha_loss * stimulus_prediction_error);
        end

    
    % Trims final value in expected reward matrix (if is an extra value beyond
    % trials).
    expected_reward = expected_reward(:, 1:T, :);
    stimulus_value = stimulus_value(:, 1:T,:);
    
    % Store model variables for returning.
    model_output.choices = choices;
    model_output.rewards = rewards;
    model_output.expected_reward = expected_reward;
    model_output.prediction_errors = prediction_error_sequence;
    model_output.P = P;
    model_output.action_probabilities = action_probabilities;
    model_output.stimulus_prediction_errors = stimulus_prediction_error_seq;
    model_output.observations = observations;
    end
;