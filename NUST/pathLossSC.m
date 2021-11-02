function [pathLossSC] = pathLossSC(pathLossSC_spread,pathLossSC_absorbtion)
numUE = size(pathLossSC_spread, 1);
pathLossSC = cell(numUE, 1);

for i = 1 : numUE
    pathLossSC{i} = pathLossSC_absorbtion{i} + pathLossSC_spread{i};
end
end

