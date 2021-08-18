function [numberStations, positionStations] = getBSPositions(lambdas,xMax, yMax)
%% BASE STATION DISTRIBUTION. 
% We have three tiers: 1) MBS @ sub 6GHz, 2) SC BS, 3) UAV @ Sub 6GHz

% Poisson Intensity/rate of MBS, SC, UAV
lambda = containers.Map;
lambda('MBS') = lambdas(1); 
lambda('SC') = lambdas(2); 
lambda('UAV') = lambdas(3);

area = xMax*yMax;
% Number of various tier base stations
numberStations = containers.Map;
numberStations('MBS') = poissrnd(lambda('MBS'));
numberStations('SC') = poissrnd(lambda('SC'));
numberStations('UAV') = poissrnd(lambda('UAV'));

% Random coordinates of stations. Using cartesian coordinates.
% x will be sampled between [0, xMax] and y between [0, yMax]
positionStations = containers.Map;
positionStations('MBS') = {rand(numberStations('MBS'), 1)*xMax,...
                           rand(numberStations('MBS'), 1)*yMax};
positionStations('SC') = {rand(numberStations('SC'), 1)*xMax,...
                           rand(numberStations('SC'), 1)*yMax};
positionStations('UAV') = {rand(numberStations('UAV'), 1)*xMax,...
                           rand(numberStations('UAV'), 1)*yMax};
end

