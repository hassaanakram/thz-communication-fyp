clc; close all; clear;
% DEFINE VARIABLES
iterations = 300;
rateCoverage = zeros(iterations, 1);
sum = zeros(4,1);

% DEFINING PARAMETRES
fMBS = 2.4E9; fUAV = 2.4E9; fTHz = 0.3E12; % Hz
bMBS = 20E6; bUAV = 20E6; bSC = 10E9; % Hz
PtMBS = dBmTodB(40); PtUAV = dBmTodB(30); PtSC = dBmTodB(20); Pr = 1; % dB
b = 0.11; a = 9;
uLoS = 5; uNLoS = 1;
alphaN = 3.3; alphaL = 2;
Area = 25000; % squared metres
xMax = 500; yMax = 500;
NF = 9; % dB
K = 200;
alphaRange = linspace(0,1,iterations); 
rateRange = linspace(1E0, 1E9, iterations);
beta = 3;
hUAVRange = linspace(10,40,iterations); % UAV Height in metres
kF = 0.0033; % m^-1
lambdaUE = 87;

% Get Base Stations and UEs
[numStations, positionStations] = getBSPositions(["MBS","SC","UAV"],...
                                                    [100,13000,1500], xMax, yMax);
[numUE, positionUE] = getUEPositions(lambdaUE, xMax, yMax);

out = sprintf('------Trial %d------\nUE: %d\nMBSs: %d\nSCs: %d\nUAVs: %d\n',...
                                                i,...
                                                numUE,...
                                                numStations('MBS'),numStations('SC'),numStations('UAV'));
disp (out);
for i=1:iterations
    % Set sim params
    hUAV =30; alpha = 0.5;
    rateThreshold = rateRange(i);
    
    %Plotting positions
    %plotEquipment(positionStations, 0);

    %% TARGET: GET THE USERS WHO ARE WITHIN COVERAGE
    receivedPowers = zeros(numUE, 3); 
    % STEP 1: CALCULATE PATH LOSS FOR EACH TIER
    % MBS
        shadowing = 10.*log10(random('Lognormal', 0, 5, numUE, 1));
        posMBS = positionStations('MBS');
        distance = getDistance(positionUE, posMBS);
        PL_MBS = pathLossMBS(fMBS, beta, distance, shadowing);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(uNLoS, numUE); % to convert to dBm
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
        fading = nakagami(uLoS, numUE);
        gain = dBmTodB(40); % Assuming directional antenna gain to be 40 (dBm)
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
        phiUAV_val = phiUAV(hUAV,distance);
        probabilityLoSUAV = probabilityLOS_UAV(a,b,phiUAV_val);
        
        FSPL = fspl(fUAV,distance);
        pathLoss_LOS = 10.*alphaL.*log10(distance);
        pathLoss_NLOS = 10.*alphaN*log10(distance);
        PL_UAV = pathLossUAV(FSPL,probabilityLoSUAV,pathLoss_LOS,pathLoss_NLOS);

        % STEP 2: GET RECEIVED POWER AT EACH UE
        fading = nakagami(uNLoS, numUE);
        gain = dBmTodB(40); % Assuming directional antenna gain to be 20 (dBm)
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
    userBSAssociation('UE-MBS') = positionUE(bestBS==1, :);
    userBSAssociation('UE-SC') = positionUE(bestBS==2, :);
    userBSAssociation('UE-UAV') = positionUE(bestBS==3, :);
    userBSAssociation('MBS') = positionStations('MBS');
    userBSAssociation('SC') = positionStations('SC');
    userBSAssociation('UAV') = positionStations('UAV');
    
    assocRatio = containers.Map;
    assocRatio('MBS') = size(userBSAssociation('UE-MBS'),1)/numUE;
    assocRatio('SC') = size(userBSAssociation('UE-SC'),1)/numUE;
    assocRatio('UAV') = size(userBSAssociation('UE-UAV'),1)/numUE;
    
    out = sprintf('\n-----Association Ratio @ hUAV: %f\talpha: %f------\nMBS: %f\nSC: %f\nUAV: %f\nUE: %f\n',...
                                                          hUAV,...
                                                          alpha,...
                                                          assocRatio('MBS'),...
                                                          assocRatio('SC'),...
                                                          assocRatio('UAV'),...
                                                          numUE);
    disp (out);                   
    %plotEquipment(userBSAssociation, 0);
    
    %% RATE COVERAGE VS RATE THRESHOLD
    noisePower = containers.Map;
    observedSINR = zeros(numUE, 3);
    dataRates = zeros(numUE, 3);
    
    noisePower('MBS-UE') = noise(bMBS, NF);
    noisePower('SC-UE') = noise(bSC, NF);
    noisePower('UAV-UE') = noise(bUAV, NF);
    
    % Get SINR
    for j = 1:1:numUE
        observedSINR(j,1) = SINR(receivedPowers(j,1), ...
                                      receivedPowers([1:j-1 j+1:end],[1,3]),...
                                      noisePower('MBS-UE'));
                                  
        observedSINR(j,2) = SINR(receivedPowers(j,2), ...
                                      receivedPowers([1:j-1 j+1:end],2),...
                                      noisePower('SC-UE'));
                                  
        observedSINR(j,3) = SINR(receivedPowers(j,3), ...
                                      receivedPowers([1:j-1 j+1:end],[1,3]),...
                                      noisePower('UAV-UE'));                          
    end
    
    % Get Data Rate
    numAssocUE = size(userBSAssociation('UE-MBS'), 1);
    if numAssocUE > 0
        dataRates(:,1) = dataRate(alpha, bMBS, numAssocUE, observedSINR(:,1));
    end
    numAssocUE = size(userBSAssociation('UE-SC'), 1);
    if numAssocUE > 0
        dataRates(:,2) = dataRate(alpha, bSC, numAssocUE, observedSINR(:,2));
    end
    numAssocUE = size(userBSAssociation('UE-UAV'), 1);
    if numAssocUE > 0
        dataRates(:,3) = dataRate(alpha, bUAV, numAssocUE, observedSINR(:,3));
    end
    
    % Get Data Rate coverage
    dataRates = reshape(dataRates, size(dataRates,1)*3,1);
    rateCoverage(i) = (length(dataRates(dataRates>=i))/...
                    length(dataRates));
%     ratesBS = dataRates(:,1);
%     rateCoverage(i,1) = (length(ratesBS(ratesBS >= rateThreshold)))...
%                           /length(ratesBS);
%     
%     ratesBS = dataRates(:,2);
%     rateCoverage(i,2) = (length(ratesBS(ratesBS >= rateThreshold)))...
%                           /length(ratesBS);    
%                       
%     ratesBS = dataRates(:,3);
%     rateCoverage(i,3) = (length(ratesBS(ratesBS >= rateThreshold)))...
%                           /length(ratesBS);                  
                      
end

figure('Name', 'Rate Coverage');
plot(rateRange, rateCoverage, 'b-');
%hold on
%plot(rateRange, rateCoverage(:,2), 'r-');
%hold on
%plot(rateRange, rateCoverage(:,3), 'k-');
%hold off
% average = sum./iterations;
% out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\nUE: %f\n', average(1),...
%                                                                average(2),...
%                                                                average(3),...
%                                                                average(4));
% disp (out);