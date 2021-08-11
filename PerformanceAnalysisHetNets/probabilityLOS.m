function [probabilityLOS] = probabilityLOS(a,b)
probabilityLOS = 1 / (1+a*exp(-b*(phiUAV-a)));
end