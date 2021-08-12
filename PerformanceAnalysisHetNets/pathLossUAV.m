function [pathLossUAV] = pathLossUAV(fspl,probabilityLOS_UAV,pathLoss_LOS,pathLoss_NLOS)
pathLossUAV = fspl + probabilityLOS_UAV*pathLoss_LOS + pathLoss_NLOS*(1-probabilityLOS_UAV);
end

