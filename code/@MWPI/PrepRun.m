function s = PrepRun(mwpi)
% PrepRun
%
% Description: Calculate and save parameters for an mwpi run.
%
% Syntax: mwpi.PrepRun;
%
% Out: the parameter struct (also saved to PTBIFO.mwpi.run.param(end+1) ):
%		All fields are 1xnBlock arrays unless otherwise indicated.
%       All figures and operations are before applying the mapping.
%
%       s.promptLoc: location of the actual prompt, clockwise from left (1=left,2=top,etc)
%       s.promptFig: (4xnBlock) figures on the prompt screen, clockwise from left
%       s.promptOp:  (4xnBlock) operations on the prompt screen, clockwise from left
%
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
%		s.tProbe: time, in TRs, of onset of the probe, from start of trial
%				  period (if probe block)
%
% Updated: 2015-08-20

% conditions
arrFig = MWPI.Param('stim','figure');
arrOp = MWPI.Param('stim','operation');

[kF, kO] = ndgrid(arrFig, arrOp);
kCondition = reshape(kF + 10*kO, [],1);

% are we doing practice?
if strcmp(mwpi.Experiment.Info.Get('experiment','context'), 'psychophysics')
	strDomain = 'practice';
else
	strDomain = 'exp';
end

nCondRep = MWPI.Param(strDomain,'nCondRep');
nProbe = MWPI.Param(strDomain,'nProbe');
nNoProbe = MWPI.Param(strDomain,'nNoProbe'); 
nBlock = MWPI.Param(strDomain,'nBlock');

% generate visual and working memory figures
    
	% generate blocks without probe
	
	wCondition_np = blockdesign(kCondition, nCondRep, 1);
	vCondition_np = blockdesign(kCondition, nCondRep, 1);

	% generate probe blocks
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
	fracCorr = MWPI.Param(strDomain,'fracProbeCorrect');
	fracMatchW = MWPI.Param(strDomain,'fracMatchW'); % fraction of correct probes that match the working memory stimulus

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
			pCondition(bProbeNoMatch) = arrayfun(@(i)	randFrom(kCondition,'exclude',avoidCond), ...
                find(bProbeNoMatch));

% decompose conditions
s.wFig = arrayfun(@(c) decget(c,0), wCondition);
s.wOp  = arrayfun(@(c) decget(c,1), wCondition);
s.vFig = arrayfun(@(c) decget(c,0), vCondition);
s.vOp  = arrayfun(@(c) decget(c,1), vCondition);
s.pFig = arrayfun(@(c) decget(c,0), pCondition);
s.pOp  = arrayfun(@(c) decget(c,1), pCondition);

% probe onset times
tMaxOnset = MWPI.Param('time','task') - MWPI.Param('time','probe');
s.tProbe		   = zeros([1,nBlock]); 
s.tProbe(s.bProbe) = randBetween(0, tMaxOnset, [1,nProbe]);

% prompt screen parameters
[~,sTemp] = blockdesign(1, nBlock, 1, struct('loc',1:4));
s.promptLoc = sTemp.loc;

cFigDistractor = arrayfun(@(wFig) randomize(setdiff(arrFig',wFig)), s.wFig,'uni',false);
cOpDistractor = arrayfun(@(wOp) randomize(setdiff(arrOp',wOp)), s.wOp,'uni',false);

s.promptFig = cell2mat(cellfun(@(dis,loc,wFig) [dis(1:loc-1); wFig; dis(loc:end)], ...
    cFigDistractor, num2cell(s.promptLoc), num2cell(s.wFig) ,'uni',false));

s.promptOp = cell2mat(cellfun(@(dis,loc,wOp) [dis(1:loc-1); wOp; dis(loc:end)], ...
    cOpDistractor, num2cell(s.promptLoc), num2cell(s.wOp), 'uni',false));

% randomize order of blocks
indShuffle = randomize(1:nBlock);
s = structfun(@(f) f(:,indShuffle), s, 'uni', false);

% log
mwpi.Experiment.AddLog('run prepared');
	
end