function totalloss = addbusandsim(mpc, removedbuses, removedlines, remlineidx, cutlines, toaddsequence)
%Calculate total losses after we add the sequence of buses to the "disconnected mpc. 
%If this doesn't work out, you can easily just remove the unused buses from
%the original mpc

define_constants;
addedbuses = toaddsequence(toaddsequence > 0); %split my sequence into lines and buses
addedlines = toaddsequence(toaddsequence < 0);

if ~isempty(removedbuses)
    mpc.bus = [mpc.bus; removedbuses(ismember(removedbuses(:,1), addedbuses), :)]; %add buses in our sequence to the mpc
    unusedbuses = setdiff(removedbuses(:,1), addedbuses); %get all unsued buses
    mpc.branch = [mpc.branch; cutlines(~ismember(cutlines(:, F_BUS), unusedbuses) & ~ismember(cutlines(:, T_BUS), unusedbuses), :)];
%add newly connected branches to the mpc from cutlines
end

for i = 1:size(addedlines, 1)
    curaddedlineidx = remlineidx == addedlines(i);
    curaddedline = removedlines(curaddedlineidx, :);
    if ~isempty(removedbuses)
        if ~ismember(curaddedline(T_BUS), unusedbuses) && ~ismember(curaddedline(F_BUS), unusedbuses)
            mpc.branch = [mpc.branch; curaddedline];
        end
    else %if mpc.branch isn't empty
        mpc.branch = [mpc.branch; curaddedline];
    end
end


%get islands as before once again using matlab
branches = mpc.branch(:, 1:2);        
buslist = mpc.bus(:, 1); 
islanding = test_islanding(branches, buslist);
islands = reshape(cell(islanding), [size(islanding, 2), 1]);


totalshed = 0; %calculate load shed of each island
for j=1:size(islands,1)
    sim = getislandmpc(mpc,islands{j});
    resulti = addloadshedding(sim);
    resultt = resulti.x;
    numbuses = size(resulti.bus,1);
    totalshed = totalshed + 100*sum(resultt(end-numbuses+1:end));
end

%get total load knocked out. Equal to the sum of removed buses - buses we
%added
if ~isempty(removedbuses)
    totalknockedout = sum(removedbuses(:,PD)) - sum(removedbuses(ismember(removedbuses(:,1), addedbuses), PD));
else
    totalknockedout = 0;
end

totalloss = totalknockedout + totalshed; %get the total loss
end