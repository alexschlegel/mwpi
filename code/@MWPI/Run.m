function Run(mwpi)
% Run - do an MWPI run.
% 
% Syntax: mwpi.Run
%
% Updated: 2015-06-24
%

% global vars so cleanup will work
global exp;
exp = mwpi.Experiment;
global sResults;
global sRun;
sRun = struct('res',[]);
global sHandle;
sHandle = [];
global finished;
finished = false; %#ok<NASGU>

% cleanup function
cleanupObj = onCleanup(@cleanupfn);

% calculate default run to execute
sResults = exp.Info.Get('mwpi','result');
kRunDefault = min([numel(sResults) + 1, mwpi.nRun]);
kRun = 0;

while ~ismember(kRun, 1:mwpi.nRun)
	kRunInput = exp.Prompt.Ask(['Which run (max = ',mwpi.nRun,')'],...
		'mode','command_window','default',kRunDefault);
	kRun = str2double(kRunInput);
end

exp.AddLog(['Starting run ' num2str(kRun) ' of ' num2str(mwpi.nRun)]);

% scanner starts
tRun = MWPI.Param('time','run');
exp.Scanner.StartScan(tRun);

% get run ready
sRun.res = [];

% perform the run

	% shared variables
    kBlock = 0;
    nCorrect = 0;
    sRun.res = [];
		
	% initialize texture handles
	sHandle.prompt1		= exp.Window.OpenTexture('prompt1');
	sHandle.prompt2		= exp.Window.OpenTexture('prompt2');
	sHandle.cue			= exp.Window.OpenTexture('cue');
	sHandle.retention	= exp.Window.OpenTexture('retention'); 
	sHandle.test		= exp.Window.OpenTexture('test');
	sHandle.testYes		= exp.Window.OpenTexture('testYes');
	sHandle.testNo		= exp.Window.OpenTexture('testNo');
    sHandle.done		= exp.Window.OpenTexture('done');
    
    % make done screen
    exp.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
        '><color:' MWPI.Param('text','colDone') '>RELAX!</color></size>'], ...
        'window','done');

    % set up sequence %
    cF = [	{@DoRest}
			repmat({@DoBlock; @DoRest}, mwpi.nBlock,1)          
            {@DoDone}
          ];
      
    trBlock		= MWPI.Param('exp','block','time');
    trRest		= MWPI.Param('exp','rest','time');
      
    tSequence = cumsum([ trRest
                         repmat([trBlock; trRest], mwpi.nBlock, 1)
                         1
                         ]) + 1;
								
	% go!
    
	[sRun.tStart, sRun.tEnd, sRun.tSequence, sRun.bAbort] = ...
		exp.Sequence.Linear(cF,tSequence, ...
		'tstart',1,			...
		'tbase','absolute', ...
		'tunit','tr'		...
		);
	
	% scanner ends
	exp.Scanner.StopScan;

% finish up
exp.AddLog(['Run ' num2str(kRun) ' complete']);

finished = true;
clear cleanupObj;

%======================= Nested Functions ==========================%

%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, ~)
        % Blank the screen, and if there is another block coming up,
        % prepare the textures for that block.
        
        exp.Show.Blank;       
        exp.Window.Flip;
        
        if kBlock < mwpi.nBlock
            kBlock = kBlock + 1;
            mwpi.PrepTextures(kRun, kBlock);
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
        % update correct total, reward, show feedback screen
        
		bCorrect = sRun.res(end).bCorrect;

		% add a log message
		nCorrect    = nCorrect + bCorrect;
		strCorrect  = conditional(bCorrect,'y','n');
		strTally    = [num2str(nCorrect) '/' num2str(sRun.kProbe(kBlock))];

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

		exp.Show.Text(strText,[0,MWPI.Param('text','fbOffset')], ...
			'window', winFeedback);
      
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

% ==================== Local Functions =============================%

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
