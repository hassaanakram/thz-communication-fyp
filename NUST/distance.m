function [distance] = distance(x1,y1,x2,y2)
if isempty(x2)
    distance(1:length(x1),1) = 6000;
    return ;
else
    for i=1:length(x2)
    distance = sqrt((x1-x2(i)).^2+(y1-y2(i)).^2);
    end
end

