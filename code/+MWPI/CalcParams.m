function s = CalcParams(varargin)
% PrepRun
%
% Description: Calculate and save parameters for all runs of an mwpi
% experiment (either normal or practice).
%
% Syntax: MWPI.CalcParams([options]);
%
% In:
%   <options>:
%       practice: [false] if true, this is a practice run.
%
% Out: the parameter struct (also saved to PTBIFO.mwpi.run.param):
%		All fields are nRunxnBlock arrays unless otherwise indicated.
%
%		Note that some fields are redundant for convenience. For instance,
%		prompt1Class and prompt2Class together contain the same information
%		about the prompt classes as wClass and dClass, except that the
%		first two are categorized by presentation order, and the second by
%		which is cued.
%
%		s.prompt1Class: class of first presented prompt figure
%		s.prompt2Class: class of second presented prompt figure
%		s.wClass:		class of working memory (cued) prompt figure
%		s.dClass:		class of distractor (non-cued) prompt figure
%		s.cue:			1 or 2, specifies which prompt to cue
%		s.vClass:		class of visual figure (during retention)
%		s.bTestMatch:  true if test matches the cued prompt i.e. the wm figure

% Updated: 2015-08-20

opt = ParseArgs(varargin, 'practice', false);

% conditions
arrClass = MWPI.Param('stim','class');
arrClassComb = MWPI.Param('stim','classComb');

% repetitions
strDomain = conditional(opt.practice, 'practice', 'exp');
nRun	 =  MWPI.Param(strDomain, 'nRun');
nRepComb =  MWPI.Param(strDomain, 'run','nCondRep');
nBlock   =  MWPI.Param(strDomain, 'run','nBlock');
nRepClass = nBlock/numel(arrClass);

% prompt classes
indClassComb = blockdesign(1:numel(arrClassComb),nRepComb,nRun);

s.wClass = arrayfun(@(ind) arrClassComb{ind}(1), indClassComb);
s.dClass = arrayfun(@(ind) arrClassComb{ind}(2), indClassComb);

% which to cue?
s.cue = blockdesign(1:2, nBlock/2, nRun);

s.prompt1Class = conditional(s.Cue == 1, s.wClass, s.dClass);
s.prompt2Class = conditional(s.Cue == 2, s.wClass, s.dClass);

s.bTestMatch = blockdesign([true,false], nBlock/2, nRun);

% visual stimulus
s.vClass = blockdesign(arrClass, nRepClass, nRun);
	
end