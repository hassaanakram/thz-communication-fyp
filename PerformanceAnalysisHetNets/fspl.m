function [fspl] = fspl(freq,x)
c=3*10^8;
fspl=10*log10((4*pi*freq*x)/c);
end

