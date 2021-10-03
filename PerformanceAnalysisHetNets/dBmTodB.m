function [dB] = dBmTodB(dBm)
watts = (10.^(dBm./10))/1000;
dB = 10.*log10(watts);
end

