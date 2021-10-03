%% Clearing workspace
clc; close all; clear;

%% Defining system parametres
fMBS = 2.4E9; fTHz = 0.3E12; fmmWave = 73E9; % Hz
bMBS = 20E6; bTHz = 10E9; bmmWave = 2E9; % Hz
PtMBS = dBmTodB(40); PtTHz = dBmTodB(20); PtmmWave = dBmTodB(30); %dB
uLoS = 5; uNLoS = 1;
alphaN = 3.3; alphaL = 2; alpha = 0.5;
p = 32.4 + 20*log10(fmmWave);
xMax = 1526; yMax = 1526;
area = xMax*yMax; % sq. metres
NF = 9; % dB
K = 200;
kF = 0.0033; % m^-1
beta = 3;

% Deployment densities
lambdaUE = 50; lambdaMBS = 4e-6; lambdaTHz = 30*lambdaMBS; 
lambdaMM = 50*lambdaMBS;
%% Deploy the map
[numBuilds, positionBuilds] = getBuildingCoords('ththr', xMax, yMax);
% Step - 1: Deploy BS and UE
[numStations, positionStations] = getBSPositions(["MBS", "THz", "mmWave"]...
                                               , [lambdaMBS, lambdaTHz, lambdaMM],...
                                                 xMax, yMax);
[numUE, positionUE] = getUEPositions(lambdaUE, xMax, yMax);
        
% Step - 2: Calculate LoS/NLoS probabilites for mmWave and THz
fprintf('Calculating Probabilites\n');
[probabilities, tHzBSLoS, mmWaveBSLoS, mmWaveBSNLoS] =...
                                             getProbabilities(positionStations,...
                                             positionUE,...
                                             positionBuilds,...
                                             numUE,...
                                             numStations,...
                                             numBuilds);
fprintf('MBS: %d\t mmWave: %d\tTHz: %d\n', numStations('MBS'), numStations('mmWave'), numStations('THz'));  
fprintf('Number of UE: %d\n', numUE);
%% Simulation
iterations =500;

biasTHzRange = dBmTodB(linspace(10,50,8));
biasMMRange = dBmTodB(linspace(150,300,8));
%receivedPowers = cell(iterations, 3);
% associationsUser = zeros(iterations, numUE);
associationsTierIter = zeros(iterations, 4);
associationsTier = zeros(8, 4);
% maxPowers = zeros(numUE, 3);
Pr = -130;

for j = 1 : 8
    biasTHz = 0%biasTHzRange(j);
    biasmmWave = biasMMRange(j);
    for i = 1 : iterations
        fprintf('******Iteration - %d,j - %d******\n', i, j);

        % Step - 3: Calculate PL for each tier.
        fprintf('Calculating Path Losses\n');
        
        % MBS
        shadowing = 10.*log10(random('Lognormal', 0, 4, numUE, 1));
        posBS = positionStations('MBS');
        distance = getDistance(positionUE, posBS);
        L_MBS = pathLossMBS(fMBS, beta, distance, shadowing);

        % mmWave
        %posBS = positionStations('mmWave');
        shadowL = 10.*log10(random('Lognormal', 0, 5.2, numUE, 1));
        shadowN = 10.*log10(random('Lognormal', 0, 7.2, numUE, 1));
        pLoS = probabilities(:, 1, 1);
        pNLoS = probabilities(:, 1, 2);
        distanceLoS = getDistance(positionUE, mmWaveBSLoS);
        distanceNLoS = getDistance(positionUE, mmWaveBSNLoS);
        L_mmWaveLoS = pathLossmmWave(p, alphaL, distanceLoS,...
                                     shadowL);
        L_mmWaveNLoS = pathLossmmWave(p, alphaN, distanceNLoS,...
                                     shadowN);                         

        % THz
        posBS = positionStations('THz');
        distance = getDistance(positionUE, tHzBSLoS);
        L_Spread = pathLossSCSpread(fTHz, distance);
        L_Absorption = pathLossSCAbsorbtion(distance);
        L_THz = pathLossSC(L_Spread, L_Absorption);

        % Step - 4: Calculate Received powers
        P_MBS = receivedPowerBiased(PtMBS, 0, nakagami(3, numUE),...
                                    L_MBS, 0);
        P_mmWaveLoS = receivedPowerBiased(PtmmWave, 10, nakagami(4, numUE),...
                                          L_mmWaveLoS, biasmmWave);
        P_mmWaveNLoS = receivedPowerBiased(PtmmWave, 10, nakagami(4, numUE),...
                                          L_mmWaveNLoS, biasmmWave);
        P_THz = receivedPowerBiased(PtTHz, 10, nakagami(5.2, numUE),...
                                    L_THz, biasTHz);

        %receivedPowers{i, 1} = P_MBS; 
        %receivedPowers{i, 2} = P_mmWave;
        %receivedPowers{i, 3} = P_THz;

        % Step - 5: Check max received power per tier for each user
        maxPowerMBS = max(P_MBS, [], 2);
        maxPowermmWaveLoS = zeros(numUE, 1);
        maxPowermmWaveNLoS = zeros(numUE, 1);
        maxPowerTHz = zeros(numUE, 1);

        for k = 1 : numUE
            maxPowerTHz(k) = max(P_THz{k}, [], 2);
            maxPowermmWaveLoS(k) = max(P_mmWaveLoS{k}, [], 2);
            maxPowermmWaveNLoS(k) = max(P_mmWaveNLoS{k}, [], 2);
        end
        
        maxPowers = [maxPowerMBS, maxPowermmWaveLoS, maxPowermmWaveNLoS, maxPowerTHz];
        % Step - 6: Based on the max power among all three tiers, associate
        % users to the best station
        [maxPower, tier] = max(maxPowers, [], 2);
        tier(maxPower < Pr) = 5;
        associationsUser{i, :} = tier;
        
        % Calculate assoc. percentage per tier for each iteration
        percentage = sum(associationsUser{i,:}==1)/numUE; % MBS
        associationsTierIter(i, 1) = percentage;
        percentage = sum(associationsUser{i,:}==2)/numUE; % mmWave LoS
        associationsTierIter(i, 2) = percentage;
        percentage = sum(associationsUser{i,:}==3)/numUE; % mmWave NLoS
        associationsTierIter(i, 3) = percentage;
        percentage = sum(associationsUser{i,:}==4)/numUE; % THz
        associationsTierIter(i, 4) = percentage;
        clc;
    end
    associationsTier(j, :) = mean(associationsTierIter,1);
end

%for p = 1 : 10
    %subplot(10,1,p);
    plot(1:8, associationsTier(:, 1),'b-',...
         1:8, associationsTier(:, 2),'r-',...
         1:8, associationsTier(:, 3),'g-',...
         1:8, associationsTier(:, 4), 'k-')
     legend(["MBS", "mmWaveLos", "mmWaveNLoS", "THz"]);
%end