function [numUserMBS,numUserSC,numUserUAV] = divideUser(numUser,asMBS,asSC,asUAV)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
numUserMBS = asMBS .* numUser;
numUserSC = asSC .* numUser;
numUserUAV = asUAV .* numUser;
end

