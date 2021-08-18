clc; close all; clear;
%% Get and check Base station position distributions.
iterations = 1;
sum = zeros(4,1);

% DEFINING PARAMETRES
fMBS = 2.4E9; fUAV = 2.4E9; fTHF = 0.3E12; % Hz
bMBS = 20E6; bUAV = 20E6; bSC = 10E9; % Hz
PtMBS = 40; PtUAV = 30; PtSC = 20; % dBM
b = 0.11; a = 9;
uLoS = 5; uNLoS = 1;
Area = 250000; % squared metres
xMax = 500; yMax = 500;
NF = 9; % dB
K = 200;
alpha = 0.5;
beta = 3;
hUAV = 30; % UAV Height in metres
kF = 0.0033; % m^-1
lambdaUE = 87;

for i=1:iterations
    % Get Base Stations and UEs
    [numStations, positionStations] = getBSPositions([1 20 3], xMax, yMax);
    [numUE, positionUE] = getUEPositions(lambdaUE, xMax, yMax);
    out = sprintf('------Trial %d------\nUE: %d\nMBSs: %d\nSCs: %d\nUAVs: %d\n',...
                                                   i,...
                                                   numUE,...
                                                   numStations('MBS'),...
                                                   numStations('SC'),...
                                                   numStations('UAV'));
    disp (out);  
    
    sum(1) = sum(1) + numStations('MBS');
    sum(2) = sum(2) + numStations('SC');
    sum(3) = sum(3) + numStations('UAV');
    sum(4) = sum(4) + numUE;

    
    %Plotting positions
    figure('Name', 'Positions of MBS, SC, UAV, and UE')
    posMBS = positionStations('MBS');
    scatter(posMBS{1}, posMBS{2}, 'ro'); 
    hold on;
    posSC = positionStations('SC');
    scatter(posSC{1}, posSC{2}, 'k+'); 
    hold on;
    posUAV = positionStations('UAV');
    scatter(posUAV{1}, posUAV{2}, 'b*'); 
    hold on;
    scatter(positionUE(:,1), positionUE(:,2), 'md'); 
    legend('MBS', 'SC', 'UAV', 'UE');
    
    % Calculating Effective Rate coverage
    
end

average = sum./iterations;
out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\nUE: %f\n', average(1),...
                                                               average(2),...
                                                               average(3),...
                                                               average(4));
disp (out);
