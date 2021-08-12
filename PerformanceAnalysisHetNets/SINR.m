function [SINR] = SINR(powerReceived,interference,noise)
sumInterferences = sum(interference,[1,1000]);
SINR = powerReceived / (sumInterferences + noise^2);
end

