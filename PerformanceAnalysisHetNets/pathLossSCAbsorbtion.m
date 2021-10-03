function [pathLossSCAbsorbtion] = pathLossSCAbsorbtion(d)
numUE = size(d, 1);
pathLossSCAbsorbtion = cell(numUE, 1);

for i = 1 : numUE
    pathLossSCAbsorbtion{i} = 10.*log10(exp(0.0033*d{i}));
end
end

