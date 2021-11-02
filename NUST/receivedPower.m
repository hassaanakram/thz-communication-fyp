function [receivedPower] = receivedPower(powerTransmitted,gain,fading,pathLoss)
receivedPower = powerTransmitted + gain + fading - pathLoss;
end

