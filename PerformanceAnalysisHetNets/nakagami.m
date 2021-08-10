function [g] = nakagami(mu)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
g=makedist('Nakagami','mu',mu,'omega',1);
g
end

