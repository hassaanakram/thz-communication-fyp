function [noisePower] = noise(B, NF)
noisePower = -174 + 10.*log10(B) + NF;
end

