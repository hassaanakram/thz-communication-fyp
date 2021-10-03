function [] = plotEquipment(dictPos, posBuilds, plotDifferent)
%% INPUT ARGS:
%  dictPos: Dictionary type object with positions of each type of BS or UE.
%           The function expects the positions of base stations/UE to be stored as
%           nx2 arrays against keys in the dictionary. It then converts each value
%           to array and plots. 
%  plotDifferent: Plots every element on same scatter plot if 0. Plots on
%                 different figures if 1.
%% RETURNS:
%  No output values.
%% IMPLEMENTATION
plotShapes = ["ko", "r*", "bx", "md", "g+", "ys", "c^"];
keys = dictPos.keys;
if plotDifferent
    for i = 1:size(dictPos, 1) 
        key = keys{i};
        figure('Name', key);
        pos = dictPos(key);
        scatter(pos(:,1), pos(:,2), plotShapes(i));
        hold on
        legend(key);
    end
else
    figure;
    for i = 1:size(posBuilds, 2)
        build = posBuilds{i};
        build = polyshape(build);
        plot(build);
        hold on
    end
    
    for i = 1:size(dictPos, 1)
        key = keys{i};
        
        pos = dictPos(key);
        if size(pos,2) ~= 2
            continue
        end
        scatter(pos(:,1), pos(:,2), plotShapes(i), 'LineWidth', 0.1);
        hold on
    end
%     legend(keys);
end

hold off
end

