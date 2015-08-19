function Run(mwpi, varargin)
% Run - do an MWPI run.
% 
% Syntax: mwpi.Run(<options>)
%
% In:
%	options:
%		'mapping'	(true) Show the mapping before the run, until the scanner starts
%
% Updated: 2015-06-24
%

% parse arguments
opt = ParseArgs(varargin, 'mapping', true);

% calculate which run to execute
sResults = mwpi.Experiment.Info.Get('mwpi','result');
kRun = numel(sResults) + 1;

if kRun > mwpi.nRun
    bContinue = mwpi.Experiment.Prompt.YesNo(['Current run (' num2str(kRun) ...
        ') exceeds planned number of runs (' num2str(mwpi.nRun) '). Continue?'], ...
        'mode', 'command_window');
    if ~bContinue
        return;
    end
end

mwpi.Experiment.AddLog(['Starting run ' num2str(kRun) ' of ' num2str(mwpi.nRun)]);

% show the mapping
if opt.mapping
    mwpi.Mapping('wait',false);
	mwpi.Experiment.Window.Flip('waiting for scanner');
end

% scanner starts
tRun = MWPI.Param('time','run');
mwpi.Experiment.Scanner.StartScan(tRun);

% get run ready
sRun = mwpi.PrepRun;

% perform the run

	% shared variables
    kBlock = 0;
    nCorrect = 0;
    sRun.res = [];
		
	% initialize texture handles
	sHandle.prompt = mwpi.Experiment.Window.OpenTexture('prompt');
	sHandle.task = mwpi.Experiment.Window.OpenTexture('task');
    sHandle.probe = mwpi.Experiment.Window.OpenTexture('probe');
    sHandle.probeYes = mwpi.Experiment.Window.OpenTexture('probeYes');
    sHandle.probeNo = mwpi.Experiment.Window.OpenTexture('probeNo');
    sHandle.done = mwpi.Experiment.Window.OpenTexture('done');
    
    % make done screen
    mwpi.Experiment.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
        '><color:' MWPI.Param('text','colDone') '>RELAX!</color></size>'], ...
        'window','done');

    % set up sequence %
    cF = [  repmat({@DoRest; @DoBlock; @DoFeedback}, [mwpi.nBlock, 1])
            {@DoRest}
            {@DoDone}
          ];
      
    trMapping = MWPI.Param('time','mapping');
    trBlock = MWPI.Param('time', 'block');
    trFeedback = MWPI.Param('time','feedback');
    trRest = MWPI.Param('time','rest');
    trPost = MWPI.Param('time','postrun');
      
    tSequence = cumsum([ trMapping
                         repmat([trBlock; trFeedback; trRest], [mwpi.nBlock-1,1])
                         trTrial
                         trFeedback
                         trPost
                         1
                         ]) + 1;
								
	% go!
    
	[sRun.tStart, sRun.tEnd, sRun.tSequence, sRun.bAbort] = ...
		mwpi.Experiment.Sequence.Linear(cF,tSequence, ...
		'tstart',1,			...
		'tbase','absolute' ...
		);
	
	% scanner ends
	mwpi.Experiment.Scanner.StopScan;

% save results 
if isempty(sResults)
	sResults = sRun;
else
	sResults(end+1) = sRun;
end
mwpi.Experiment.Info.Set('mwpi','result',sResults);
mwpi.Experiment.Info.AddLog('Results saved.');

% close textures
cellfun(@(tName) mwpi.Experiment.Window.CloseTexture(tName), fieldnames(sHandle));

% finish up
mwpi.Experiment.AddLog(['Run ' num2str(kRun) ' complete']);

%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, ~)
        % Blank the screen, and if there is another block coming up,
        % prepare the textures for that block.
        
        if kBlock == 0
            mwpi.Mapping('wait',false);
        else
            mwpi.Experiment.Show.Blank;
        end
        
        mwpi.Experiment.Window.Flip;
        
        if kBlock < mwpi.nBlock
            kBlock = kBlock + 1;
            mwpi.PrepTextures(sRun, kBlock);
        end
        
        mwpi.Experiment.Scheduler.Wait;
    end
%---------------------------------------------------------------------%
    function tNow = DoBlock(tNow, ~)
        % Run a block, then save the results.
        
        mwpi.Experiment.AddLog(['block ' num2str(kBlock) ' start']);
        
        resCur = mwpi.Block(kRun, kBlock, sHandle);
        
        if isempty(sRun.res)
            sRun.res = resCur;
        else
            sRun.res(end+1) = resCur;
        end    
    end
