clear all; clc; close all

addpath('/Users/taeyongkim/Documents/matpower8.0')
define_constants;

mpc = loadcase('case9.m'); %load the case file
mpc = scale_load(2.4, mpc); %increase the load demand by a factor of 1.25 for texas, 2.4 for case 9, and 1.15 for Hawaii


% Load unique failure cases
load("unique_fail_scenario_RCP26.mat", "data");
numcases = size(data, 1);

% Make a structure to save the results
outputstruct = repmat(struct('row', 0, 'cost', 0), ceil(numcases), 1);

for j = 1:100 %numcases

    vec = data(j, :);
    buses = vec(1:9);
    buses_to_remove = transpose(find(buses));
    lines = sum(reshape(vec(10:36),3,[]), 1);
    downlines = find(lines);
    remlines = repmat(struct('busfrom', 0, 'busto', 0, 'connumber', 1, 'leninbox', 0), size(downlines, 2), 1);
    %put it at 1 here cause they're all 1
    %3 is there since it's 3 poles per line
    for k = 1:size(downlines, 2)
        remlines(k).busfrom = mpc.branch(downlines(k), F_BUS);
        remlines(k).busto = mpc.branch(downlines(k), T_BUS);
        remlines(k).leninbox = lines(downlines(k));
    end
    
    outputstruct(j).row = vec;
    if size(buses_to_remove, 1) + size(downlines, 2) == 0
        outputstruct(j).cost = 0;
    else
        [casedata, ~] = removeandrestore(mpc, buses_to_remove, remlines, struct('function', @keepx, 'value', size(buses_to_remove, 1) + size(downlines, 2)));
        outputstruct(j).cost = casedata.cost;
    end

    if mod(j, 100) == 0
        disp(j)
    end

end
save('outputstruct', 'outputstruct')
