function s = CalcParams(varargin)
% PrepRun
%
% Description: Calculate and save parameters for all runs of an mwpi
% experiment (either normal or practice).
%
% Syntax: s = MWPI.CalcParams([options]);
%
% In:
%   <options>:
%       practice: [false] if true, this is a practice run.
%
% Out: the parameter struct (also saved to PTBIFO.mwpi.run.param):
%		All fields are nRun x nBlock arrays unless otherwise indicated.
%
%		Note that some fields are redundant for convenience. For instance,
%		promptClass together with posCued and posUncued contain the
%		information contained in cClass and ucClass.
%
%		For positional parameters, the following encoding is used:
%		1 = up, 2 = right, 3 = down, 4 = left
%
%		s.promptClass:	(nRun x nBlock x 4 array) the stimulus 
%						classes on the prompt screen, in clockwise order
%						starting from the top (along 3rd dimension)
%		s.cClass:		class of cued prompt figure (working memory figure)
%		s.vClass:		class of visual figure (during retention)
%		s.ucClass:		class of uncued framed prompt figure
%		s.posCued:		position of the cued prompt figure
%		s.posUncued:	position of the uncued framed prompt figure
%		s.posMatch:     position of the stimulus matching the cued prompt
%						during the test

% Updated: 2015-08-20

opt = ParseArgs(varargin, 'practice', false);

% conditions
arrClass     = MWPI.Param('stim','class');
arrClassComb = MWPI.Param('stim','classComb');

% repetitions
strDomain = conditional(opt.practice, 'practice', 'exp');
nRun	 =  MWPI.Param(strDomain, 'nRun');
nBlock   =  MWPI.Param(strDomain, 'run','nBlock');
nRepComb =  unless(MWPI.Param(strDomain, 'run','nCondRep'), ceil(nBlock / numel(arrClassComb)));

% cued and retention period classes
indClassComb = blockdesign(1:numel(arrClassComb),nRepComb,nRun);
indClassComb = indClassComb(:,1:nBlock);

s.cClass = arrayfun(@(ind) arrClassComb{ind}(1), indClassComb);
s.vClass = arrayfun(@(ind) arrClassComb{ind}(2), indClassComb);

% uncued framed stimulus class - chosen randomly from those available when
% cClass is removed.
s.ucClass = arrayfun(@(cClass) randFrom(setdiff(arrClass,cClass)), s.cClass);

% position of prompt screen stimuli, frames and cue
% here the position of the cued stimulus is counterbalanced, but the
% position of the other frame is random.
s.posCued = blockdesign(1:4, ceil(nBlock / 4), nRun);
s.posCued = s.posCued(:,1:nBlock);

posOthers = arrayfun(@(cued) randomize(setdiff((1:4)', cued)), s.posCued, 'uni', false);

s.posUncued = cellfun(@(po) po(1), posOthers);
for j = 1:nRun
	for k = 1:nBlock
		s.promptClass(j,k,posOthers{j,k}) = [s.ucClass(j,k); setdiff(arrClass, [s.cClass(j,k), s.ucClass(j,k)])];
		s.promptClass(j,k,s.posCued(j,k)) = s.cClass(j,k);
	end
end

% which tests match cued prompt?
s.posMatch = blockdesign([1,2,3,4], nBlock/4, nRun);
	
end