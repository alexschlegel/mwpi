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

	% shared variables
    bResponse = false;
	bLastCorrect = [];
    bClearSerialWaitTask = true;
    bTexturesPrepared = false;
		
	% initialize texture handles
	hPrompt = mwpi.Experiment.Window.OpenTexture('prompt');
	arr_hTask = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['task',num2str(i)]),...
				(1:mwpi.RSVPLength)');
	arr_hTaskYes = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['taskYes',num2str(i)]),...
				(1:mwpi.RSVPLength)');
	arr_hTaskNo = arrayfun(@(i) mwpi.Experiment.Window.OpenTexture(['taskNo',num2str(i)]),...
				(1:mwpi.RSVPLength)');
	hRecall = mwpi.Experiment.Window.OpenTexture('recall');
	hRecallYes = mwpi.Experiment.Window.OpenTexture('recallYes');
	hRecallNo = mwpi.Experiment.Window.OpenTexture('recallNo');


    % set up sequence %
    cX = SetupStimuli;
    tShow = SetupTiming;
    fwait = SetupWaitFuncs;
    	
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
			(1:mwpi.RSVPLength)');
arrayfun(@(i) mwpi.Experiment.Window.CloseTexture(['taskYes',num2str(i)]),...
			(1:mwpi.RSVPLength)');
arrayfun(@(i) mwpi.Experiment.Window.CloseTexture(['taskNo',num2str(i)]),...
			(1:mwpi.RSVPLength)');
mwpi.Experiment.Window.CloseTexture('recall');
mwpi.Experiment.Window.CloseTexture('recallYes');
mwpi.Experiment.Window.CloseTexture('recallNo');

% finish up
mwpi.Experiment.AddLog(['Run ' num2str(kRun) ' complete']);
mwpi.runsComplete(kRun) = true;
mwpi.Experiment.Info.Set('mwpi','runsComplete',mwpi.runsComplete);


%--------------------------------------------------------------------%
    function cX = SetupStimuli
        
        % Set up the cell of stimuli for the run sequence.
        
        cRSVP = arrayfun(@(kTrial) ...
            {arr_hTask(kTrial)              % response screen
             arr_hTask(kTrial)              % buffer to allow correct feedback
             {@ShowTaskFeedback, kTrial}    % feedback screen
            }, ...
            (1:mwpi.RSVPLength)','uni',false);
        
        cRSVP = vertcat(cRSVP{:});
        
        cRest = {{'Blank'}   % rest / prerun
            {'Blank'}}; % preblock
        
        cBlock = [hPrompt
                  {{'Blank'}}
                  cRSVP
                  hRecall
                  hRecall % buffer to allow correct feedback
                  {@ShowRecallFeedback}
                  ];
        
        cPost = {{'Blank'}}; % postrun
        
        cX = [repmat([cRest
                      cBlock
                      ], mwpi.nBlock,1)
              cPost
             ];
    end
%--------------------------------------------------%
	function ShowTaskFeedback(kTrial, varargin)
		% Show the appropriate task feedback screen
		
		opt = ParseArgs(varargin, 'window', []);
		
		if isempty(bLastCorrect)
			arr_hFeedback = arr_hTask;
		elseif bLastCorrect
			arr_hFeedback = arr_hTaskYes;
		else
			arr_hFeedback = arr_hTaskNo;
		end
		
		bLastCorrect = [];
		
		mwpi.Experiment.Show.Texture(arr_hFeedback(kTrial), 'window',opt.window);
        
        bClearSerialWaitTask = true; % for next task
	end
%----------------------------------------------%
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
        
        bClearSerialWaitTask = true; % for next task
    end
%-----------------------------------------------------------------------%
    function tShow = SetupTiming
        
        % set up the timing for the run sequence
        
        tBlock = [MWPI.Param('time','preblock')
                  MWPI.Param('time','prompt')
                  MWPI.Param('time','blank')
                  repmat(MWPI.Param('time','task'),mwpi.RSVPLength,1)
                  MWPI.Param('time','recall')];
	
        % tShowAbs: the absolute transition times (does not include transitions
        % to feedback screens)
        tShowAbs = cumsum([MWPI.Param('time','prerun')
                           repmat([tBlock
                                   MWPI.Param('time','rest')
                                   ],mwpi.nBlock-1,1)
                           tBlock
                           MWPI.Param('time','postrun')
                          ]);
	
        % during which elements of tShowTemp are we expecting a response?
        bResponseStimuli = [repmat([false % rest / prerun
                                    false % preblock
                                    false % prompt
                                    false % blank
                                    true(mwpi.RSVPLength + 1,1) % trials and recall                                
                                    ],mwpi.nBlock,1)
                            false % postrun
                            ];
	
        tAfterFeedback = tShowAbs(bResponseStimuli);
	
        % control transition to buffer and feedback stimuli
        tShow = num2cell(tShowAbs);
        tShow(bResponseStimuli) = arrayfun(@(tNext) ...
            {@(tNow) MoveToFeedback(tNow, tNext)% task
             @(tNow) deal(false, true)          % buffer (move immediately)
             tNext},...                           feedback
		tAfterFeedback, 'uni',false);
	
        tShow = cellnestflatten(tShow);
    end
%-------------------------------------------%
	function [bAbort, bShow] = MoveToFeedback(tNow, tNext)
		% return whether to show the feedback screen
		bAbort = false;
		% move on if there has been a response or it's time for the next
		% stimulus
		if tNow >= tNext || bResponse
			bResponse = false;
			bShow = true;
		else
			bShow = false;
		end
    end
%--------------------------------------------------------------------%
    function fwait = SetupWaitFuncs
        fwait = [arrayfun(@(kBlock) ...
                    [{{@(tNow,tNext) WaitRest(kBlock,tNow,tNext)}}   % prerun / rest
                     {{@WaitDefault}}                                % preblock
                     {{@WaitDefault}}                                % prompt
                     {{@WaitDefault}}                                % blank

                     % RSVP stream
                     arrayfun(@(kTrial) ...
                         {@(tNow,tNext) WaitTask(mwpi.match(kRun,kBlock,kTrial),tNow,tNext)
                          false          % buffer
                          @WaitDefault   % feedback
                         },...
                        (1:mwpi.RSVPLength)','uni',false)

                     % recall    
                     {{@(tNow,tNext) WaitTask(mwpi.rMatch(kRun,kBlock),tNow,tNext)}}
                     false            % buffer
                     {{@WaitDefault}}   % feedback
					], (1:mwpi.nBlock)','uni',false);
             {{@WaitDefault}} % postrun
             ];
         
        fwait = cellnestflatten(fwait);
    end
%----------------------------------%
    function [bAbort, bCorrect, tResponse] = WaitDefault(~, tNext)
        % wait and perform tasks in the background
        
        bAbort = false;
        bCorrect = [];
        tResponse = [];
        
        % clear shared vars
        bResponse = false;
        bLastCorrect = [];
        bTexturesPrepared = false;
        
        tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
        
        WaitSecs(0.001);
        mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_NORMAL, tNextms);
    end
%--------------------------------------%
	function [bAbort, bCorrect, tResponse] = WaitRest(kBlock, ~, tNext)
        % prepare textures while while resting between blocks.
				
		if ~bTexturesPrepared
			mwpi.PrepTextures(kRun, kBlock);
            bTexturesPrepared = true;
		end
		
		% wait
        bAbort = false;
        bCorrect = [];
        tResponse = [];
        
        tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
        
        WaitSecs(0.001);
        mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_IDLE, tNextms);
	end
%---------------------------------------%
	function [bAbort, bCorrect, tResponse] = WaitTask(bMatch, tNow, ~)
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
        if bClearSerialWaitTask
            mwpi.Experiment.Serial.Clear;
            bClearSerialWaitTask = false;
        end
        
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

end