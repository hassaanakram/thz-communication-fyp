%% Clearing workspace
clc; close all; clear;

%% Defining system parametres
fMBS = 2.4E9; fTHz = 0.3E12; fmmWave = 73; % Hz
bMBS = 20E6; bTHz = 10E9; bmmWave = 2E9; % Hz
% Bandwidths array 
bandwidths = [bMBS, bmmWave, bTHz];
PtMBS = dBmTodB(30);
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
lambdaUE = 50; 
lambdaMBS = 2e-6;
%% Deploy the map
[numBuilds, positionBuilds] = getBuildingCoords('ththr', xMax, yMax, 3, 38, 39);
% Deploy UE
[numUE, dataUE] = getUEPositions(lambdaUE, xMax, yMax);

% tiers
tiers = ["MBS", "mmWave", "THz"];

fprintf('Number of UE: %d\n', numUE);
%% Simulation
clc; close;
iterations = 2;

% Various optimization parameters
episodesPowerTHz = 1;
episodesPowermmWave = 1; 
episodesBiasTHz = 1;
episodesBiasmmWave = 1;
episodesFactorTHz = 3;
episodesFactormmWave = 1;
sinrThresholdLevels = 1500;
drThresholdLevels = 1500;

factorTHzRange = linspace(2, 40, episodesFactorTHz);
factormmWaveRange = linspace(1, 20, episodesFactormmWave);
powermmWaveRange = dBmTodB(linspace(15, 35, episodesPowermmWave));
powerTHzRange = dBmTodB(linspace(25, 35, episodesPowerTHz));
sinrThreshold = logspace(-5, 1, sinrThresholdLevels);
drThreshold = logspace(3, 10, drThresholdLevels);
% biasTHzRange = linspace(5,25,episodesBiasTHz);
% biasmmWaveRange = linspace(5,25,episodesBiasmmWave);

bandwidthTier = zeros(3, 1);

% Data structs to store mean results after iterations 

associationsTier = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, 3);
                       % episodesBiasmmWave, episodesBiasTHz, 3);
                     
SINRCoverage = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         sinrThresholdLevels, 3);
                       % episodesBiasmmWave, episodesBiasTHz, 3);
                     
dataRateCoverage = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, ...
                         drThresholdLevels, 3);
                       % episodesBiasmmWave, episodesBiasTHz, 3);
                     
rateByPower = zeros(episodesFactormmWave, episodesFactorTHz, ...
                         episodesPowermmWave, episodesPowerTHz, 3);
                       % episodesBiasmmWave, episodesBiasTHz, 1);
