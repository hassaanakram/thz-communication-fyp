function [pathLossSCAbsorbtion] = pathLossSCAbsorbtion(d)
numUE = size(d, 1);
pathLossSCAbsorbtion = cell(numUE, 1);

for i = 1 : numUE
    pathLossSCAbsorbtion{i} = 0.0033.*d{i}.*10.*log10(exp(1));
end
end

