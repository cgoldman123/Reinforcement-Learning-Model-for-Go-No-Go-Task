function fit_results = GNG_fit(subject, input_dir, field, priors, PLOT)

file = [input_dir '/' subject '-T0-GNGB-R1-_BEH.csv'];

%% Add Subj Data (Parse the data files)

opts = detectImportOptions(file);
opts.VariableNamesLine = 2; % specify that the second line has the variable names
subdat = readtable(file, opts);


for trial = 0:159
    trial_rows = subdat.trial_number == trial;
    if any(subdat.event_code(trial_rows) == 5)
        action = 2;
    else 
        action = 1;
    end
    outcome_row = trial_rows & (subdat.event_code ==8);
    outcome = str2double(subdat.response(outcome_row));
    state = subdat.trial_type(outcome_row)+1;
    
    outcomes(trial+1,:) = [action, outcome, state];
end


sub.o = outcomes(:,1);
o_all = sub.o;
sub.u = outcomes(:,2:3);
u_all = sub.u;



%% 6.2 Invert model and try to recover original parameters:
%==========================================================================

%--------------------------------------------------------------------------
% This is the model inversion part. Model inversion is based on variational
% Bayes. The basic idea is to maximise (negative) variational free energy
% wrt to the free parameters (here: alpha and cr). This means maximising
% the likelihood of the data under these parameters (i.e., maximise
% accuracy) and at the same time penalising for strong deviations from the
% priors over the parameters (i.e., minimise complexity), which prevents
% overfitting.
% 
% You can specify the prior mean and variance of each parameter at the
% beginning of the TAB_spm_dcm_mdp script.
%--------------------------------------------------------------------------
% TpB = 32;
% NB = 5;
% DCM.TpB        = TpB;        % trials per block
% DCM.NB         = NB;         % number of blocks

DCM.field  = field;
DCM.MDP = priors;

DCM.U      = {u_all};              % trial specification (stimuli)
DCM.Y      = {o_all};              % responses (action)

DCM        = GNG_inversion_RL(DCM);   % Invert the model

%% 6.3 Check deviation of prior and posterior means & posterior covariance:
%==========================================================================

%--------------------------------------------------------------------------
% re-transform values and compare prior with posterior estimates
%--------------------------------------------------------------------------
field = fieldnames(DCM.M.pE);
for i = 1:length(field)
    if strcmp(field{i},'alpha_win')
        prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
        posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));
    elseif strcmp(field{i},'alpha_loss')
        prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
        posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));
    elseif strcmp(field{i},'zeta')
        prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
        posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));       
    elseif strcmp(field{i},'V0')
        prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
        posterior(i) = 1/(1+exp(-DCM.Ep.(field{i}))); 
    elseif strcmp(field{i},'beta')
        prior(i) = exp(DCM.M.pE.(field{i}));
        posterior(i) = exp(DCM.Ep.(field{i})); 
    elseif strcmp(field{i},'prior_a')
        prior(i) = DCM.M.pE.(field{i});
        posterior(i) = DCM.Ep.(field{i}); 
    else
        prior(i) = exp(DCM.M.pE.(field{i}));
        posterior(i) = exp(DCM.Ep.(field{i}));
    end
end

U_block = DCM.U{:};
states_block = U_block(:,2);
Y_block = DCM.Y{:};

task_rewards = zeros(2,160,4);
% choices the participant made
choices = zeros(1,160);
for trial = 1:160
    choices(trial) = Y_block(trial,1);
    task_rewards(choices(trial),trial, U_block(trial,2)) = U_block(trial,1);
end

    
params = struct('prior_a', posterior(1), 'alpha_win', posterior(2), 'alpha_loss', posterior(3), 'rs',posterior(4), 'la',posterior(4),... 
                'pi_loss', posterior(5), 'pi_win', posterior(6), 'zeta', posterior(7), 'beta', posterior(8));
MDP = RW_model_extended_GNG(params, task_rewards, states_block, choices);
MDP.observations = outcomes(:,2);
if PLOT
    GNG_plot(MDP, states_block);
end


action_probabilities = MDP.action_probabilities;
for i = 1:length(MDP.action_probabilities) % Get probability of true actions for each tria
    if MDP.P(MDP.choices(i),i) == max(MDP.P(:,i))
        acc(i) = 1;
    else
        acc(i) = 0;
    end
end
p_avg = sum(action_probabilities)/length(action_probabilities);
acc_avg = sum(acc)/length(acc);
fprintf('Avg action prob: %f\n', p_avg);
fprintf('Model accuracy: %f\n', acc_avg);

fit_results = [{file} prior posterior MDP acc_avg p_avg];

clear MDP;




%figure
%gtitle = sprintf('fit model');
%TAB_plot_RL(all_MDPs(3));


    %saveas(gcf,append(file.name(1:end-4),'_RL_TAB.png')) 

    %plot_2_arm_bandit(game_config, rewards, choices, MDPs);
    %plot_bandit_gradient(game_config, rewards, choices, MDPs);



% Return input file name, prior, posterior, output DCM structure, and
% list of MDPs across task using fitted posterior values
% FinalResults = [{file} prior posterior DCM all_MDPs p_acc_avg];
% save([result_dir '/' subject '_TAB_assoc_results.mat'], 'FinalResults')

%     clear all
%     close all

