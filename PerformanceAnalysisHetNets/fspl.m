function [fspl] = fspl(freq,x)
c=3*10^8;
fspl=20*log((4*pi*freq*x)/c);
end

