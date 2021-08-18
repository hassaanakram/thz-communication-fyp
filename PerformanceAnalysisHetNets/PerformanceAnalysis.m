clc; close all; clear;
%% Get and check Base station position distributions.
xMax =  1; yMax = 1;
iterations = 2;
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
    
    
    %Plotting positions
    figure('Name', 'Positions of MBS, SC, UAV')
    pos_MBS = positionStations('MBS');
    scatter(pos_MBS{1}, pos_MBS{2}, 'ro'); 
    hold on;
    pos_SC = positionStations('SC');
    scatter(pos_SC{1}, pos_SC{2}, 'k+'); 
    hold on;
    pos_UAV = positionStations('UAV');
    scatter(pos_UAV{1}, pos_UAV{2}, 'b*'); 
end

average = sum./iterations;
out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\n', average(1),...
                                                               average(2),...
                                                               average(3));
disp (out);