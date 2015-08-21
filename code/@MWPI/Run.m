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
                         trBlock
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

end