% Carter Goldman, 2023
dbstop if error
% Go / No Go fitting script
rng('shuffle');
clear all

if ispc
    root = 'L:';
    subject = 'AD108';
    result_dir = [root '/rsmith/lab-members/cgoldman/go_no_go/fits'];
    input_dir = [root '\rsmith\lab-members\cgoldman\go_no_go\COBRE_GNGB_data'];
elseif isunix
    root='/media/labs'; 
    subject = getenv('SUBJECT');
    result_dir = getenv('RESULTS');
    input_dir = getenv('INPUT_DIRECTORY');
end

addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);




SIM = false; % Generate simulated behavior (if false and FIT == true, will fit to subject file data instead)
FIT = true; % Fit example subject data 'BBBBB' or fit simulated behavior (if SIM == true)
PLOT = true; % plot actual or simulated data




% learning rate for punishment context (scales prediction error term)
priors.alpha_loss = .6;
% learning rate for rewarding context (scales prediction error term)
priors.alpha_win = .6;
% win sensitivity (scales a win before subtracting by previous weight)
priors.rs = 1;
% loss sensitivity (scales a loss before subtracting by previous weight)
priors.la = 1;
% pavlovian factor for punishment contexts
priors.pi_loss = .5;
% pavlovian factor for rewarding contexts
priors.pi_win = .5;
% noise (complete noise is 1, no noise is 0)
priors.zeta = .1;
% bias toward go
priors.beta = .2;

field = {'alpha_win' 'alpha_loss', 'rs', 'la', 'pi_loss', 'pi_win', 'zeta', 'beta'}; % Parameter field

if SIM
        
        gen_params.alpha_loss = .6;
        gen_params.alpha_win = .6;
        gen_params.rs = 1;
        gen_params.la = 1;
        gen_params.pi_win = 1;
        gen_params.pi_loss = 1;
        gen_params.zeta = .1;
        gen_params.beta = .1;
        [outcomes, gen_choices] = GNG_sim(gen_params);
        if FIT
            fit_results = GNG_sim_fit(priors,gen_choices,outcomes,field);
        end
else
    if FIT
        
        fit_results = GNG_fit(subject, input_dir, field, priors, PLOT);
        results.subject = subject;
        fieldNames = fieldnames(fit_results.posterior);
        % Loop over each field name and copy the value to res
        for i = 1:length(fieldNames)
            fieldName = fieldNames{i};
            results.(strcat(fieldName,"_posterior")) = fit_results.posterior.(fieldName);
            results.(strcat(fieldName,"_prior")) = fit_results.prior.(fieldName);
        end
        results.model_acc = fit_results.model_acc;
        results.avg_action_prob = fit_results.avg_action_prob;

        
        save(fullfile([result_dir '/fit_results_' subject '.mat']), 'fit_results');
        
        writetable(struct2table(results), [result_dir '/fit_' subject '.csv']);
    end
end
    



