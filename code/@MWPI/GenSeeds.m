function arrSeed = GenSeeds(varargin)
% Generate an nx1 array of unique seeds using randseed2
% Syntax: arrSeed = MWPI.GenSeeds([n]=5)

if nargin > 1 || (nargin == 1 && ~isa(varargin{1},'numeric'))
	error('Invalid input arguments')
end

if nargin == 0
	n = 5;
else
	n = varargin{1};
end

bSeedsDone = false;
while ~bSeedsDone
	arrSeed = arrayfun(@(x) randseed2, (1:n)');
	if numel(unique(arrSeed)) == n
		bSeedsDone = true;
	end
end
end