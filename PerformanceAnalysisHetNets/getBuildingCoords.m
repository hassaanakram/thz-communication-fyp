function [num_buildings, coords] = getBuildingCoords(csv_name, xMax, yMax)
% Reading CSV data of buildings. Will have to change Vars manually atm.
data = readtable(csv_name, 'NumHeaderLines', 1);
coords_ids = data(:, {'Var3', 'Var38', 'Var39'});
ids = coords_ids.Var3;
coords_x = rescale(coords_ids.Var38).*xMax;
coords_y = rescale(coords_ids.Var39).*yMax;
num_buildings = size(unique(ids),1);

for i = 1:num_buildings
    coords_building = [];
    fid = coords_ids.Var3;
    coords_building(:, 1) = coords_x(fid == i);
    coords_building(:, 2) = coords_y(fid == i);
    coords{i} = coords_building;
end
end

