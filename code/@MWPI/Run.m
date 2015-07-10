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

	% used for feedback
    bResponse = false;
	bLastCorrect = [];
	
	%-- set up sequence --%
	
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

	trialSequence = arrayfun(@(kTrial) ...
						{hTask{kTrial}
                         hTask{kTrial} % buffer to allow correct feedback
						 {@ShowTaskFeedback, kTrial}
						}, ...
				  (1:mwpi.RSVPLength)','uni',false);
	
	cX = [repmat([{{'Blank'}} % pre-run
                  {{'Blank'}} % last TR before block
				  hPrompt
				  {{'Blank'}}
				  vertcat(trialSequence{:})
				  hRecall
                  hRecall % buffer to allow correct feedback
				  {@ShowRecallFeedback}
				  ], mwpi.nBlock,1)
		  {{'Blank'}} % post-run
          ];
								
	tBlock = [MWPI.Param('time','prompt')
			  MWPI.Param('time','blank')
			  repmat(MWPI.Param('time','task'),mwpi.RSVPLength,1)
			  MWPI.Param('time','recall')];
		  
	tShowTemp = num2cell(cumsum([MWPI.Param('time','prepost')
                                 repmat([1 % last TR before block
                                         tBlock
                                         MWPI.Param('time','rest') - 1
                                        ],mwpi.nBlock-1,1)
                                 1 % last TR before last block
                                 tBlock % last block
                                 MWPI.Param('time','prepost')
                                ]));
	
	% during which elements of tShowTemp are we expecting a response?
	bResponseStimuli = [false % pre-trial                        
						repmat([false % last TR before block
                                false % prompt
                                false % blank
                                true(mwpi.RSVPLength + 1,1) % trials and recall
                                false % rest / post-trial
                                ],mwpi.nBlock,1)
						];
	
	tNextStimuli = tShowTemp(bResponseStimuli);
	
	% insert a function call after each response stimulus to determine when to show feedback.
	tShow = tShowTemp;
	tShow(bResponseStimuli) = cellfun(@(tNext) {@(tNow) MoveToFeedback(tNow, tNext)
                                                @(tNow) deal(false, true) % move immediately
                                                tNext},...
		tNextStimuli, 'uni',false);
	
	tShow = cellnestflatten(tShow);
	
	fwait = arrayfun(@(kBlock) [{@(tNow,tNext) DoRest(kBlock,tNow,tNext)}
                                {@WaitDefault} % last TR before block
								{@WaitDefault} % prompt
								{@WaitDefault} % blank
								cellnestflatten(arrayfun(@(kTrial) ...
									 {@(tNow,tNext) DoTask(mwpi.match(kRun,kBlock,kTrial),tNow,tNext)
                                     false
									 @WaitDefault
									 },...
									(1:mwpi.RSVPLength)','uni',false))
								{@(tNow,tNext) DoTask(mwpi.rMatch(kRun,kBlock),tNow,tNext)}
                                false
								{@WaitDefault}
								], (1:mwpi.nBlock)','uni',false);
	fwait = vertcat(fwait{:},{@WaitDefault});
	
	% scanner starts
	tRun = MWPI.Param('time','run');
	mwpi.Experiment.Scanner.StartScan(tRun);
								
	% go!
	[cRun.tStart, cRun.tEnd, cRun.tShow, cRun.bAbort, cRun.bCorrect, cRun.tResponse] = ...
		mwpi.Experiment.Show.Sequence(cX,tShow, ...
		'tstart',1,			...
		'tbase','absolute', ...
		'fixation',false,	...
		'fwait', fwait		...
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

% close textures
mwpi.Experiment.Window.CloseTexture('prompt');
arrayfun(@(i) mwpi.Experiment.Window.CloseTexture(['task',num2str(i)]),...
			(1:mwpi.RSVPLength)','uni',false);
arrayfun(@(i) mwpi.Experiment.Window.CloseTexture(['taskYes',num2str(i)]),...
			(1:mwpi.RSVPLength)','uni',false);
arrayfun(@(i) mwpi.Experiment.Window.CloseTexture(['taskNo',num2str(i)]),...
			(1:mwpi.RSVPLength)','uni',false);
mwpi.Experiment.Window.CloseTexture('recall');
mwpi.Experiment.Window.CloseTexture('recallYes');
mwpi.Experiment.Window.CloseTexture('recallNo');

% finish up
mwpi.Experiment.AddLog(['Run ' num2str(kRun) ' complete']);
mwpi.runsComplete(kRun) = true;
mwpi.Experiment.Info.Set('mwpi','runsComplete',mwpi.runsComplete);

%--------------------------------------------------------------------%
	function [bAbort, bShow] = MoveToFeedback(tNow, tNext)
		% return whether to show the feedback screen
		bAbort = false;
		% move on if there has been a response or it's time for the next
		% stimulus
		if tNow >= tNext || bResponse
            tNow-tNext
			bResponse = false;
			bShow = true;
		else
			bShow = false;
		end
	end
%--------------------------------------------------------------------%
    function [bAbort, bCorrect, tResponse] = WaitDefault(~, tNext)
        % wait and perform tasks in the background
        
        bAbort = false;
        bCorrect = [];
        tResponse = [];
        
        % clear globals
        bResponse = false;
        bLastCorrect = [];
        
        tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
        
        WaitSecs(0.001);
        mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_NORMAL, tNextms);
    end
%--------------------------------------------------------------------%
	function [bAbort, bCorrect, tResponse] = DoRest(kBlock, ~, tNext)				
				
		% check if textures have been prepared
        persistent lastPrepared; % [kRun kBlock] of last set of textures prepared
		if isempty(lastPrepared) || ~all(lastPrepared == [kRun,kBlock])
			% prepare the textures for the next block.
			mwpi.PrepTextures(kRun, kBlock);
            lastPrepared = [kRun, kBlock];
		end
		
		% wait
        bAbort = false;
        bCorrect = [];
        tResponse = [];
        
        tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
        
        WaitSecs(0.001);
        mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_IDLE, tNextms);
	end
%-------------------------------------------------------------------%
	function [bAbort, bCorrect, tResponse] = DoTask(bMatch, tNow, ~)
		% Listen for responses during the task stage
		
		bAbort = false;
		kCorrect = cell2mat(mwpi.Experiment.Input.Get(conditional(bMatch,'match','noMatch')));
		
		% if a response has been logged, don't check for another.
        if bResponse
			bCorrect = [];
			tResponse = [];
			return
        end
        
        bLastCorrect = [];
		
		% check for a response
		[bResp,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
		if ~bResp
			tResponse = [];
			bCorrect = [];
		else		
			tResponse = tNow;
			bCorrect = all(ismember(kButton, kCorrect));			
		end
		bLastCorrect = bCorrect;
		bResponse = bResp;
    end
	%------------------------------------------------------------------------%
	function ShowTaskFeedback(kTrial, varargin)
		% Show the appropriate task feedback screen
		
		opt = ParseArgs(varargin, 'window', []);
		
		if isempty(bLastCorrect)
			cFeedback = hTask;
		elseif bLastCorrect
			cFeedback = hTaskYes;
		else
			cFeedback = hTaskNo;
		end
		
		bLastCorrect = [];
		
		mwpi.Experiment.Show.Texture(cFeedback{kTrial}, 'window',opt.window);
	end
	%------------------------------------------------------------------------%
	function ShowRecallFeedback(varargin)
		% show the appropriate recall feedback screen
		
		opt = ParseArgs(varargin, 'window', []);
		
		if isempty(bLastCorrect)
			hFeedback = hRecall;
		elseif bLastCorrect
			hFeedback = hRecallYes;
		else
			hFeedback = hRecallNo;
		end
		
		bLastCorrect = [];
		
		mwpi.Experiment.Show.Texture(hFeedback, 'window', opt.window);
	end
end