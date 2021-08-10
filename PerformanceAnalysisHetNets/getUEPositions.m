function [positionsUE] = getUEPositions(number, xMax, yMax)
%% getUEPositions
positionsUE = [rand(number, 1).*xMax, rand(number, 1).*yMax];
end

