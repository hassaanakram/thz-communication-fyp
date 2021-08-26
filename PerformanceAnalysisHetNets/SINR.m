function [SINR] = SINR(powerReceived,interference,noise)
interference = dBtoWatts(interference);
powerReceived = dBtoWatts(powerReceived);
noise = dBtoWatts(noise);
sumInterferences = sum(interference, 'all');
SINR = powerReceived./(sumInterferences + noise.^2);
%SINR = 10.*log10(SINR);
end

