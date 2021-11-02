function [num_buildings, coords] = getBuildingCoords(csv_name, xMax, yMax, fidIdx, xIdx, yIdx)
% Reading CSV data of buildings. Will have to change Vars manually atm
csv_name = strcat(csv_name, '.csv');
data = csvimport(csv_name);

% coords_ids = data(:, {'Var3', 'Var38', 'Var39'});
fid = cell2mat(data(2:end, fidIdx));
coords_x = rescale(cell2mat(data(2:end, xIdx))).*xMax;
coords_y = rescale(cell2mat(data(2:end, yIdx))).*yMax;

% Check if an coord is negative if yes, offset it
minX = min(coords_x); minY = min(coords_y);
if minX < 0
    coords_x = coords_x + abs(minX);
end
if minY < 0
    coords_y = coords_y + abs(minY);
end
num_buildings = size(unique(fid),1);
coords = cell(num_buildings, 1);

for i = 1:num_buildings
    coords_building = [];
    %fid = coords_ids.Var3;
    coords_building(:, 1) = coords_x(fid == i);
    coords_building(:, 2) = coords_y(fid == i);
    coords{i} = coords_building;
end
end