% Thresholds
Pr = -130; % Receiver sensitivity dB (-100 dBm taken from my cellphone's status)
sinrTr = 1; % Watt;
drTr = [10^6, 10^8, 10^10]; % bits per second

for counterFactormmWave = 1 : episodesFactormmWave
    factormmWave = factormmWaveRange(counterFactormmWave);
    lambdammWave = factormmWave * lambdaMBS;
    
    for counterFactorTHz = 1 : episodesFactorTHz
        factorTHz = factorTHzRange(counterFactorTHz);
        lambdaTHz = factorTHz * lambdaMBS;
        
        [numStations, positionStations] = getBSPositions(["MBS", "THz", "mmWave"]...
                                               , [lambdaMBS, lambdaTHz, lambdammWave],...
                                                 xMax, yMax);
        
        % Step - 2: Calculate LoS/NLoS probabilites for mmWave and THz
        fprintf('Calculating LoS/NLoS data\n');
        [probabilities, tHzBSLoS, mmWaveBSLoS, mmWaveBSNLoS] =...
                                      getProbabilities(positionStations,...
                                      dataUE,...
                                      positionBuilds,...
                                      numUE,...
                                      numStations,...
                                      numBuilds);
                                         
        for counterBiasmmWave = 1 : episodesBiasmmWave
            % biasmmWave = biasmmWaveRange(counterBiasmmWave);
            biasmmWave = 0;
            
            for counterBiasTHz = 1 : episodesBiasTHz
                % biasTHz = biasTHzRange(counterBiasTHz);
                biasTHz = 7;
                for counterPmmWave = 1 : episodesPowermmWave
                    PtmmWave = powermmWaveRange(counterPmmWave);
                    
                    for counterPTHz = 1 : episodesPowerTHz
                        PtTHz = powerTHzRange(counterPTHz);
                        fprintf('PTHz: %d\nPmmWave: %d\nBiasTHz: %d\nBiasMM: %d\nLambdaTHz: %d\nLambdaMM: %d\n'...
                                , counterPTHz, counterPmmWave, counterBiasTHz, counterBiasmmWave, counterFactorTHz, ...
                                counterFactormmWave);
                        % Random effects loop
                        for i = 1 : iterations
                            SINRReceivedIter = cell(3, 1);
                            dataRateIter = cell(3, 1);

                            % Step - 3: Calculate PL for each tier.

                            % MBS
                            shadowing = 10.*log10(random('Lognormal', 0, 4, numUE, 1));
                            posBS = positionStations('MBS');
                            distance = getDistance(dataUE, posBS);
                            L_MBS = pathLossMBS(fMBS, beta, distance, shadowing);

                            % mmWave
                            %posBS = positionStations('mmWave');
                            shadowL = 10.*log10(random('Lognormal', 0, 5.2, numUE, 1));
                            shadowN = 10.*log10(random('Lognormal', 0, 7.2, numUE, 1));
                            pLoS = probabilities(:, 1, 1);
                            pNLoS = probabilities(:, 1, 2);
                            distanceLoS = getDistance(dataUE, mmWaveBSLoS);
                            distanceNLoS = getDistance(dataUE, mmWaveBSNLoS);
                            L_mmWaveLoS = pathLossmmWave(p, alphaL, distanceLoS,...
                                                         shadowL);
                            L_mmWaveNLoS = pathLossmmWave(p, alphaN, distanceNLoS,...
                                                         shadowN);                         

                            % THz
                            posBS = positionStations('THz');
                            distance = getDistance(dataUE, tHzBSLoS);
                            L_Spread = pathLossSCSpread(fTHz, distance);
                            L_Absorption = pathLossSCAbsorbtion(distance);
                            L_THz = pathLossSC(L_Spread, L_Absorption);

                            % Step - 4: Calculate Received powers

                            P_MBS = receivedPowerBiased(PtMBS, 0, nakagami(3, numUE),...
                                                        L_MBS, 0);
                            P_mmWaveLoS = receivedPowerBiased(PtmmWave, 20, nakagami(4, numUE),...
                                                              L_mmWaveLoS, biasmmWave);
                            P_mmWaveNLoS = receivedPowerBiased(PtmmWave, 20, nakagami(4, numUE),...
                                                              L_mmWaveNLoS, biasmmWave);
                            P_THz = receivedPowerBiased(PtTHz, 24, nakagami(5.2, numUE),...
                                                        L_THz, biasTHz);
                            % Combined mmWave LoS and NLoS powers
                            for idx = 1 : numUE
                                P_mm{idx} = [P_mmWaveLoS{idx}, P_mmWaveNLoS{idx}];
                            end
                            receivedPowers = {P_MBS, P_mm, P_THz};
                            
                            % Step - 5: Check max received power per tier for each user
                            idxBestBSTier = zeros(numUE, 3);
                            
                            [maxPowerMBS, idxBestBSTier(:, 1)] = max(P_MBS, [], 2);
                            %maxPowermmWaveLoS = zeros(numUE, 1);
                            %maxPowermmWaveNLoS = zeros(numUE, 1);
                            maxPowermmWave = zeros(numUE, 1);
                            maxPowerTHz = zeros(numUE, 1);                
                            
                            for k = 1 : numUE
                                [maxPowerTHz(k), idxBestBSTier(k, 3)] = max(P_THz{k}, [], 2);
                                [maxPowermmWave(k), idxBestBSTier(k, 2)] ...
                                    = max(P_mm{k}, [], 2);
                                %[maxPowermmWaveLoS(k), idxBestBSTier(k, 2)] = ...
                                %                max(P_mmWaveLoS{k}, [], 2);
                                %[maxPowermmWaveNLoS(k), idxBestBSTier(k, 3)] = ...
                                %                max(P_mmWaveNLoS{k}, [], 2);
                                
                            end

                            %maxPowers = ...
                            %[maxPowerMBS, maxPowermmWaveLoS, maxPowermmWaveNLoS, maxPowerTHz];
                            maxPowers = [maxPowerMBS, maxPowermmWave, maxPowerTHz];
                            % Step - 6: Based on the max power among all three tiers, associate
                            % users to the best station
                            [dataUE(:, 6), tier] = max(maxPowers, [], 2);
                            
                            % Populate the userBSAssociation matrix
      
                            bsIdx = zeros(numUE, 1);
                            for idx = 1 : numUE
                                bsIdx(idx) = idxBestBSTier(idx, tier(idx));
                            end
                            % Joining mmWave LoS and NLoS powers
                            %tier(tier == 3) = 2; tier(tier == 4) = 3;
                            
                            % All the users with less than the threshold received power are
                            % assigned tier 4 (T1: MBS, T2: mmWave, T3: THz, T4: None)
                            tier(dataUE(:, 6) < Pr) = 4;
                            
                            dataUE(:, [3, 4]) = [tier, bsIdx];
                            
                            % Discard all UE that fall below threshold
                            % power
                            %dataUE = dataUE((dataUE(:, 3)~=4),:);
                            
%                             for idx = 1 : size(dataUE, 1)
%                                 userBSAssoc{dataUE(idx, 3)}(dataUE(idx, 4)) = ...
%                                     userBSAssoc{dataUE(idx, 3)}(dataUE(idx, 4)) + 1;
%                             end
                            % Dividing bandwidth per transmitting base
                            % station
                            %%
                            for idx = 1 : 3 
                                % Total bandwidth per base station/tier
                                bandwidthTier = bandwidths(idx);
                                % Vector of BS numbers of idx Tier
                                tierUE = dataUE(dataUE(:, 3)==idx ,4);
                                if tierUE == 4
                                    % Out of coverage
                                    continue;
                                end
                                % Get count of each element in this vect
                                count = unique(tierUE);
                                out = [count, histc(tierUE(:), count)];
                                % Divide bandwidth
                                divBands = [out, bandwidthTier./out(:,2)];
                                
                                for bsIdx = 1 : numel(count)
                                    bsNumber = count(bsIdx);
                                    dataUE(dataUE(:, 3)==idx&dataUE(:,4)==bsNumber, 5)...
                                        = divBands(divBands(:,1)==bsNumber, 3);
                                end
                            end
                            
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

                            % Step - 7: Divide bandwidth
                            %bands = bandwidths(dataUE(:, 3));
                            %numAssocUE = userBSAssoc{dataUE(:,3)}(dataUE(:,4));
                            %dataUE(:, 5) = bands./numAssocUE;

                            % Step - 8: Calculate SINR
                            for u = 1 : size(dataUE,1)
                                ue = dataUE(u, :);
                                %tierUE = tier(u);
                                tierUE = ue(3);
                                if tierUE == 4 % Out of coverage
                                    continue;
                                end
                                bandwidthUE = ue(5);
                                % Noise
                                noiseReceived = noise(bandwidthUE , NF);
                                % Powers at all UE except the current one (u)
                                interferences = receivedPowers{tierUE};
                                if iscell(interferences)
                                    interferences = interferences{u};
                                    if numel(interferences) > 1
                                        interferences = ...
                                        interferences([1:ue(4)-1,ue(4)+1:end]);
                                    else
                                        interferences = 0;
                                    end
                                else
                                    % Powers from all BS
                                    interferences = interferences(u, :);
                                    % Powers from all BS except the serving
                                    % BS
                                    if numel(interferences) > 1
                                        interferences = ...
                                        interferences([1:ue(4)-1,ue(4)+1:end]);
                                    else
                                        interferences = 0;
                                    end
                                end
                                % Tiers of all UE except the current one
%                                 tier_ = dataUE([1:u-1, u+1:end], 3);
                                % Powers of all the UE except the current UE and having the
                                % same tier.
%                                 interferences = interferences(tier_ == tierUE);
                                sinrCalc = SINR(ue(6),...
                                                          interferences, noiseReceived);
                                %SINRReceivedIter{tierUE, :} = [SINRReceivedIter{tierUE,:}; sinrCalc];
                                dataUE(numUE, 7) = sinrCalc;
                                
                                % DataRate
                                drCalc = dataRate(1, bandwidthUE,...
                                                           1, sinrCalc);
                                %dataRateIter{tierUE, :} = [dataRateIter{tierUE,:}; drCalc]; 
                                dataUE(numUE, 8) = drCalc;
                            end

                            % Calculating SINR and DataRate coverage per tier against
                            % thresholds
                            for tierIdx = 1 : 3
                                for thrIdx = 1 : sinrThresholdLevels
                                    sinrThr = sinrThreshold(thrIdx);
                                    drThr = drThreshold(thrIdx);

                                    SINRCoverageIter(i, thrIdx, tierIdx) = ...
                                    sum(dataUE(dataUE(:,3)==tierIdx, 7) > sinrThr)./sum(tier==tierIdx);

                                    dataRateCoverageIter(i, thrIdx, tierIdx) = ...
                                    sum(dataUE(dataUE(:, 3)==tierIdx, 8) > drThr)./sum(tier==tierIdx);
                                end
                            end
%                             sumSINRCoverage(i, :) = associationsTierIter(i, :)*...
%                                                     squeeze(SINRCoverageIter(i,:,:))';
%                             sumDRCoverage(i, :) = associationsTierIter(i, :)*...
%                                                     squeeze(dataRateCoverageIter(i,:,:))';                            
                            
                            %for tierIdx = 1 : 3
                            %    sinrTier = SINRReceivedIter{tierIdx, :};
                            %    for trIdx = 1 : sinrThresholdLevels
                            %        sinrTr = sinrThreshold(trIdx);
                            %        drTr = drThreshold(trIdx);
                            %        SINRCoverageIter(i, tierIdx, trIdx) ...
                            %        = sum(sinrTier > sinrTr)/size(sinrTier,1);
                            %    drTier = dataRateIter{tierIdx, :};
                            %    dataRateCoverageIter(i, tierIdx, trIdx) = sum(drTier > drTr)/size(drTier,1);
                            %    end
                            %end
                        end
                        meanAssoc = mean(associationsTierIter, 1);
                        meanSINRCoverage = mean(SINRCoverageIter, 1);
                        meanDRCoverage = mean(dataRateCoverageIter, 1);
                        tierKeys = {'MBS', 'mmWave', 'THz'};
                        tierPowers = [PtMBS, PtmmWave, PtTHz];
                        for tierIdx = 1 : 3
                            associationsTier(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         tierIdx) = ...
                                         meanAssoc(tierIdx);
                             SINRCoverage(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         :, tierIdx) = ...
                                         reshape(meanSINRCoverage(:, :, tierIdx), 1,1,1,1,sinrThresholdLevels,1);
                                         %reshape(meanSINRCoverage, 1,1,1,1,500);
                                     
                            dataRateCoverage(counterFactormmWave, ...
                                         counterFactorTHz, ...
                                         counterPmmWave, ...
                                         counterPTHz, ...
                                         :, tierIdx) = ...
                                         reshape(meanDRCoverage(:, :, tierIdx), 1,1,1,1,drThresholdLevels,1);
                                         %reshape(meanDRCoverage, 1,1,1,1,500);
%                              assocTier = meanAssoc(tierIdx);
%                              dataRateTier = mean(dataRateIter{tierIdx});
%                              powerTierConsumed = numStations(tierKeys{tierIdx}) * dBtoWatts(tierPowers(tierIdx));
%                              dataRateTier = dataRateTier .* assocTier;
%                         
%                                  rateByPower(counterFactormmWave, ...
%                                          counterFactorTHz, ...
%                                          counterPmmWave, ...
%                                          counterPTHz, ...
%                                          counterBiasmmWave, ...
%                                          counterBiasTHz, tierIdx) = ...
%                                          dataRateTier ./ powerTierConsumed;
                        end

                        
                        associationsTierIter = zeros(iterations, 4);
                        SINRCoverageIter = zeros(iterations, 3);
                        dataRateCoverageIter = zeros(iterations, 3);
                        
                    end
                end
            end
        end
    end
end

% Resolve NaNs to 0
associationsTier(isnan(associationsTier)) = 0;
SINRCoverage(isnan(SINRCoverage)) = 0;
dataRateCoverage(isnan(dataRateCoverage)) = 0;

% Calculating sum sinr coverage for various thz densitiesg
sc = squeeze(SINRCoverage(1,:,1,1,:,:)); % 3x500x3
assoc = squeeze(associationsTier(1,:,1,1,:)); % 3x3
sumSINRCoverage = zeros(sinrThresholdLevels, 3);
for i = 1 : episodesFactorTHz
    sumSINRCoverage(:,1) = squeeze(sc(i,:,:)) * assoc(i,:)';
end
figure('Name', 'sumSINR Coverage');
for i = 1 : 3
    semilogx(sinrThreshold, sumSINRCoverage(:,i))
    hold on
end
legend('low', 'medium', 'high');

figure('Name', 'SINR Coverage');
for i = 1 : 3
    semilogx(sinrThreshold, squeeze(sc(i, :, 2)))
    hold on
end
legend('low', 'medium', 'high');
figure;
dc = squeeze(dataRateCoverage(1,:,1,1,:,:));
for i = 1 : 3
    semilogx(drThreshold, squeeze(dc(i, :, 2)))
    hold on
end
legend('low', 'medium', 'high');
% rateByPower(isnan(rateByPower)) = 0;
% figure;
% sc = squeeze(SINRCoverage);
% for i = 1 : 3
%     semilogx(sinrThreshold, sc(i,:));
%     hold on
% end
% legend('lowest', 'low', 'high');
% figure;
% dc = squeeze(dataRateCoverage);
% for i = 1 : 3
%     semilogx(drThreshold, dc(i,:));
%     hold on
% end
% legend('lowest', 'low', 'high');

% Saving 
%save('associationsTier.mat', 'associationsTier');
%save('SINRCoverage.mat', 'SINRCoverage');
%save('dataRateCoverage.mat', 'dataRateCoverage');
% save('rateByPower.mat', 'rateByPower');

% % rateVSPower = rateByPower(1, 1, 1, :, 1, 1);
% figure('Name', 'thz data rate vs thz power at specific lambdas, biases');
% plot(powerTHzRange, squeeze(rateVSPower));