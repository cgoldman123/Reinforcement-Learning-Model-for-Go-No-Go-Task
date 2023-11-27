function [outcomes, gen_choices] = GNG_sim(gen_params)

    
    % Read in states from subject AA111 game
    load('states_block.mat');
    game_rewards = NaN;
    choices = NaN;
    MDP = RW_model_extended_GNG(gen_params, game_rewards, states_block, choices);
    GNG_plot(MDP, states_block);
    
    outcomes(:,1) = MDP.observations;
    outcomes(:,2) = states_block;
    gen_choices = MDP.choices';
end