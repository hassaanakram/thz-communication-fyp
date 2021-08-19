function [distance] = getDistance(posUE, posBS)
% First check if any MBS is present
if isempty(posBS)
    distance = ones(size(posUE, 1),1).*60000;
    return
end
for i = 1:1:size(posBS, 1)
    distance = sqrt( (posUE(:,1)-posBS(i,1)).^2 +...
                     (posUE(:,2)-posBS(i,2)).^2);
end
end

