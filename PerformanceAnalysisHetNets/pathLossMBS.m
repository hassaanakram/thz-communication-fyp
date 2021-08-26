function [PL] = pathLossMBS(freqMBS,beta,d,shadow)
c=3*10^8;
PL = 10.*log10((4*pi*freqMBS)/c)+10*beta*log10(d)+shadow;
end

