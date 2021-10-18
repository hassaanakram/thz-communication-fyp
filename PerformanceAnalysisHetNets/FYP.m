%% Clearing workspace
clc; close all; clear;

%% Defining system parametres
fMBS = 2.4E9; fTHz = 0.3E12; fmmWave = 73; % Hz
bMBS = 20E6; bTHz = 10E9; bmmWave = 2E9; % Hz
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
lambdaUE = 600; lambdaMBS = 4e-6;
%% Deploy the map
[numBuilds, positionBuilds] = getBuildingCoords('ththr', xMax, yMax);
% Deploy UE
[numUE, positionUE] = getUEPositions(lambdaUE, xMax, yMax);
        
fprintf('Number of UE: %d\n', numUE);
%% Simulation
clc; close;
iterations = 1e6;

% Various optimization parameters
episodesPowerTHz = 5;
episodesPowermmWave = 5; 
episodesBiasTHz = 10;
episodesBiasmmWave = 10;
episodesFactorTHz = 5;
episodesFactormmWave = 5;

factorTHzRange = 5 : 1/episodesFactorThz : 40;
factormmWaveRange = 5 : 1/episodesFactormmWave : 30;
powermmWaveRange = dBmTodB(linspace(20, 40, episodesPowermmWave));
powerTHzRange = dBmTodB(linspace(15, 30, episodesPowerTHz));
biasTHzRange = linspace(5,25,episodesBiasTHz);
biasMMRange = linspace(10,15,episodesBiasmmWave);

bandwidthTier = zeros(3, 1);

% Data structs to store mean results after iterations 

associationsTier = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         episodesBiasmmWave, episodesBiasTHz, 4);
                     
SINRCoverage = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         episodesBiasmmWave, episodesBiasTHz, 3);
                     
dataRateCoverage = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         episodesBiasmmWave, episodesBiasTHz, 3);
                     
