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
        results.baseline_alpha_loss = fit_results{1,2}(1);
        results.baseline_alpha_win = fit_results{1,2}(2);
        results.baseline_rs = fit_results{1,2}(3);
        results.baseline_la = fit_results{1,2}(4);
        results.baseline_pi_loss = fit_results{1,2}(5);
        results.baseline_pi_win = fit_results{1,2}(6);
        results.baseline_zeta = fit_results{1,2}(7);
        results.baseline_beta = fit_results{1,2}(8);
        results.fit_alpha_loss = fit_results{1,3}(1);
        results.fit_alpha_win = fit_results{1,3}(2);
        results.fit_rs = fit_results{1,3}(3);
        results.fit_la = fit_results{1,3}(4);
        results.fit_pi_loss = fit_results{1,3}(5);
        results.fit_pi_win = fit_results{1,3}(6);
        results.fit_zeta = fit_results{1,3}(7);
        results.fit_beta = fit_results{1,3}(8);
        results.model_acc = fit_results{1,5};
        results.avg_action_prob = fit_results{1,6};

        
        save(fullfile([result_dir '/fit_results_' subject '.mat']), 'fit_results');
        
        writetable(struct2table(results), [result_dir '/fit_' subject '.csv']);
    end
end
    