%--------------------------------------------------------------------%
    function tNow = DoFeedback(tNow, ~)
        % if probe, update correct total, reward, show feedback screen
        
        if sRun.bProbe(kBlock)            
            bCorrect = sRun.res(end).correct;
            
            % add a log message
            nCorrect    = nCorrect + bCorrect;
            strCorrect  = conditional(bCorrect,'y','n');
            strTally    = [num2str(nCorrect) '/' num2str(kBlock)];
            
            mwpi.Experiment.AddLog(['feedback (' strCorrect ', ' strTally ')']);
            
            % show feedback texture and updated reward
            if bCorrect
                winFeedback = 'probeYes';
                strFeedback = 'Yes!';
                strColor = MWPI.Param('text','colYes');
                dWinning = MWPI.Param('reward','rewardPerBlock');
            else
                winFeedback = 'probeNo';
                strFeedback = 'No!';
                strColor = MWPI.Param('text','colNo');
                dWinning = -MWPI.Param('reward','penaltyPerBlock');
            end
            mwpi.reward = max(mwpi.reward + dWinning, MWPI.Param('reward','base'));
            
            strText = ['<color:' strColor '>' strFeedback ' (' ...
                StringMoney(dWinning,'sign',true) ')</color>\nCurrent total: ' ...
                StringMoney(mwpi.reward)];
            
            mwpi.Experiment.Show.Text(strText,[0,MWPI.Param('text','offset')], ...
                'window', winFeedback);
        else
            winFeedback = 'task';                
        end
        
        mwpi.Experiment.Show.Texture(winFeedback);
        mwpi.Experiment.Window.Flip;
    end


