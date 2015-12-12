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
%		prompt1Class and prompt2Class together contain the same information
%		about the prompt classes as wClass and dClass, except that the
%		first two are categorized by presentation order, and the second by
%		which is cued.
%
%		s.lClass:		class of left prompt figure
%		s.rClass:		class of right prompt figure
%		s.wClass:		class of working memory (cued) prompt figure
%		s.dClass:		class of distractor (non-cued) prompt figure
%		s.cue:			1 or 2, specifies which prompt to cue (1 = left, 2 = right)
%		s.vClass:		class of visual figure (during retention)
%		s.posMatch:     position of the stimulus matching the cued prompt
%						during the test: 1 = up, 2 = right, 3 = down, 4 = left

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
nRepClass = nBlock/numel(arrClass);

% cued and retention period classes
indClassComb = blockdesign(1:numel(arrClassComb),nRepComb,nRun);
indClassComb = indClassComb(:,1:nBlock);

s.wClass = arrayfun(@(ind) arrClassComb{ind}(1), indClassComb);
s.vClass = arrayfun(@(ind) arrClassComb{ind}(2), indClassComb);

% non-cued stimulus class
s.dClass = blockdesign(arrClass, nRepClass, nRun);

% which to cue?
s.cue = blockdesign(1:2, nBlock/2, nRun);

s.lClass = conditional(s.cue == 1, s.wClass, s.dClass);
s.rClass = conditional(s.cue == 2, s.wClass, s.dClass);

% which tests match cued prompt?
s.posMatch = blockdesign([1,2,3,4], nBlock/4, nRun);
	
end