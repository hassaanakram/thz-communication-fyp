function [rate] = dataRate(alpha, bandwidth, users, SINR)
%k = (1*bandwidth)/users;
rate = bandwidth.*log2(1+SINR);
end