function [distance] = getDistance(posUE, posBS)
% First check if any MBS is present
if isempty(posBS)
    distance = ones(size(posUE, 1),1).*60000;
    return
end

if iscell(posBS)
    numUE = size(posUE, 1);
    distance = cell(numUE, 1);

    for i = 1 : numUE
        distance{i} = getDistance(posUE(i,:), posBS{i});
    end
else
    distance = zeros(size(posUE, 1), size(posBS, 1));
    for i = 1:1:size(posBS, 1)
        distance(:, i) = sqrt( (posUE(:,1)-posBS(i,1)).^2 +...
                         (posUE(:,2)-posBS(i,2)).^2);
    end
end


end

