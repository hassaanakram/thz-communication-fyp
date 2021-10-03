function [PL] = pathLossmmWave(p,...
                               alpha,...
                               distance,...
                               shadow)
numUE = size(distance, 1);
PL = cell(numUE, 1);
for i = 1 : numUE
    PL{i} = p + 10.*alpha.*log10(distance{i}) + shadow(i);
end
end

