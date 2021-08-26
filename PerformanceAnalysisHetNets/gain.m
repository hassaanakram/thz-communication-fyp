function [gain] = gain(y,omega)
gain = 10.*log10(y/(omega^2));
end

