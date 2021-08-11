function [PL] = pathLossMBS(freqMBS,beta,d,shadow)
c=3*10^8;
PL=20*log((4*pi*freqMBS)/c)+10*beta*log(d)+shadow;
end

