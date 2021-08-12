function [rate] = dataRate(alpha,bandwidth,users,SINR)
rate = ((alpha*bandwidth)/users)*log2(1+SINR);
end