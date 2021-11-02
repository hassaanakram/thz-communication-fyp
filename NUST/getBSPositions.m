function [numberStations, positionStations] = getBSPositions(tiers, lambdas,xMax, yMax)
%% BASE STATION DISTRIBUTION. INPUT PARAMETRES
% types: A vector of strings with names of equipment types
% lambdas: Corresponding mean values for each type of equipment
% xMax, yMax: Maximum area bounds

if (length(tiers) ~= length(lambdas))
    disp ("NUMBER OF TYPES MUST MATCH PROVIDED AVERAGES");
    numberStations = 0; positionStations = 0;
    return
end
% Number of various tier base stations
numberStations = containers.Map;
for i = 1:length(tiers)
    tier = convertStringsToChars(tiers(i));
    numberStations(tier) = poissrnd(lambdas(i)*(xMax*yMax));
end
% Random coordinates of stations. Using cartesian coordinates.
% x will be sampled between [0, xMax] and y between [0, yMax]
positionStations = containers.Map;
for i = 1:length(tiers)
    tier = convertStringsToChars(tiers(i));
    positionStations(tier) = [rand(numberStations(tier), 1)*xMax,...
                           rand(numberStations(tier), 1)*yMax];
end
end

