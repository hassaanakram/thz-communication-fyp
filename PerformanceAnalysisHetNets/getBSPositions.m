function [numberStations, positionStations] = getBSPositions(types, lambdas,xMax, yMax)
%% BASE STATION DISTRIBUTION. INPUT PARAMETRES
% types: A vector of strings with names of equipment types
% lambdas: Corresponding mean values for each type of equipment
% xMax, yMax: Maximum area bounds

if (length(types) ~= length(lambdas))
    disp ("NUMBER OF TYPES MUST MATCH PROVIDED AVERAGES");
    numberStations = 0; positionStations = 0;
    return
end
% Number of various tier base stations
numberStations = containers.Map;
for i = 1:length(types)
    numberStations(types(i)) = poissrnd(lambdas(i));
end
% Random coordinates of stations. Using cartesian coordinates.
% x will be sampled between [0, xMax] and y between [0, yMax]
positionStations = containers.Map;
for i = 1:length(types)
positionStations(types(i)) = {rand(numberStations(types(i)), 1)*xMax,...
                           rand(numberStations(types(i)), 1)*yMax};
end
end

