function [probabilityLOS_UAV] = probabilityLOS_UAV(a,b)
probabilityLOS_UAV = 1 / (1+a*exp(-b*(phiUAV-a)));
end