%% TEST BENCH FOR SIMULATION
% DEFINING PARAMETRES

fMBS = 2.4E9; fUAV = 2.4E9; fTHF = 0.3E12; % Hz
bMBS = 20E6; bUAV = 20E6; bSC = 10E9; % Hz
PtMBS = 40; PtUAV = 30; PtSC = 20; % dBM
b = 0.11; a = 9;
uLoS = 5; uNLoS = 1;
Area = 250000; % squared metres
NF = 9; % dB
K = 200;
alpha = 0.5;
beta = 3;
hUAV = 30; % UAV Height in metres
kF = 0.0033; % m^-1

%% EFFECTIVE RATE COVERAGE PROBABILTY VS RATE THRESHOLD
% Placing base stations and users
[numberStations, positionStations] = getBSPositions([1,20,3], 500, 500);
[positionUsers] = getUEPositions(
=======
%% Get and check Base station position distributions.
xMax =  500; yMax = 500;
iterations = 20;
sum = zeros(3,1);


for i=1:iterations
    
    positionUE = getUEPositions(10, xMax, yMax);
    
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
      pos_MBS_data = cell2mat(pos_MBS);
      scatter(pos_MBS{1}, pos_MBS{2}, 'ro'); 
      hold on;
      
      pos_SC = positionStations('SC');
      pos_SC_data = cell2mat(pos_SC);
      scatter(pos_SC{1}, pos_SC{2}, 'k+'); 
      hold on;
      
      pos_UAV = positionStations('UAV');
      pos_UAV_data = cell2mat(pos_UAV);
      scatter(pos_UAV{1}, pos_UAV{2}, 'b*');
      hold on;
      scatter(positionUE(:,1),positionUE(:,2),'r*');

    distanceUserMBS = distance(positionUE(:,1),positionUE(:,2),pos_MBS_data(:,1),pos_MBS_data(:,2));
    distanceUserSC = distance(positionUE(:,1),positionUE(:,2),pos_SC_data(:,1),pos_SC_data(:,2));
    distanceUserUAV = distance(positionUE(:,1),positionUE(:,2),pos_UAV_data(:,1),pos_UAV_data(:,2));
end

average = sum./iterations;
out = sprintf('-----Average-----\nMBS: %f\nSC: %f\nUAV: %f\n', average(1),...
                                                               average(2),...
                                                               average(3));
disp (out);