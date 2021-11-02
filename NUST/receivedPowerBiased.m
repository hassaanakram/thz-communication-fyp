function [receivedPowerBiased] = receivedPowerBiased(powerTransmitted,gain,fading,pathLoss,bias)
if iscell(pathLoss)
    % for thz yikes
    numUE = size(pathLoss, 1);
    %receivedPowerBiased = zeros(numUE, 1);
    for i = 1 : numUE
        receivedPowerBiased{i} = powerTransmitted + gain + fading(i) - pathLoss{i} + bias;
    end
    return
end
receivedPowerBiased = powerTransmitted + gain + fading - pathLoss + bias;
end
