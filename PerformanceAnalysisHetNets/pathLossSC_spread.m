function [pathLossSC_spread] = pathLossSC_spread(freq,d)
c=3*10^8;
pathLossSC_spread = 20*log((4*pi*freq*d)/c);
end

