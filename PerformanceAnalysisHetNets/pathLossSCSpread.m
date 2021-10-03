function [pathLossSCSpread] = pathLossSCSpread(freq,d)
c=3*10^8;
numUE = size(d, 1);
pathLossSCSpread = cell(numUE, 1);
for i = 1 : numUE
    pathLossSCSpread{i} = 10*log10((4*pi*freq*d{i})/c);
end
end

