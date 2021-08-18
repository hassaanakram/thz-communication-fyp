clc; close all; clear;
%% Get and check Base station position distributions.
xMax =  1; yMax = 1;
iterations = 1;
sum = zeros(3,1);

for i=1:iterations
    [numStations, positionStations] = getBSPositions([1 20 3], xMax, yMax);
    out = sprintf('------Trial %d------\nMBSs: %d\nSCs: %d\nUAVs: %d\n',...
                                                   i,...
                                                   numStations('MBS'),...
                                                   numStations('SC'),...
                                                   numStations('UAV'));
    disp (out);                                         
    sum(1) = sum(1) + numStations('MBS');
    sum(2) = sum(2) + numStations('SC');
    sum(3) = sum(3) + numStations('UAV');
    
    
    % Plotting positions
    figure('Name', 'Positions of MBS')
    pos = positionStations('MBS');
    scatter(pos{1}, pos{2}, 'ro'); 

    figure('Name', 'Positions of SC')
    pos = positionStations('SC');
    scatter(pos{1}, pos{2}, 'k+'); 

    figure('Name', 'Positions of UAV')
    pos = positionStations('UAV');
    scatter(pos{1}, pos{2}, 'b*'); 
end

average = sum./iterations;
out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\n', average(1),...
                                                               average(2),...
                                                               average(3));
disp (out);