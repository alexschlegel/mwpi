function Run(mwpi, varargin)
% Run - do an MWPI run.
% 
% Syntax: MWPI.Run
%
% Updated: 2015-06-24
%

% calculate which run to execute
skippedRuns = find(~mwpi.runsComplete);
if numel(skippedRuns) == 0
	nextRun = numel(mwpi.runsComplete) + 1;
else
	nextRun = skippedRuns(1);
end

% Ask which run to run
while true
	kRun = mwpi.Experiment.Prompt.Ask('Which run?', ...
								'mode','command_window', ...
								'default',nextRun);

	if ~isa(kRun,'numeric') || kRun < 1 || floor(kRun) ~= ceil(kRun)
		warning('Run must be a positive integer.');
	else
		break;
	end
end

if kRun > mwpi.maxRun
	error('Run must be between 1 and %d, inclusive.', mwpi.maxRun);
elseif kRun > mwpi.nRun
	bCont = mwpi.Experiment.Prompt.YesNo(['Run exceeds experimental design of ',...
			num2str(mwpi.nRun), ' runs. Continue?'],...
			'mode','command_window',...
			'default','n');
	if ~bCont
		return
	end
end

mwpi.Experiment.AddLog(['Starting run ' num2str(kRun)]);

% perform the run
	
	%-- set up sequence --%
	
	% scanner starts
	tRun = MWPI.Param('time','run');
	mwpi.Experiment.Scanner.StartScan(tRun);
	
	% initialize texture handles
	hPrompt = mwpi.Experiment.Window.OpenTexture('prompt');
	hTask = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['task',num2str(i)]),...
				(1:mwpi.RSVPLength)','uni',false);
	hTaskYes = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['taskYes',num2str(i)]),...
				(1:mwpi.RSVPLength)','uni',false);
	hTaskNo = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['taskNo',num2str(i)]),...
				(1:mwpi.RSVPLength)','uni',false);
	hRecall = mwpi.Experiment.Window.OpenTexture('recall');
	hRecallYes = mwpi.Experiment.Window.OpenTexture('recallYes');
	hRecallNo = mwpi.Experiment.Window.OpenTexture('recallNo');

	cX = [repmat([{{'Blank'}}
				  hPrompt
				  {{'Blank'}}
				  arrayfun(@(kTrial) hTask{kTrial}, ...
				  (1:mwpi.RSVPLength)','uni',false)
				  hRecall
				  ], mwpi.nBlock,1)
		  {{'Blank'}}];
								
	tBlock = [MWPI.Param('time','prompt')
			  MWPI.Param('time','blank')
			  repmat(MWPI.Param('time','task'),mwpi.RSVPLength,1)
			  MWPI.Param('time','recall')];
		  
	tShow = cumsum([MWPI.Param('time','prepost')
					repmat([tBlock; MWPI.Param('time','rest')], mwpi.nBlock-1,1)
					tBlock
					MWPI.Param('time','prepost')
					]);				
	
	fwait = arrayfun(@(kBlock) [{@(tNow,tNext) DoRest(kBlock,tNow,tNext)}
								{false}
								{false}
								arrayfun(@(kTrial) ...
									@(tNow,tNext) DoTask(kBlock,kTrial,tNow,tNext),...
									(1:mwpi.RSVPLength)','uni',false)
								{@(tNow,tNext) DoRecall(kBlock,tNow,tNext)}
								], (1:mwpi.nBlock)','uni',false);
	fwait = vertcat(fwait{:},false);
								
	% go!
	[cRun.tStart, cRun.tEnd, cRun.tShow, cRun.bAbort, cRun.bCorrect, cRun.tResponse] = ...
		mwpi.Experiment.Show.Sequence(cX,tShow, ...
		'tstart',1, ...
		'tbase','absolute', ...
		'tunit','tr', ...
		'fwait', fwait ...
		);
	
	% scanner ends
	mwpi.Experiment.Scanner.StopScan;

% save results
sResults = mwpi.Experiment.Info.Get('mwpi','result');
if isempty(sResults)
	sResults = cRun;
else
	sResults(end+1) = cRun;
end
mwpi.Experiment.Info.Set('mwpi','result',sResults);
mwpi.Experiment.Info.AddLog('Results saved.');
	
% finish up
mwpi.Experiment.AddLog(['Run ' num2str(kRun) ' complete']);
mwpi.runsComplete(kRun) = true;
mwpi.Experiment.Info.Set('mwpi','runsComplete',mwpi.runsComplete);

%--------------------------------------------------------------------%
	function [bAbort, bCorrect, tResponse] = DoRest(kBlock, ~, tNext)				
		bAbort = false;
		bCorrect = [];
		tResponse = [];
		
		% check if textures have been prepared
		arrPrepared = mwpi.Experiment.Info.Get('mwpi','blocksPrepared');
		if isempty(arrPrepared) || 	~arrPrepared(kRun,kBlock)
			% prepare the textures for the next block.
			mwpi.PrepTextures(kRun, kBlock);
		end
		
		% wait
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_IDLE, ...
			mwpi.Experiment.Scheduler.TR2ms(tNext));
	end
%-------------------------------------------------------------------%
	function [bAbort, bCorrect, tResponse] = DoTask(kBlock, kTrial, tNow, ~)
		bAbort = false;
		kCorrect = mwpi.Experiment.Input.Get(conditional(mwpi.match(kRun,kBlock,kTrial),'match','noMatch'));
		
		arrResponse = mwpi.Experiment.Info.Get('mwpi','bTaskResponse');
		if isempty(arrResponse)
			arrResponse = false(mwpi.maxRun, mwpi.nBlock, mwpi.RSVPLength);
		end
		
		% if a response has been logged, don't check for another.
		if arrResponse(kRun,kBlock,kTrial)
			bCorrect = [];
			tResponse = [];
			mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
			return
		end
		
		% check for a response
		[~,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
		if kButton == kCorrect
			tResponse = tNow;
			bResponse = true;
			bCorrect = true;
		elseif ~isempty(kButton)
			tResponse = tNow;
			bResponse = true;
			bCorrect = false;
		else
			tResponse = [];
		end
		
		if bResponse
			arrResponse(kRun,kBlock,kTrial) = true;
			mwpi.Experiment.Info.Set('mwpi','bTaskResponse',arrResponse);
			% show feedback
			if bCorrect
				mwpi.Experiment.Show.Texture(hTaskYes{kTrial});
				mwpi.Experiment.Window.Flip('correct response');
			else
				mwpi.Experiment.Show.Texture(hTaskNo{kTrial});
				mwpi.Experiment.Window.Flip('incorrect response');
			end
		end		
	end
%------------------------------------------------------------------%
	function [bAbort, bCorrect, tResponse] = DoRecall(kBlock, tNow, ~)		
		bAbort = false;
		kCorrect = mwpi.Experiment.Input.Get(conditional(mwpi.rMatch(kRun,kBlock),'match','noMatch'));
		
		arrResponse = mwpi.Experiment.Info.Get('mwpi','bRecallResponse');
		if isempty(arrResponse)
			arrResponse = false(mwpi.maxRun, mwpi.nBlock);
		end
		
		% if a response has been logged, don't check for another.
		if arrResponse(kRun,kBlock)
			bCorrect = [];
			tResponse = [];
			mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
			return
		end
		
		% check for a response
		[~,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
		if kButton == kCorrect
			tResponse = tNow;
			bResponse = true;
			bCorrect = true;
		elseif ~isempty(kButton)
			tResponse = tNow;
			bResponse = true;
			bCorrect = false;
		else
			tResponse = [];
		end
		
		if bResponse
			arrResponse(kRun,kBlock) = true;
			mwpi.Experiment.Info.Set('mwpi','bRecallResponse',arrResponse);
			% show feedback
			if bCorrect
				mwpi.Experiment.Show.Texture(hRecallYes);
				mwpi.Experiment.Window.Flip('correct response');
			else
				mwpi.Experiment.Show.Texture(hRecallNo);
				mwpi.Experiment.Window.Flip('incorrect response');
			end
		end		
		
	end
end