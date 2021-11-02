function [distance] = getDistanceTHz(BS, posUE)
numUE = size(posUE, 1);
distance = cell(numUE, 1);

for i = 1 : numUE
    distance{i} = getDistance(posUE(i,:), BS{i});
end
end

