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

% global vars so cleanup will work
global exp;
exp = mwpi.Experiment;
global sResults;
sResults = [];
global sRun;
sRun = struct('res',[]);
global sHandle;
sHandle = [];
global finished;
finished = false;

% cleanup function
cleanupObj = onCleanup(@cleanupfn);

% parse arguments
opt = ParseArgs(varargin, 'mapping', true);

% calculate which run to execute
sResults = exp.Info.Get('mwpi','result');
kRun = numel(sResults) + 1;

if kRun > mwpi.nRun
    bContinue = exp.Prompt.YesNo(['Current run (' num2str(kRun) ...
        ') exceeds planned number of runs (' num2str(mwpi.nRun) '). Continue?'], ...
        'mode', 'command_window');
    if ~bContinue
        return;
    end
end

exp.AddLog(['Starting run ' num2str(kRun) ' of ' num2str(mwpi.nRun)]);

% show the mapping
if opt.mapping
    mwpi.Mapping('wait',false);
	exp.Window.Flip('waiting for scanner');
end

% scanner starts
tRun = MWPI.Param('time','run');
exp.Scanner.StartScan(tRun);

% get run ready
sRun = mwpi.PrepRun;
sRun.res = [];

% perform the run

	% shared variables
    kBlock = 0;
    nCorrect = 0;
    sRun.res = [];
		
	% initialize texture handles
	sHandle.prompt = exp.Window.OpenTexture('prompt');
	sHandle.task = exp.Window.OpenTexture('task');
    sHandle.probe = exp.Window.OpenTexture('probe');
    sHandle.probeYes = exp.Window.OpenTexture('probeYes');
    sHandle.probeNo = exp.Window.OpenTexture('probeNo');
    sHandle.done = exp.Window.OpenTexture('done');
    
    % make done screen
    exp.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
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
                         trBlock
                         trFeedback
                         trPost
                         1
                         ]) + 1;
								
	% go!
    
	[sRun.tStart, sRun.tEnd, sRun.tSequence, sRun.bAbort] = ...
		exp.Sequence.Linear(cF,tSequence, ...
		'tstart',1,			...
		'tbase','absolute' ...
		);
	
	% scanner ends
	exp.Scanner.StopScan;

% finish up
exp.AddLog(['Run ' num2str(kRun) ' complete']);

finished = true;
clear cleanupObj;
%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, ~)
        % Blank the screen, and if there is another block coming up,
        % prepare the textures for that block.
        
        if kBlock == 0
            mwpi.Mapping('wait',false);
        else
            exp.Show.Blank;
        end
        
        exp.Window.Flip;
        
        if kBlock < mwpi.nBlock
            kBlock = kBlock + 1;
            mwpi.PrepTextures(sRun, kBlock);
        end
        
        exp.Scheduler.Wait;
    end
%---------------------------------------------------------------------%
    function tNow = DoBlock(tNow, ~)
        % Run a block, then save the results.
        
        exp.AddLog(['block ' num2str(kBlock) ' start']);
        
        resCur = mwpi.Block(sRun, kBlock, sHandle);
        
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
            bCorrect = sRun.res(end).bCorrect;
            
            % add a log message
            nCorrect    = nCorrect + bCorrect;
            strCorrect  = conditional(bCorrect,'y','n');
            strTally    = [num2str(nCorrect) '/' num2str(kBlock)];
            
            exp.AddLog(['feedback (' strCorrect ', ' strTally ')']);
            
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
            
            exp.Show.Text(strText,[0,MWPI.Param('text','offset')], ...
                'window', winFeedback);
        else
            winFeedback = 'task';                
        end
        
        exp.Show.Texture(winFeedback);
        exp.Window.Flip;
    end
%----------------------------------------------------------------------------------%
    function  tNow = DoDone(tNow,~)
        exp.Show.Texture(sHandle.done);
        exp.Window.Flip;
    end
%-----------------------------------------------------------------------------------%
end

    function cleanupfn
        % cleanup if the run is interrupted / when it ends
        global sHandle;
        global exp;
        global sRun;
        global sResults;
        global finished;
        
        % close textures
        if isstruct(sHandle)
            cellfun(@(tName) exp.Window.CloseTexture(tName), fieldnames(sHandle));
        end
        exp.Window.AddLog('Textures closed.');

        
        % save results 
        if ~isempty(sRun.res)
            if ~finished
                bSave = exp.Prompt.YesNo('WARNING: Run was not finished. Save results?', ...
                    'mode','command_window');
            else
                bSave = true;
            end
            
            if bSave
                if isempty(sResults)
                    sResults = sRun;
                else
                    sResults(end+1) = sRun;
                end
                exp.Info.Set('mwpi','result',sResults);
                exp.Info.AddLog('Results saved.');
            end
        end
    end
