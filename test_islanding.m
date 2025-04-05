
function islands = test_islanding(branches, buslist)

    foundbuses = [];
    islands = {};
    
    % Check for empty branches
    if isempty(branches)
        for i = 1:length(buslist)
            bus1 = buslist(i);
            islands{end+1} = bus1;
        end
        return;
    end
    
    % Check for single branch case
    if size(branches, 1) == 1
        islands{end+1} = [branches(1, 1); branches(1, 2)];
        for i = 1:length(buslist)
            bus = buslist(i);        
            if ~ismember(bus, islands{1})
                islands{end+1} = bus;
            end
        end
        return;
    end

    % General case
    for i = 1:length(buslist)
        bus1 = buslist(i);
        if ismember(bus1, foundbuses)
            continue;
        else
            curiter = bus1;
            island = bus1;
            foundbuses(end+1) = bus1;
            
            while true

                nextiter = [];
                for j = 1:length(curiter)
                    bus = curiter(j);
                    
                    adjbranches1 = branches(branches(:, 1) == bus, :); % find all branches in branches where the target bus appears in index 0
                    for k = 1:size(adjbranches1, 1)
                        branch = adjbranches1(k, :);
                        if ~ismember(branch(2), nextiter) && ~ismember(branch(2), foundbuses)
                            nextiter(end+1) = branch(2);
                        end
                    end
                    
                    adjbranches2 = branches(branches(:, 2) == bus, :);
                    for k = 1:size(adjbranches2, 1)
                        branch = adjbranches2(k, :);
                        if ~ismember(branch(1), nextiter) && ~ismember(branch(1), foundbuses)
                            nextiter(end+1) = branch(1);
                        end
                    end
                end
                
                if isempty(nextiter)
                    islands{end+1} = island;
                    break;
                end
                
                curiter = nextiter;
                island = [island, nextiter];
                foundbuses = [foundbuses, nextiter];
            end
        end
    end
end

% Example usage:
% branches = [1, 4; 4, 5; 5, 6; 3, 6; 6, 7; 9, 4];
% buslist = [1, 2, 3, 4, 5, 6, 7, 9];
% islands = test_islanding(branches, buslist)