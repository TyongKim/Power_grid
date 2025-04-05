function sim = getislandmpc(sim, island)
define_constants;
arbgen = [1	72.3 27.03 300 -300	1.04 100 1 0 0 0 0 0 0 0 0 0 0 0 0 0]; %arbitrary generator with no power output
arbgen = horzcat(arbgen, zeros(1, size(sim.gen,2) - 21)); %add cause for some cases, the generator is longer

%create a new "case" for the island with only nodes and lines which are
%part of the island
sim.branch = sim.branch((ismember(sim.branch(:, F_BUS), island)) | (ismember(sim.branch(:, T_BUS), island)), :);
sim.bus = sim.bus(ismember(sim.bus(:, BUS_I), island),:);
sim.gen = sim.gen(ismember(sim.gen(:, GEN_BUS), island),:);

%add a "generator" with no power output if the system doesn't have one
if size(sim.gen, 1) == 0
    sim.gen(1,:) = arbgen;
    sim.gen(1,1) = sim.bus(1,1); %assign the "generator" to the first bus
    sim.bus(1,2) = 3;

%check if there is no slack bus
elseif ~ismember(3, sim.bus(:, BUS_TYPE))
    busindex = sim.gen(1,1); %just assign the first bus with a generator as the slack bus
    busesinisland = sim.bus(:, 1);
    sim.bus(find(busesinisland == busindex), 2) = 3; %actually assigning as a slack bus
end

while sum(sim.gen(:,PMIN)) > sum(sim.bus(:, PD)) %check if min power output is larger than the power demand
    for i=1:size(sim.gen, 1)
        if sim.gen(i, PMIN) ~= 0 %check if the minimum value of the generator is 0
            sim.gen(i, PMIN) = 0; %if not set its min and max to 0, akin to turning it off
            sim.gen(i, PMAX) = 0;
            break %break and recheck above
        end
        %this assumes that its fine for the maximum power of a generator to
        %be nonzero while the slack buses is 0. idk if this will work
        %If it doesn't change the code to turn off non-slack buses first
    end


end

%just set number of rows of gencost to be the number of generators. This will
%avoid errors (even though gencost isn't actually used)
sim.gencost = sim.gencost(1: size(sim.gen, 1), :);