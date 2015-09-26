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
%		s.bMatchW: if matching probe, true if probe matches wm stim; else 0'
%		s.tProbe: time, in TRs, of onset of the probe, from start of trial
%				  period (if probe block)
%		s.kProbe: for probe blocks, indicates which probe block we're on
%				  (e.g. s.kProbe = 3 for the third probe block)
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

nCondRep_np = MWPI.Param(strDomain,'nCondRep');
nProbe = MWPI.Param(strDomain,'nProbe');
nNoProbe = MWPI.Param(strDomain,'nNoProbe'); 
nBlock = MWPI.Param(strDomain,'nBlock');

% generate visual and working memory figures
    
	% generate blocks without probe
	
    wFig_np = blockdesign(arrFig, nCondRep_np, 1);
    vFig_np = blockdesign(arrFig, nCondRep_np, 1);

	% generate probe blocks
	nCondRep_p = ceil(nProbe / numel(arrFig)); % max repetitions per figure (balanced)

    wFig_p = blockdesign(arrFig, nCondRep_p, 1);
    vFig_p = blockdesign(arrFig, nCondRep_p, 1);
	
	% trim to number of probe blocks
	wFig_p = wFig_p(1:nProbe);
	vFig_p = vFig_p(1:nProbe);
	
	% combine
	s.wFig = [wFig_np wFig_p];
	s.vFig = [vFig_np vFig_p];
    
    % choose operations (randomly)
    s.wOp = randFrom(arrOp, [1,nBlock], 'unique', false);
    s.vOp = randFrom(arrOp, [1,nBlock], 'unique', false);
    
    % arrrays of composite conditions
    wCondition = s.wFig + 10*s.wOp;
    vCondition = s.vFig + 10*s.vOp;

% generate probe figures
	fracCorr = MWPI.Param(strDomain,'fracProbeCorrect');
	fracMatchW = MWPI.Param(strDomain,'fracMatchW'); % fraction of correct probes that match the working memory stimulus

	% randomly assign probes to be correct/incorrect + match visual/wm stim
	s.bProbe = [false([1,nNoProbe]), true([1,nProbe])];
    
	s.bProbeMatch = logical([false([1,nNoProbe]) CoinFlip(nProbe, fracCorr)']);
    nProbeMatch = sum(s.bProbeMatch);
    
	s.bMatchW(s.bProbeMatch) = logical(CoinFlip(nProbeMatch,fracMatchW));
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
s.pFig = arrayfun(@(c) decget(c,0), pCondition);
s.pOp  = arrayfun(@(c) decget(c,1), pCondition);

% probe onset times
tMaxOnset = MWPI.Param('time','task') - MWPI.Param('time','probe');
tMinOnset = MWPI.Param('time','probeDelay');
s.tProbe		   = zeros([1,nBlock]); 
s.tProbe(s.bProbe) = randBetween(tMinOnset, tMaxOnset, [1,nProbe]);

% probe order
s.kProbe(s.bProbe) = 1:nProbe;

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