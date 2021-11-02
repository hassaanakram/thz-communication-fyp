function [numberUE, positionsUE] = getUEPositions(lambda, xMax, yMax)
%% getUEPositions
numberUE = poissrnd(lambda);
positionsUE = [rand(numberUE, 1).*xMax, rand(numberUE, 1).*yMax];
end

