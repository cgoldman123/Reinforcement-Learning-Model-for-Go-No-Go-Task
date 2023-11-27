% Samuel Taylor and Ryan Smith, 2021

% Model inversion script
function [DCM] = GNG_inversion_RL(DCM)

% MDP inversion using Variational Bayes
% FORMAT [DCM] = spm_dcm_mdp(DCM)

% If simulating - comment out section on line 196
% If not simulating - specify subject data file in this section 

%
% Expects:
%--------------------------------------------------------------------------
% DCM.MDP   % MDP structure specifying a generative model
% DCM.field % parameter (field) names to optimise
% DCM.U     % cell array of outcomes (stimuli)
% DCM.Y     % cell array of responses (action)
%
% Returns:
%--------------------------------------------------------------------------
% DCM.M     % generative model (DCM)
% DCM.Ep    % Conditional means (structure)
% DCM.Cp    % Conditional covariances
% DCM.F     % (negative) Free-energy bound on log evidence
% 
% This routine inverts (cell arrays of) trials specified in terms of the
% stimuli or outcomes and subsequent choices or responses. It first
% computes the prior expectations (and covariances) of the free parameters
% specified by DCM.field. These parameters are log scaling parameters that
% are applied to the fields of DCM.MDP. 
%
% If there is no learning implicit in multi-trial games, only unique trials
% (as specified by the stimuli), are used to generate (subjective)
% posteriors over choice or action. Otherwise, all trials are used in the
% order specified. The ensuing posterior probabilities over choices are
% used with the specified choices or actions to evaluate their log
% probability. This is used to optimise the MDP (hyper) parameters in
% DCM.field using variational Laplace (with numerical evaluation of the
% curvature).
%
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_mdp.m 7120 2017-06-20 11:30:30Z spm $

% OPTIONS
%--------------------------------------------------------------------------
ALL = false;

% prior expectations and covariance
%--------------------------------------------------------------------------
prior_variance = 2^-2;

for i = 1:length(DCM.field)
    field = DCM.field{i};
    try
        param = DCM.MDP.(field);
        param = double(~~param);
    catch
        param = 1;
    end
    if ALL
        pE.(field) = zeros(size(param));
        pC{i,i}    = diag(param);
    else
        if strcmp(field,'prior_a')
            pE.(field) = DCM.MDP.prior_a;             % don't transform prior_a
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'rs')
            pE.(field) = log(DCM.MDP.rs);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'la')
            pE.(field) = log(DCM.MDP.la);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;      
            
        elseif strcmp(field,'pi_win')
            pE.(field) = log(DCM.MDP.pi_win);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'pi_loss')
            pE.(field) = log(DCM.MDP.pi_loss);             % in log-space (to keep positive)
            pC{i,i}    = prior_variance;     
            
            
        elseif strcmp(field,'zeta')
            pE.(field) = log(DCM.MDP.zeta/(1-DCM.MDP.zeta));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_win')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_loss')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'beta')
            pE.(field) = log(DCM.MDP.beta);                % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_win')
            pE.(field) = log(DCM.MDP.alpha_win/(1-DCM.MDP.alpha_win));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_loss')
            pE.(field) = log(DCM.MDP.alpha_loss/(1-DCM.MDP.alpha_loss));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'V0')
            pE.(field) = log(1/3/(1-1/3));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        else
            pE.(field) = 0;      
            pC{i,i}    = prior_variance;
        end
    end
end

pC      = spm_cat(pC);

% model specification
%--------------------------------------------------------------------------
M.L     = @(P,M,U,Y)spm_mdp_L(P,M,U,Y);  % log-likelihood function
M.pE    = pE;                            % prior means (parameters)
M.pC    = pC;                            % prior variance (parameters)
%M.mdp   = DCM.MDP;                       % MDP structure
% M.TpB = DCM.TpB;
% M.NB = DCM.NB;
% Variational Laplace
%--------------------------------------------------------------------------
[Ep,Cp,F] = spm_nlsi_Newton(M,DCM.U,DCM.Y);

% Store posterior densities and log evidnce (free energy)
%--------------------------------------------------------------------------
DCM.M   = M;
DCM.Ep  = Ep;
DCM.Cp  = Cp;
DCM.F   = F;


