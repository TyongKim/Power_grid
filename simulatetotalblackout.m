function simulatetotalblackout(partitionno)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
addpath('matpower7.1')
install_matpower(1,0,0,1)
define_constants;
mpc = loadcase('case9.m'); %load the case file
mpc = scale_load(2.4, mpc); %increase the load demand by a factor of 1.25 for texas, 2.4 for case 9, and 1.15 for Hawaii
totalpartitions = 200000;
load("shuff_outages.mat", "shuff_A");
numcases = size(shuff_A, 1);
outputstruct = repmat(struct('row', 0, 'cost', 0), ceil(numcases/totalpartitions), 1);
for j = (1+((partitionno-1)*ceil(numcases/totalpartitions))):min(numcases, (partitionno*ceil(numcases/totalpartitions)))
    localcasenum = j - (1+((partitionno-1)*ceil(numcases/totalpartitions))) + 1;
    vec = ones(1, 36);
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
    outputstruct(localcasenum).row = vec;
    if size(buses_to_remove, 1) + size(downlines, 2) == 0
        outputstruct(localcasenum).cost = 0;
    else
        [casedata, ~] = removeandrestore(mpc, buses_to_remove, remlines, struct('function', @keepx, 'value', size(buses_to_remove, 1) + size(downlines, 2)));
        outputstruct(localcasenum).cost = casedata.cost;
    end
    if mod(localcasenum, 100) == 0
        disp(localcasenum)
    end
end
save('simresultstotalblackout', "outputstruct")
quit
end