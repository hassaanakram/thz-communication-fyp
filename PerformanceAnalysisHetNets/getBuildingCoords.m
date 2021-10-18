function [num_buildings, coords] = getBuildingCoords(csv_name, xMax, yMax)
% Reading CSV data of buildings. Will have to change Vars manually atm
csv_name = strcat(csv_name, '.csv');
data = csvimport(csv_name);

% coords_ids = data(:, {'Var3', 'Var38', 'Var39'});
fid = cell2mat(data(2:end, 3));
coords_x = rescale(cell2mat(data(2:end, 38))).*xMax;
coords_y = rescale(cell2mat(data(2:end, 39))).*yMax;
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

