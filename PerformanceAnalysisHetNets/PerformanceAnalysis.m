clc; close all; clear;
% DEFINE VARIABLES
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
    receivedPowers = zeros(numUE, 3); 
    % STEP 1: CALCULATE PATH LOSS FOR EACH TIER
    % MBS
        shadowing = random('Lognormal', 0, 5, numUE, 1);
        posMBS = positionStations('MBS');
        distance = getDistance(positionUE, posMBS);
        PL_MBS = pathLossMBS(fMBS, beta, distance, shadowing);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(1, numUE);
        gain = 0; % Assuming directional antenna gain for MBS: 0
        receivedPowers(:,1) = receivedPower(PtMBS, gain, fading, PL_MBS);

        % STEP 3: CHECK RECEIVED POWER AGAINST THRESHOLD
        %inRangeUE = positionUE(receivedPowerMBS >= Pr, :);
        %outOfRangeUE = positionUE(receivedPowerMBS < Pr, :);

        % Plotting
%         figure('Name', 'In Range and Out of Range UE');
%         scatter(inRangeUE(:,1), inRangeUE(:,2), 'gd');
%         hold on
%         scatter(outOfRangeUE(:,1), outOfRangeUE(:,2), 'rd');
%         hold on
%         scatter(posMBS(:,1), posMBS(:,2), 'ko');
%         hold off
%         legend('In Range', 'Out of Range', 'MBS');
    
    % SC
        posSC = positionStations('SC');
        distance = getDistance(positionUE, posSC);
        absorbtion = pathLossSCAbsorbtion(distance);
        spread = pathLossSCSpread(fTHz,distance);
        PL_SC = pathLossSC(absorbtion,spread);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(1, numUE);
        gain = 25; % Assuming directional antenna gain to be 25 (dBm)
        receivedPowers(:,2) = receivedPower(PtSC, gain, fading, PL_SC);

        % STEP 3: CHECK RECEIVED POWER AGAINST THRESHOLD
        %inRangeUE_SC = positionUE(receivedPowerSC >= Pr, :);
        %outOfRangeUE_SC = positionUE(receivedPowerSC < Pr, :);

        % Plotting
%         figure('Name', 'In Range and Out of Range UE');
%         scatter(inRangeUE_SC(:,1), inRangeUE_SC(:,2), 'gd');
%         hold on
%         scatter(outOfRangeUE_SC(:,1), outOfRangeUE_SC(:,2), 'rd');
%         hold on
%         scatter(posSC(:,1), posSC(:,2), 'ko');
%         hold off
%         legend('In Range', 'Out of Range', 'SC');
    % UAV
        posUAV = positionStations('UAV');
        distance = getDistance(positionUE, posUAV);
        phiUAV = phiUAV(hUAV,distance);
        probabilityLOS_UAV = probabilityLOS_UAV(a,b,phiUAV);
        
        FSPL = fspl(fUAV,distance);
        pathLoss_LOS=5;
        pathLoss_NLOS=5;
        PL_UAV = pathLossUAV(FSPL,probabilityLOS_UAV,pathLoss_LOS,pathLoss_NLOS);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(1, numUE);
        gain = 20; % Assuming directional antenna gain to be 10 (dBm)
        receivedPowers(:,3) = receivedPower(PtMBS, gain, fading, PL_UAV(:,1));

        % STEP 3: CHECK RECEIVED POWER AGAINST THRESHOLD
        %inRangeUE_SC = positionUE(receivedPowerUAV >= Pr, :);
        %outOfRangeUE_SC = positionUE(receivedPowerUAV < Pr, :);

        % Plotting
%         figure('Name', 'In Range and Out of Range UE');
%         scatter(inRangeUE_SC(:,1), inRangeUE_SC(:,2), 'gd');
%         hold on
%         scatter(outOfRangeUE_SC(:,1), outOfRangeUE_SC(:,2), 'rd');
%         hold on
%         scatter(posSC(:,1), posSC(:,2), 'ko');
%         hold off
%         legend('In Range', 'Out of Range', 'UAV');

    %% GET MAX POWER AT EACH UE AND CORRESPONDING BS
    userBSAssociation = containers.Map;
    [bestPower, bestBS] = max(receivedPowers, [], 2);
    userBSAssociation('MBS') = positionUE(bestBS==1, :);
    userBSAssociation('SC') = positionUE(bestBS==2, :);
    userBSAssociation('UAV') = positionUE(bestBS==3, :);
    
    plotEquipment(userBSAssociation, 0);
    
end

% average = sum./iterations;
% out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\nUE: %f\n', average(1),...
%                                                                average(2),...
%                                                                average(3),...
%                                                                average(4));
% disp (out);