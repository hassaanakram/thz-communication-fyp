function [pathLossSCSpread] = pathLossSCSpread(freq,d)
c=3*10^8;
pathLossSCSpread = 10*log10((4*pi*freq*d)/c);
end

