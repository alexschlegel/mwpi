function s = PrepRun(mwpi)
% mwpi.PrepRun
%
% Description: Calculate and save parameters for an mwpi run.
%
% Syntax: mwpi.PrepRun;
%
% Out: the parameter struct (also saved to PTBIFO.mwpi.run.param(end+1) ):
%		All fields are 1xnBlock arrays.
%		s.wFig: working-memory stimulus figure
%		s.wOp:  working-memory stimulus operation
%		s.vFig: visual stimulus figure
%		s.vOp:  visual stmulus orientation = start orientation + vOp + hflip
%				(in order to ensure its orientation is always different
%				from that of the manipulated wFig)
%		s.pFig: if probe block, probe figure; else 0
%		s.pOp:  if probe block, operation used to construct probe
%				orientation; else 0
%
%		s.bProbeHFlip: probe orientation = start orientation + pOp if 0,
%										   start orient. + pOp + hflip if 1
%		s.bProbe: true if probe block
%		s.bProbeMatch: if probe block, true if probe is a match; else 0
%		s.bMatchW: if matching probe, true if probe matches wm stim; else 0
%
% Updated: 2015-08-14

% conditions
[kF, kO] = ndgrid(MWPI.Param('stim','figure'),MWPI.Param('stim','operation'));
kCondition = reshape(kF + 10*kO, [],1);

% generate visual and working memory figures
	% generate blocks without probe
	nCondRep = MWPI.Param('exp','nCondRep');
	nNoProbe = MWPI.Param('exp','nNoProbe'); 

	wCondition_np = blockdesign(kCondition, nCondRep, 1);
	vCondition_np = blockdesign(kCondition, nCondRep, 1);

	% generate probe blocks
	nProbe = MWPI.Param('exp','nProbe');
	nCondRep = ceil(nProbe / numel(kCondition)); % max repetitions per figure (balanced)

	wCondition_p = blockdesign(kCondition, nCondRep, 1);
	vCondition_p = blockdesign(kCondition, nCondRep, 1);
	
	% trim to number of probe blocks
	wCondition_p = wCondition_p(1:nProbe);
	vCondition_p = vCondition_p(1:nProbe);
	
	% combine
	wCondition = [wCondition_np wCondition_p];
	vCondition = [vCondition_np vCondition_p];

% generate probe figures
	fracCorr = MWPI.Param('exp','fracProbeCorrect');
	fracMatchW = MWPI.Param('exp','fracMatchW'); % fraction of correct probes that match the working memory stimulus

	% randomly assign probes to be correct/incorrect + match visual/wm stim
	s.bProbe = [false([1,nNoProbe]), true([1,nProbe])];
	s.bProbeMatch = logical([false([1,nNoProbe]) CoinFlip(nProbe, fracCorr)']);
	s.bMatchW(s.bProbeMatch) = logical(CoinFlip(sum(s.bProbeMatch),fracMatchW));
	s.bMatchW(~s.bProbeMatch) = false;

	% probe figures and operations
		% probes matching w
		pCondition(s.bMatchW) = wCondition(s.bMatchW);
		s.bProbeHFlip(s.bMatchW) = false; % whether to flip probe horizontally first

		% probes matching v
		bMatchV = s.bProbeMatch & ~s.bMatchW;
		pCondition(bMatchV) = vCondition(bMatchV);
		s.bProbeHFlip(bMatchV) = true;

		% nonmatching probes
		bProbeNoMatch = ~s.bProbeMatch & s.bProbe;
			
			% h flip?
			s.bProbeHFlip(bProbeNoMatch) = logical(CoinFlip(sum(bProbeNoMatch),0.5));
			% condition to avoid (to make it incorrect)
			avoidCond = arrayfun(@(i) conditional(s.bProbeHFlip(i), vCondition(i), wCondition(i)), ...
				find(bProbeNoMatch));
			
			% choose condition at random from the remaining choices
			pCondition(bProbeNoMatch) = arrayfun(@(i)	randFrom(kCondition,'exclude',avoidCond),...
				find(bProbeNoMatch));

% decompose conditions
s.wFig = arrayfun(@(c) decget(c,0), wCondition);
s.wOp  = arrayfun(@(c) decget(c,1), wCondition);
s.vFig = arrayfun(@(c) decget(c,0), vCondition);
s.vOp  = arrayfun(@(c) decget(c,1), vCondition);
s.pFig = arrayfun(@(c) decget(c,0), pCondition);
s.pOp  = arrayfun(@(c) decget(c,1), pCondition);

% randomize order of blocks
indShuffle = randomize(1:(nNoProbe + nProbe));
s = structfun(@(f) f(indShuffle), s, 'uni', false);

% save
	% get existing struct
	paramStruct = mwpi.Experiment.Info.Get('mwpi',{'run','param'});
	
	if isempty(paramStruct)
		paramStruct = s;
	else
		paramStruct(end+1) = s;
	end
	
	mwpi.Experiment.Info.Set('mwpi',{'run','param'},paramStruct);

% log
mwpi.Experiment.AddLog('run prepared; parameters saved');
	
end