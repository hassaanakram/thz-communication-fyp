function [g] = nakagami(mu, numUE)
%% RETURNS NAKAGAMI FADING FOR EACH USER. 
%g = makedist('Nakagami','mu',mu,'omega',1);
g = random('Nakagami', mu, 1, numUE,1);
end

