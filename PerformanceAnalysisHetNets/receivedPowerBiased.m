function [receivedPowerBiased] = receivedPowerBiased(powerTransmitted,gain,fading,pathLoss,bias)
receivedPowerBiased = powerTransmitted + gain + fading - pathLoss + bias;
end
