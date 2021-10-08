%% Clearing workspace
clc; close all; clear;

%% Defining system parametres
fMBS = 2.4E9; fTHz = 0.3E12; fmmWave = 73; % Hz
bMBS = 20E6; bTHz = 10E9; bmmWave = 2E9; % Hz
PtMBS = dBmTodB(40); PtTHz = dBmTodB(20); PtmmWave = dBmTodB(30); %dB
uLoS = 5; uNLoS = 1;
alphaN = 3.3; % mmWaveNLoS Path loss
alphaL = 2; % mmWaveLoS Path loss
alpha = 0.5; % UHF Path loss
p = 32.4 + 20*log10(fmmWave);
xMax = 1268; yMax = 1268;
area = xMax*yMax; % sq. metres
NF = 9; % dB
K = 200;
kF = 0.0033; % m^-1
beta = 3;

% Deployment densities
lambdaUE = 10; lambdaMBS = 4e-6; lambdaTHz = 40*lambdaMBS; 
lambdaMM = 20*lambdaMBS;
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
iterations = 300;
episodes = 8;

biasTHzRange = dBmTodB(linspace(10,50,episodes));
biasMMRange = dBmTodB(linspace(10,30,episodes));

associationsTierIter = zeros(iterations, 4);
associationsTier = zeros(episodes, 4);
bandwidthTier = zeros(3, 1);
SINRReceivedIter = cell(3, 1);
dataRatesIter = cell(3, 1);
SINRCoverage = zeros(episodes, 3);
dataRateCoverage = zeros(episodes, 3);

Pr = -130; % Receiver sensitivity dB (-100 dBm taken from my cellphone's status)
sinrTr = 1; % Watt;
drTr = [10^3, 10^4, 10^6];

for j = 1 : episodes
    biasTHz = biasTHzRange(j);
    biasmmWave = biasMMRange(j);
    for i = 1 : iterations
        fprintf('******Iteration - %d,j - %d******\n', i, j);
        SINRCoverageIter = cell(3, 1);
        dataRateCoverageIter = cell(3, 1);

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
        fprintf('Calculating Received powers\n');
        
        P_MBS = receivedPowerBiased(PtMBS, 0, nakagami(3, numUE),...
                                    L_MBS, 0);
        P_mmWaveLoS = receivedPowerBiased(PtmmWave, 10, nakagami(4, numUE),...
                                          L_mmWaveLoS, biasmmWave);
        P_mmWaveNLoS = receivedPowerBiased(PtmmWave, 10, nakagami(4, numUE),...
                                          L_mmWaveNLoS, biasmmWave);
        P_THz = receivedPowerBiased(PtTHz, 10, nakagami(5.2, numUE),...
                                    L_THz, biasTHz);

        % Step - 5: Check max received power per tier for each user
        fprintf('Calculating association matrix for this iteration\n');
        
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
        % Joining mmWave LoS and NLoS powers
        tier(tier == 3) = 2; tier(tier == 4) = 3;
        
        % All the users with less than the threshold received power are
        % assigned tier 4 (T1: MBS, T2: mmWave, T3: THz, T4: None)
        tier(maxPower < Pr) = 4;
        % associationsUser{i, :} = tier;
        
        % Calculate assoc. percentage per tier for each iteration
        mbsUE = sum(tier==1);
        percentage = mbsUE/numUE; % MBS
        associationsTierIter(i, 1) = percentage;
        
        mmWaveUE = sum(tier==2);
        percentage = mmWaveUE/numUE; % mmWave LoS/nLoS
        associationsTierIter(i, 2) = percentage;
        
        thzUE = sum(tier==3);
        percentage = thzUE/numUE; % THz
        associationsTierIter(i, 3) = percentage;
        clc;
        
        % Step - 7: Divide bandwidth
        bandwidthTier(1,:) = bMBS/mbsUE;
        bandwidthTier(2,:) = bmmWave/mmWaveUE;
        bandwidthTier(3,:) = bTHz/thzUE;
        
        % Step - 8: Calculate SINR
        %SINRReceivedIter = zeros(numUE, 1);
        %dataRatesIter = zeros(numUE, 1);
        
        for u = 1 : numUE
            tierUE = tier(u);
            if tierUE == 4 % Out of coverage
                continue;
            end
            
            % Noise
            noiseReceived = noise(bandwidthTier(tierUE, :), NF);
            % Powers at all UE except the current one (u)
            interferences = maxPower([1:u-1, u+1:end]);
            % Tiers of all UE except the current one
            tier_ = tier([1:u-1, u+1:end]);
            % Powers of all the UE except the current UE and having the
            % same tier.
            interferences = interferences(tier_ == tierUE);
            sinrCalc = SINR(maxPower(u),...
                                      interferences, noiseReceived);
            SINRReceivedIter{tierUE, :} = [SINRReceivedIter{tierUE,:}; sinrCalc];
            drCalc = dataRate(1, bandwidthTier(tierUE, :),...
                                       1, sinrCalc);
            dataRatesIter{tierUE, :} = [dataRatesIter{tierUE,:}; drCalc]; 
        end
        
        % Calculating SINR and DataRate coverage per tier against
        % thresholds
        for tierIdx = 1 : 3
            sinrTier = SINRReceivedIter{tierIdx, :};
            SINRCoverageIter{tierIdx, :} = [SINRCoverageIter{tierIdx,:};...
                              sum(sinrTier > sinrTr)/size(sinrTier,1)];
            drTier = dataRatesIter{tierIdx, :};
            dataRateCoverageIter{tierIdx, :} = [dataRateCoverageIter{tierIdx,:};...
                              sum(drTier > drTr(tierIdx))/size(drTier,1)];
        end
    end
    fprintf('Calculating the means over %d iters\n', iterations);
    associationsTier(j, :) = mean(associationsTierIter,1);
    for tierIdx = 1 : 3
            sinrTier = SINRCoverageIter{tierIdx, :};
            SINRCoverage(j, tierIdx) = mean(sinrTier, 1);
            drTier = dataRateCoverageIter{tierIdx, :};
            dataRateCoverage(j, tierIdx) = mean(drTier, 1);
    end
end

%for p = 1 : 10
    %subplot(10,1,p);
    figure('Name', 'Assoc');
    plot(1:8, associationsTier(:, 1),'b-',...
         1:8, associationsTier(:, 2),'r-',...
         1:8, associationsTier(:, 3),'g-'...
         )
     legend(["MBS", "mmWave", "THz"]);
     figure('Name', 'SINR Converage');
     plot(1:8, SINRCoverage(:, 1),'b-',...
         1:8, SINRCoverage(:, 2),'r-',...
         1:8, SINRCoverage(:, 3),'g-'...
         )
     legend(["MBS", "mmWave" "THz"]);
     figure('Name', 'DR Coverage');
     plot(1:8, dataRateCoverage(:, 1),'b-',...
         1:8, dataRateCoverage(:, 2),'r-',...
         1:8, dataRateCoverage(:, 3),'g-'...
         )
     legend(["MBS", "mmWave", "THz"]);
%end