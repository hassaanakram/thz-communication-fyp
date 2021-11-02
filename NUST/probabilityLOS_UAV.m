function [probabilityLOS_UAV] = probabilityLOS_UAV(a,b,phiUAV)
probabilityLOS_UAV = 1 / (1+a*exp(-b.*(phiUAV-a)));
end