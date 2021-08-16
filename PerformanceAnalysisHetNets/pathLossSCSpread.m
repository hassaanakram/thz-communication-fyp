function [pathLossSCSpread] = pathLossSCSpread(freq,d)
c=3*10^8;
pathLossSCSpread = 20*log((4*pi*freq*d)/c);
end

