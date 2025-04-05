function [allsequences,bestsequence,cost] = keepx(keepn,mpc, removedbuses, removedlines, remlineidx, linetimings, cutlines, origloss)
%Greedy but instead of keeping the best sequence, we keep the best n
%sequences before continuing
%   Detailed explanation goes here
define_constants;
timingmodifier = 1;
%create a struct of the sequences for the current iteration
cursequences = repmat(struct('sequence', [], 'cost', 0, 'mockcost' ,0, 'lossafteriter', origloss, 'totalrestored', 0, 'iterrestored', 0, 'totaltime', 0), 1, 1);
%create a struct of the sequences for the next iteration
allsequences = cell(size(removedbuses, 1) + size(removedlines, 1), 1);
newsequences = 0;
for i=1:(size(removedbuses, 1) + size(removedlines, 1) -1)
    for j=1:size(cursequences, 1)
        for k=1:size(removedbuses, 1)
            if ~ismember(removedbuses(k, 1), cursequences(j).sequence) %check if bus is not already in the sequence
                toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)];
                %toaddsequence = toaddsequence(~cellfun('isempty', toaddsequence)); %weird thing is happening with the sequence thing being a cell array
                lossafteriter = addbusandsim(mpc, removedbuses, removedlines, remlineidx, cutlines, toaddsequence); %get total loss of buses using this sequence
                eventtime = size(cutlines(cutlines(:, F_BUS) == removedbuses(k, 1), :), 1) + size(cutlines(cutlines(:, T_BUS) == removedbuses(k, 1), :), 1);
                if ~isempty(removedlines)
                    eventtime = eventtime + size(removedlines(removedlines(:, F_BUS) == removedbuses(k, 1), :), 1) + size(removedlines(removedlines(:, T_BUS) == removedbuses(k, 1), :), 1);
                end
                iterrestored = cursequences(j).lossafteriter - lossafteriter;
                totalrestored = origloss - lossafteriter;
                totaltime = cursequences(j).totaltime + eventtime;
                if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                    newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime),'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
                end
            end
        end

        for k=1:size(removedlines, 1)
            if ~ismember(remlineidx(k), cursequences(j).sequence) %check if line is not already in the sequence
                toaddsequence = [cursequences(j).sequence; remlineidx(k)];
                
                lossafteriter = addbusandsim(mpc, removedbuses, removedlines, remlineidx, cutlines, toaddsequence); %get total loss of buses using this sequence
                iterrestored = cursequences(j).lossafteriter - lossafteriter;
                totalrestored = origloss - lossafteriter;
                eventtime = timingmodifier * linetimings(k);
                totaltime = cursequences(j).totaltime + eventtime;
                if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                    newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime),'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
                end
            end
        end
    end
    if i==(size(removedbuses, 1) + size(removedlines, 1) -1) %if it's the second last iter, just keep all of them, we aren't running more sims
         allsequences{i} = newsequences;
         cursequences = newsequences;
         newsequences = 0;
    else
        allsequences{i} = newsequences; %save sequences so we don't lose information
        sequencecosts = [newsequences.mockcost];
        [~, idxs] = maxk(sequencecosts, keepn);
        cursequences = newsequences(idxs); %update cursequences for the next iteration
        newsequences = 0;
    end
end

%do the last iteration here, can be done without simming. This assumes there was no load shed to begin with
for j=1:size(cursequences, 1)
    found = false;
    for k=1:size(removedbuses, 1)
        if ~ismember(removedbuses(k, 1), cursequences(j).sequence)
            eventtime = size(cutlines(cutlines(:, T_BUS) == removedbuses(k, 1), :), 1) + size(cutlines(cutlines(:, F_BUS) == removedbuses(k, 1), :), 1);
            if size(removedlines, 1) > 0
                eventtime = eventtime + size(removedlines(removedlines(:, F_BUS) == removedbuses(k, 1), :), 1) + size(removedlines(removedlines(:, T_BUS) == removedbuses(k, 1), :), 1);
            end

            toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)];

            found = true;
        end
    end

    if ~found
        for k=1:size(removedlines, 1)
            if ~ismember(remlineidx(k), cursequences(j).sequence)
                eventtime = timingmodifier * linetimings(k);
                toaddsequence = [cursequences(j).sequence; remlineidx(k)];
                
            end
        end
    end

    lossafteriter = 0;
    iterrestored = cursequences(j).lossafteriter - lossafteriter;
    totaltime = cursequences(j).totaltime + eventtime;
    totalrestored = origloss - lossafteriter;
    if isa(newsequences, 'double')
        newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime);
    else
        newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(eventtime), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(eventtime), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
    end
end

allsequences{end} = newsequences;
sequencecosts = [newsequences.cost];
[~, idx] = min(sequencecosts);
cursequence = newsequences(idx);

bestsequence = cursequence.sequence;
cost = cursequence.cost;

end