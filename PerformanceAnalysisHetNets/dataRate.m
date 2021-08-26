function [rate] = dataRate(alpha, bandwidth, users, SINR)
k = (alpha*bandwidth)/users;
rate = k.*log2(1.+SINR);
end