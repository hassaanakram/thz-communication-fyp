function [probabilities,tHzBSLoS, mmWaveBSLoS, mmWaveBSNLoS] = ...
                                    getProbabilities(positionStations...
                                    ,positionUE, positionBuilds...
                                    ,numUE, numStations, numBuilds)
%% FUNCTION TO COMPUTE LOS/NLOS PROBABILITES & LOS THZ BS LOCATIONS PER USER BASIS
probabilities = zeros(numUE, 2, 2);
tHzBSLoS = cell(numUE, 1);
mmWaveBSLoS = cell(numUE, 1);
mmWaveBSNLoS = cell(numUE, 1);

% First, iterate over each user:
for i = 1 : 1 : numUE
    str = sprintf('User %d\n', i); disp(str);
    UE = positionUE(i, :);
    % Second, iterate over each Basestation
    for tier = ["mmWave", "THz"]
        numLoS = 0; numNLoS = 0;
        for j = 1 : 1 : numStations(tier)
            BS = positionStations(tier);
            BS = BS(j, :);
            overlap = 0;
            % Then iterate over each building
            for k = 1 : 1 : numBuilds
                building = positionBuilds{k};
                % Check for intersection between UE/BS and Building
                lineX = [UE(:, 1); BS(:, 1)];
                lineY = [UE(:, 2); BS(:, 2)];
                building = polyshape(building);
                [in, out] = intersect(building, [lineX, lineY]);
                % Check if no intersection
                if size(in,1) ~= 0
                    overlap = 1;
                    break;
                end
            end
            
            if overlap == 0
                numLoS = numLoS + 1;
                if tier == "THz"
                    tHzBSLoS{i} = [tHzBSLoS{i}; BS];
                else
                    mmWaveBSLoS{i} = [mmWaveBSLoS{i}; BS];
                end
            else
                numNLoS = numNLoS + 1;
                if tier == "mmWave"
                    mmWaveBSNLoS{i} = [mmWaveBSNLoS{i}; BS];
                end
            end
            
        end
        if tier == "mmWave"
            tierIdx = 1;
        else 
            tierIdx = 2;
        end
        
        probabilities(i, tierIdx, 1) = numLoS/numStations(tier);
        probabilities(i, tierIdx, 2) = numNLoS/numStations(tier);
        
        fprintf('NumLoS = %d\nNumNLoS = %d\nPLoS-%s = %d\nPNLoS-%s = %d\n'...
                    ,numLoS, numNLoS, tier...
                    ,probabilities(i, tierIdx, 1)...
                    ,tier, probabilities(i, tierIdx, 2));
    end
end
end