return

function L = spm_mdp_L(P,M,U,Y)
% log-likelihood function
% FORMAT L = spm_mdp_L(P,M,U,Y)
% P    - parameter structure
% M    - generative model
% U    - inputs
% Y    - observed repsonses
%__________________________________________________________________________

if ~isstruct(P); P = spm_unvec(P,M.pE); end

% multiply parameters in MDP
%--------------------------------------------------------------------------
% mdp   = M.mdp;

field = fieldnames(M.pE);
for i = 1:length(field)
    if strcmp(field{i},'prior_a')
        params.(field{i}) = P.(field{i});
    elseif strcmp(field{i},'zeta')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));        
    elseif strcmp(field{i},'rs')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'la')
        params.(field{i}) = exp(P.(field{i}));   
        
    elseif strcmp(field{i},'pi_win')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'pi_loss')
        params.(field{i}) = exp(P.(field{i}));      
        
    elseif strcmp(field{i},'eta_win')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'eta_loss')
        params.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'beta')
        params.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'alpha_win')
        params.alpha_win = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'alpha_loss')
        params.alpha_loss = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'V0')
        mdp.parameters.(field{i}) = 1/(1+exp(-P.(field{i})));
    else
        mdp.(field{i}) = exp(P.(field{i}));
    end
end


% discern whether learning is enabled - and identify unique trials if not
%--------------------------------------------------------------------------
% if any(ismember(fieldnames(mdp),{'a','b','d','c','d','e'}))
%     j = 1:numel(U);
%     k = 1:numel(U);
% else
%     % find unique trials (up until the last outcome)
%     %----------------------------------------------------------------------
%     u       = spm_cat(U');
%     [i,j,k] = unique(u(:,1:(end - 1)),'rows');
% end
% TpB = M.TpB;
% NB = M.NB;
% reshape actions and outcomes by block
% U_block = U{:};
% U_block = reshape(U_block,[TpB NB 2]);
% states_block = U_block(:,:,2);
% Y_block = Y{:};
% %Y_block = reshape(Y_block,TpB,NB);

U_block = U{:};
rewards_block = U_block(:,1);
states_block = U_block(:,2);
Y_block = Y{:};

L = 0;

task_rewards = zeros(2,160,4);
% choices the participant made
choices = zeros(1,160);
    
for trial = 1:160
    choices(trial) = Y_block(trial,1);
    task_rewards(choices(trial),trial, states_block(trial)) = rewards_block(trial);
end


    % solve MDP and accumulate log-likelihood
    %--------------------------------------------------------------------------
%     if mdp.RL == true
%         if mdp.assoc == true 
%             MDP = associability_model_extended(mdp.parameters, task_rewards, choices);
%         elseif mdp.assoc == false
%             MDP = RW_model_extended(mdp.parameters, task_rewards, choices);
%         end
%         
%         
%         for j = 1:mdp.TpB
%               L = L + log(MDP.action_probabilities(j) + eps);
%         end
%         
%         for i = 1:length(MDP.action_probabilities) % Get probability of true actions for each tria
%             if MDP.P(MDP.choices(i),i) == max(MDP.P(:,i))
%                 acc(i) = 1;
%             else
%                 acc(i) = 0;
%             end
%        end
%           p_avg = sum(MDP.action_probabilities)/numel(MDP.action_probabilities);
%           acc_avg = (sum(acc)/length(MDP.action_probabilities))*100;
% %           fprintf('p_avg: %f \n',p_avg);
% %           fprintf('acc_avg: %f \n',acc_avg);
%     else
%         MDP  = spm_MDP_VB_X_eta2_FR(MDP);

    MDP = RW_model_extended_GNG(params, task_rewards, states_block, choices);


    
    for j = 1:160
              L = L + log(MDP.action_probabilities(j) + eps);
    end
%     for i = 1:numel(Y)
%         for j = 1:TpB
%              L = L + log(MDP.P(Y_block(j,idx_block),j) + eps);
%         end
%     end
    
            
%end

clear('MDP')
    

fprintf('LL: %f \n',L)





