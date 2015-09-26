function res = Block(mwpi, sRun, kBlock, sHandle)
% Block - do one MWPI block.
%
% Syntax: mwpi.Block(kRun, kBlock, sHandle)
%
% In:
%   sRun - the run parameter struct
%   kBlock - the block number
%   sHandle - a struct of handles to textures that should be prepared before this function
%             is called. Fields must include at least "prompt", "task", and "probe".
%
% Updated: 2015-08-18

res.bCorrect = [];
bFlushed = false;

bProbe = sRun.bProbe(kBlock);

% set up sequence
if bProbe
	cX = {	sHandle.prompt
			sHandle.task
			sHandle.probe
			{'Blank'}
		};
else
	cX = {	sHandle.prompt
			sHandle.task
		};
end

if bProbe
	tProbeStart = sRun.tProbe(kBlock);
	tShow = cumsum([	MWPI.Param('time','prompt')
						tProbeStart
						MWPI.Param('time','probeOn')
						MWPI.Param('time','probeOff')
					]);
else
	tShow = cumsum([	MWPI.Param('time','prompt')
						MWPI.Param('time','task')
					]);
end

if strcmp(mwpi.Experiment.Info.Get('experiment','context'), 'psychophysics')
	% convert trs to milliseconds
	trSecs = MWPI.Param('trTime');
	tShow = tShow * trSecs * 1000;
end
	
if bProbe
	fwait = {@WaitDefault
			 @WaitDefault
			 @WaitProbe
			 @WaitProbe
			 };
else
	fwait = repmat({@WaitDefault},2,1);
end

[res.tStart, res.tEnd, res.tShow, res.bAbort, res.kResponse, res.tResponse] = ...
	mwpi.Experiment.Show.Sequence(cX, tShow, ...
	'fwait',	fwait, ...
	'tbase',	'sequence', ...
	'fixation',	false ...
	);

% if it's a probe and there's no response, call it incorrect
if bProbe && isempty(res.bCorrect)
	res.bCorrect = false;
end

%---------------------------------------------------------------------%
	function [bAbort, kResponse, tResponse] = WaitDefault(tNow,tNext)
		bAbort = false;
		kResponse = [];
		tResponse = [];
		
		timeMS = MWPI.Param('trTime') * 1000 * (tNext - tNow);
		endTimeMS = PTB.Now + timeMS;
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW, endTimeMS);
	end
%--------------------------------------------------------------------%
	function [bAbort, kResponse, tResponse] = WaitProbe(tNow,~)
		bAbort = false;
        
        % flush serial port once
        if ~bFlushed
            mwpi.Experiment.Serial.Clear;
            bFlushed = true;
        end
		
		kCorrect = cell2mat(mwpi.Experiment.Input.Get( ...
			conditional(sRun.bProbeMatch(kBlock),'match','noMatch')));
		
		% check for a response
		[bResp,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
		
		if ~bResp
			kResponse = [];
			tResponse = [];
		else
			kResponse = kButton;
			tResponse = tNow;
			if isempty(res.bCorrect)
				res.bCorrect = all(ismember(kButton, kCorrect));
			end
		end
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
end