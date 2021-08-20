clc; close all; clear;
%% Get and check Base station position distributions.
iterations = 1;
sum = zeros(4,1);

% DEFINING PARAMETRES
fMBS = 2.4E9; fUAV = 2.4E9; fTHz = 0.3E12; % Hz
bMBS = 20E6; bUAV = 20E6; bSC = 10E9; % Hz
PtMBS = 40; PtUAV = 30; PtSC = 20; Pr = 1; % dBM
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
    [numStations, positionStations] = getBSPositions(["MBS","SC","UAV"],...
                                                    [2,40,50], xMax, yMax);
    [numUE, positionUE] = getUEPositions(lambdaUE, xMax, yMax);
    
    out = sprintf('------Trial %d------\nUE: %d\nMBSs: %d\nSCs: %d\nUAVs: %d\n',...
                                                   i,...
                                                   numUE,...
                                                   numStations('MBS'),numStations('SC'),numStations('UAV'));
                                                   
    disp (out);  
    
    sum(1) = sum(1) + numStations('MBS');
    sum(2) = sum(2) + numStations('SC');
    sum(3) = sum(3) + numStations('UAV');
    sum(2) = sum(2) + numUE;

    
    %Plotting positions
    plotEquipment(positionStations, 0);
    
    %% TARGET: GET THE USERS WHO ARE WITHIN COVERAGE
    % STEP 1: CALCULATE PATH LOSS FOR EACH TIER
    % MBS
        shadowing = random('Lognormal', 0, 5, numUE, 1);
        posMBS = cell2mat(positionStations('MBS'));
        distance = getDistance(positionUE, posMBS);
        PL_MBS = pathLossMBS(fMBS, beta, distance, shadowing);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(1, numUE);
        gain = 1000; % Assuming directional antenna gain to be 10 (dBm)
        receivedPowerMBS = receivedPower(PtMBS, 0, 0, PL_MBS);

        % STEP 3: CHECK RECEIVED POWER AGAINST THRESHOLD
        inRangeUE = positionUE(receivedPowerMBS >= Pr, :);
        outOfRangeUE = positionUE(receivedPowerMBS < Pr, :);

        % Plotting
        figure('Name', 'In Range and Out of Range UE');
        scatter(inRangeUE(:,1), inRangeUE(:,2), 'gd');
        hold on
        scatter(outOfRangeUE(:,1), outOfRangeUE(:,2), 'rd');
        hold on
        scatter(posMBS(:,1), posMBS(:,2), 'ko');
        hold off
        legend('In Range', 'Out of Range', 'MBS');
    
    % SC
        posSC = cell2mat(positionStations('SC'));
        distance = getDistance(positionUE, posSC);
        absorbtion = pathLossSCAbsorbtion(distance);
        spread = pathLossSCSpread(fTHz,distance);
        PL_SC = pathLossSC(absorbtion,spread);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(1, numUE);
        gain = 1000; % Assuming directional antenna gain to be 10 (dBm)
        receivedPowerSC = receivedPower(PtMBS, gain, fading, PL_SC);

        % STEP 3: CHECK RECEIVED POWER AGAINST THRESHOLD
        inRangeUE_SC = positionUE(receivedPowerSC >= Pr, :);
        outOfRangeUE_SC = positionUE(receivedPowerSC < Pr, :);

        % Plotting
        figure('Name', 'In Range and Out of Range UE');
        scatter(inRangeUE_SC(:,1), inRangeUE_SC(:,2), 'gd');
        hold on
        scatter(outOfRangeUE_SC(:,1), outOfRangeUE_SC(:,2), 'rd');
        hold on
        scatter(posSC(:,1), posSC(:,2), 'ko');
        hold off
        legend('In Range', 'Out of Range', 'SC');
    %% CALCULATING DATARATE AT EACH IN RANGE UE
    
end

% average = sum./iterations;
% out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\nUE: %f\n', average(1),...
%                                                                average(2),...
%                                                                average(3),...
%                                                                average(4));
% disp (out);