% %--------------------------------------------------------------------%
%     function cX = SetupStimuli
%         
%         % Set up the cell of stimuli for the run sequence.
%         
%         cRSVP = arrayfun(@(kTrial) ...
%             {arr_hTask(kTrial)              % response screen
%              arr_hTask(kTrial)              % buffer to allow correct feedback
%              {@ShowTaskFeedback, kTrial}    % feedback screen
%             }, ...
%             (1:mwpi.RSVPLength)','uni',false);
%         
%         cRSVP = vertcat(cRSVP{:});
%         
%         cRest = {{'Blank'}   % rest / prerun
%             {'Blank'}}; % preblock
%         
%         cBlock = [hPrompt
%                   {{'Blank'}}
%                   cRSVP
%                   hRecall
%                   hRecall % buffer to allow correct feedback
%                   {@ShowRecallFeedback}
%                   ];
%         
%         cPost = {{'Blank'}}; % postrun
%         
%         cX = [repmat([cRest
%                       cBlock
%                       ], mwpi.nBlock,1)
%               cPost
%              ];
%     end
% %--------------------------------------------------%
% 	function ShowTaskFeedback(kTrial, varargin)
% 		% Show the appropriate task feedback screen
% 		
% 		myOpt = ParseArgs(varargin, 'window', []);
% 		
% 		if isempty(bLastCorrect)
% 			arr_hFeedback = arr_hTask;
% 		elseif bLastCorrect
% 			arr_hFeedback = arr_hTaskYes;
% 		else
% 			arr_hFeedback = arr_hTaskNo;
% 		end
% 		
% 		bLastCorrect = [];
% 		
% 		mwpi.Experiment.Show.Texture(arr_hFeedback(kTrial), 'window',myOpt.window);
%         
%         bClearSerialWaitTask = true; % for next task
% 	end
% %----------------------------------------------%
% 	function ShowRecallFeedback(varargin)
% 		% show the appropriate recall feedback screen
% 		
% 		myOpt = ParseArgs(varargin, 'window', []);
% 		
% 		if isempty(bLastCorrect)
% 			hFeedback = hRecall;
% 		elseif bLastCorrect
% 			hFeedback = hRecallYes;
% 		else
% 			hFeedback = hRecallNo;
% 		end
% 		
% 		bLastCorrect = [];
% 		
% 		mwpi.Experiment.Show.Texture(hFeedback, 'window', myOpt.window);
%         
%         bClearSerialWaitTask = true; % for next task
%     end
% %-----------------------------------------------------------------------%
%     function tShow = SetupTiming
%         
%         % set up the timing for the run sequence
%         
%         tBlock = [MWPI.Param('time','preblock')
%                   MWPI.Param('time','prompt')
%                   MWPI.Param('time','blank')
%                   repmat(MWPI.Param('time','task'),mwpi.RSVPLength,1)
%                   MWPI.Param('time','recall')];
% 	
%         % tShowAbs: the absolute transition times (does not include transitions
%         % to feedback screens)
%         tShowAbs = cumsum([MWPI.Param('time','prerun')
%                            repmat([tBlock
%                                    MWPI.Param('time','rest')
%                                    ],mwpi.nBlock-1,1)
%                            tBlock
%                            MWPI.Param('time','postrun')
%                           ]);
% 	
%         % during which elements of tShowTemp are we expecting a response?
%         bResponseStimuli = [repmat([false % rest / prerun
%                                     false % preblock
%                                     false % prompt
%                                     false % blank
%                                     true(mwpi.RSVPLength + 1,1) % trials and recall                                
%                                     ],mwpi.nBlock,1)
%                             false % postrun
%                             ];
% 	
%         tAfterFeedback = tShowAbs(bResponseStimuli);
% 	
%         % control transition to buffer and feedback stimuli
%         tShow = num2cell(tShowAbs);
%         tShow(bResponseStimuli) = arrayfun(@(tNext) ...
%             {@(tNow) MoveToFeedback(tNow, tNext)% task
%              @(tNow) deal(false, true)          % buffer (move immediately)
%              tNext},...                           feedback
% 		tAfterFeedback, 'uni',false);
% 	
%         tShow = cellnestflatten(tShow);
%     end
% %-------------------------------------------%
% 	function [bAbort, bShow] = MoveToFeedback(tNow, tNext)
% 		% return whether to show the feedback screen
% 		bAbort = false;
% 		% move on if there has been a response or it's time for the next
% 		% stimulus
% 		if tNow >= tNext || bResponse
% 			bResponse = false;
% 			bShow = true;
% 		else
% 			bShow = false;
% 		end
%     end
% %--------------------------------------------------------------------%
%     function fwait = SetupWaitFuncs
%         fwait = [arrayfun(@(kBlock) ...
%                     [{{@(tNow,tNext) WaitRest(kBlock,tNow,tNext)}}   % prerun / rest
%                      {{@WaitDefault}}                                % preblock
%                      {{@WaitDefault}}                                % prompt
%                      {{@WaitDefault}}                                % blank
% 
%                      % RSVP stream
%                      arrayfun(@(kTrial) ...
%                          {@(tNow,tNext) WaitTask(mwpi.match(kRun,kBlock,kTrial),tNow,tNext)
%                           false          % buffer
%                           @WaitDefault   % feedback
%                          },...
%                         (1:mwpi.RSVPLength)','uni',false)
% 
%                      % recall    
%                      {{@(tNow,tNext) WaitTask(mwpi.rMatch(kRun,kBlock),tNow,tNext)}}
%                      false            % buffer
%                      {{@WaitDefault}}   % feedback
% 					], (1:mwpi.nBlock)','uni',false);
%              {{@WaitDefault}} % postrun
%              ];
%          
%         fwait = cellnestflatten(fwait);
%     end
% %----------------------------------%
%     function [bAbort, bCorrect, tResponse] = WaitDefault(~, tNext)
%         % wait and perform tasks in the background
%         
%         bAbort = false;
%         bCorrect = [];
%         tResponse = [];
%         
%         % clear shared vars
%         bResponse = false;
%         bLastCorrect = [];
%         bTexturesPrepared = false;
%         
%         tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
%         
%         WaitSecs(0.001);
%         mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_NORMAL, tNextms);
%     end
% %--------------------------------------%
% 	function [bAbort, bCorrect, tResponse] = WaitRest(kBlock, ~, tNext)
%         % prepare textures while while resting between blocks.
% 				
% 		if ~bTexturesPrepared
%             bTexturesPrepared = true;
% 		end
% 		
% 		% wait
%         bAbort = false;
%         bCorrect = [];
%         tResponse = [];
%         
%         tNextms = mwpi.Experiment.Scanner.TR2ms(tNext);
%         
%         WaitSecs(0.001);
%         mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_IDLE, tNextms);
% 	end
% %---------------------------------------%
% 	function [bAbort, bCorrect, tResponse] = WaitTask(bMatch, tNow, ~)
% 		% Listen for responses during the task stage
% 		
% 		bAbort = false;
% 		kCorrect = cell2mat(mwpi.Experiment.Input.Get(conditional(bMatch,'match','noMatch')));
% 		
% 		% if a response has been logged, don't check for another.
%         if bResponse
% 			bCorrect = [];
% 			tResponse = [];
% 			return
%         end
%         
%         bLastCorrect = [];        
% 		
% 		% check for a response
%         if bClearSerialWaitTask
%             mwpi.Experiment.Serial.Clear;
%             bClearSerialWaitTask = false;
%         end
%         
% 		[bResp,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
% 		if ~bResp
% 			tResponse = [];
% 			bCorrect = [];
% 		else		
% 			tResponse = tNow;
% 			bCorrect = all(ismember(kButton, kCorrect));
% 		end
% 		bLastCorrect = bCorrect;
% 		bResponse = bResp;
%     end

end