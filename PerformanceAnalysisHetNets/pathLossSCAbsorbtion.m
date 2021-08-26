function [pathLossSCAbsorbtion] = pathLossSCAbsorbtion(d)
pathLossSCAbsorbtion = 10.*log10(exp(0.0033*d));
end

