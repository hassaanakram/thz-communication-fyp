function [pathLossSC] = pathLossSC(pathLossSC_spread,pathLossSC_absorbtion)
pathLossSC = pathLossSC_absorbtion + pathLossSC_spread;
end