rateByPower = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         episodesBiasmmWave, episodesBiasTHz, 1);
% Thresholds
Pr = -130; % Receiver sensitivity dB (-100 dBm taken from my cellphone's status)
sinrTr = 1; % Watt;
drTr = [10^3, 10^4, 10^8]; % bits per second

for counterFactormmWave = 1 : episodesFactormmWave
    factormmWave = factormmWaveRange(counterFactormmWave);
    lambdammWave = factormmWave * lambdaMBS;
    
    for counterFactorTHz = 1 : episodesFactorTHz
        factorTHz = factorTHzRange(counterFactorTHz);
        lambdaTHz = factorTHz * lambdaMBS;
        
        [numStations, positionStations] = getBSPositions(["MBS", "THz", "mmWave"]...
                                               , [lambdaMBS, lambdaTHz, lambdaMM],...
                                                 xMax, yMax);
                                             
        % Step - 2: Calculate LoS/NLoS probabilites for mmWave and THz
        fprintf('Calculating Probabilites\n');
        [probabilities, tHzBSLoS, mmWaveBSLoS, mmWaveBSNLoS] =...
                                      getProbabilities(positionStations,...
                                      positionUE,...
                                      positionBuilds,...
                                      numUE,...
                                      numStations,...
                                      numBuilds);
                                         
        for counterBiasmmWave = 1 : episodesBiasmmWave
            biasmmWave = biasmmWaveRange(counterBiasmmWave);
            
            for counterBiasTHz = 1 : episodesBiasTHz
                biasTHz = biasTHzRange(counterBiasTHz);
                
                for counterPmmWave = 1 : episodesPowermmWave
                    PtmmWave = powermmWaveRange(counterPmmWave);
                    
                    for counterPTHz = 1 : episodesPowerTHz
                        PtTHz = powerTHzRange(counterPTHz);
                        
                        % Random effects loop
                        for i = 1 : iterations
                            fprintf('******Iteration - %d,j - %d******\n', i, counterPTHz);
                            SINRReceivedIter = cell(3, 1);
                            dataRateIter = cell(3, 1);

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
                            P_mmWaveLoS = receivedPowerBiased(PtmmWave, 20, nakagami(4, numUE),...
                                                              L_mmWaveLoS, biasmmWave);
                            P_mmWaveNLoS = receivedPowerBiased(PtmmWave, 20, nakagami(4, numUE),...
                                                              L_mmWaveNLoS, biasmmWave);
                            P_THz = receivedPowerBiased(PtTHz, 24, nakagami(5.2, numUE),...
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
                                dataRateIter{tierUE, :} = [dataRateIter{tierUE,:}; drCalc]; 
                            end

                            % Calculating SINR and DataRate coverage per tier against
                            % thresholds
                            for tierIdx = 1 : 3
                                sinrTier = SINRReceivedIter{tierIdx, :};
                                SINRCoverageIter(i, tierIdx) = sum(sinrTier > sinrTr)/size(sinrTier,1);
                                drTier = dataRateIter{tierIdx, :};
                                dataRateCoverageIter(i, tierIdx) = sum(drTier > drTr(tierIdx))/size(drTier,1);
                            end
                        end
                        fprintf('Calculating the means over %d iters\n', iterations);
                    
                        associationsTier(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         counterBiasmmWave, ...
                                         counterBiasTHz, :) = ...
                                         mean(associationsTierIter, 1);
                        assocTHz = associationsTier(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         counterBiasmmWave, ...
                                         counterBiasTHz, 3);
                                     
                        SINRCoverage(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         counterBiasmmWave, ...
                                         counterBiasTHz, :) = ...
                                         mean(SINRCoverageIter, 1);
                                     
                        dataRateCoverage(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         counterBiasmmWave, ...
                                         counterBiasTHz, :) = ...
                                         mean(dataRateCoverageIter, 1);
                                     
                        dataRateTHz = mean(dataRateIter{3});
                        powerTHzConsumed = numStations('THz') * PtTHz;
                        dataRateTHz = dataRateTHz .* assocTHz;
                        
                        rateByPower(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         counterBiasmmWave, ...
                                         counterBiasTHz, :) = ...
                                         dataRateTHz ./ powerTHzConsumed;
                        
                        associationsTierIter = zeros(iterations, 4);
                        SINRCoverageIter = zeros(iterations, 3);
                        dataRateCoverageIter = zeros(iterations, 3);
                        
                    end
                end
            end
        end
    end
end

rateVSPower = rateByPower(1, 1, 1, :, 1, 1);
figure('Name', 'thz data rate vs thz power at specific lambdas, biases');
plot(powerTHzRange, rateVSPower);

% % Replacing all NaNs with 0 (NaNs arise due to a division by zero. In our
% % case this happens moslty when the number of UE associated with any tier
% % are zero. 
% associationsTier(isnan(associationsTier)) = 0;
% SINRCoverage(isnan(SINRCoverage)) = 0;
% dataRateCoverage(isnan(dataRateCoverage)) = 0;
% 
% figure('Name', 'Assoc');
% plot(1:8, associationsTier(:, 1),'b-',...
%      1:8, associationsTier(:, 2),'r-',...
%      1:8, associationsTier(:, 3),'g-'...
%      )
% legend(["MBS", "mmWave", "THz"]);
% figure('Name', 'SINR Converage');
% plot(1:8, SINRCoverage(:, 1),'b-',...
%      1:8, SINRCoverage(:, 2),'r-',...
%      1:8, SINRCoverage(:, 3),'g-'...
%      )
% legend(["MBS", "mmWave" "THz"]);
% figure('Name', 'DR Coverage');
% plot(1:8, dataRateCoverage(:, 1),'b-',...
%      1:8, dataRateCoverage(:, 2),'r-',...
%      1:8, dataRateCoverage(:, 3),'g-'...
%      )
% legend(["MBS", "mmWave", "THz"]);
% 
% figure('Name', 'Data Rate verses Power transmitted');
% plot(PtTHz,dataRateMeanThz)