function fit_results = GNG_sim_fit(priors,gen_choices,outcomes,field)
    DCM.field  = field;
    DCM.MDP = priors;

    DCM.U      = {outcomes};              % trial specification (stimuli)
    DCM.Y      = {gen_choices};              % responses (action)

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

    fit_results = [prior posterior {MDP} acc_avg p_avg];

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



end