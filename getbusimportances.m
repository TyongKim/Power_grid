function [datastruct, casebusimportances, caselineimportances] = getbusimportances(mpc, buses_removed, lines_removed) 
define_constants;
outputinfo = struct('allseq', [], 'seq', [], 'cost', 0, 'time', 0);
datastruct = struct('totalcase', outputinfo, 'caseminusitem', 0); %datastruct with DCOPF output data
%totalcase gives the cost of the entire outage

numbusesincase = size(buses_removed, 1);
numlinesincase = size(lines_removed, 1);
casebusimportances = table;
casebusimportances.bus = buses_removed;
casebusimportances.importance = zeros(numbusesincase, 1);

caselineimportances = table;
caselineimportances.line = lines_removed;
caselineimportances.importance = zeros(numlinesincase, 1);

[totalcase, ~] = removeandrestore(mpc, buses_removed, lines_removed, struct('function', @keepx, 'value', 1));
totalcasecost = totalcase.cost;

if isnan(totalcasecost)
    a = broken
    return
end

datastruct.totalcase = totalcase;
if (numbusesincase + numlinesincase) == 1
    caseminusitem = struct();
    caseminusitem.indivcase = 0;
    caseminusitem.diffcost = totalcasecost;
    if numbusesincase == 1
        caseminusitem.itemprefixed = buses_removed;
        casebusimportances.importance(1) = totalcasecost;
    else
        caseminusitem.itemprefixed = lines_removed;
        caselineimportances.importance(1) = totalcasecost;
    end
    
    datastruct.caseminusitem = caseminusitem;
    return
end
caseminusitem = repmat(struct('indivcase', outputinfo, 'itemprefixed', 0, 'diffcost', 0), numlinesincase + numbusesincase , 1);
%indivcase is the same as output info but for my sliced case
%busprefixed is just the item which was "prefixed", i.e strengthened
%diffcost gives the difference in cost with and without that item
for j = 1:numbusesincase
    dividedcase = buses_removed;
    dividedcase(j) = []; %removing the "strengthened" item
    [divcaseres, ~] = removeandrestore(mpc, dividedcase, lines_removed, struct('function', @keepx, 'value', 1));
    divcasecost = divcaseres.cost;
    caseminusitem(j).indivcase = divcaseres;
    caseminusitem(j).itemprefixed = buses_removed(j);
    diffcost = totalcasecost - divcasecost;
    caseminusitem(j).diffcost = diffcost;
    casebusimportances.importance(j) = diffcost;
end
for j = 1:numlinesincase
    dividedcase = lines_removed;
    dividedcase(j) = []; %removing the "strengthened" item
    [divcaseres, ~] = removeandrestore(mpc, buses_removed, dividedcase, struct('function', @keepx, 'value', 1));
    divcasecost = divcaseres.cost;
    caseminusitem(j + numbusesincase).indivcase = divcaseres;
    caseminusitem(j + numbusesincase).itemprefixed = lines_removed(j);
    diffcost = totalcasecost - divcasecost;
    caseminusitem(j + numbusesincase).diffcost = diffcost;
    caselineimportances.importance(j) = diffcost;

end

datastruct.caseminusitem = caseminusitem;

end