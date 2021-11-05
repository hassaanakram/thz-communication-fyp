function [numberUE, positionsUE] = getUEPositions(lambda, xMax, yMax)
%% getUEPositions
numberUE = poissrnd(lambda);

% (x, y, tierIdx, BS Number, Bandwidth, Pr, SINR, DataRate)
positionsUE = [rand(numberUE, 1).*xMax, rand(numberUE, 1).*yMax, ...
               zeros(numberUE, 6)];
end

