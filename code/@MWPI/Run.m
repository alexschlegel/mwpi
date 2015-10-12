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
finished = false;

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
sRun = mwpi.PrepRun;
sRun.res = [];

% perform the run

	% shared variables
    kBlock = 0;
    nCorrect = 0;
    sRun.res = [];
		
	% initialize texture handles
	sHandle.prompt		= exp.Window.OpenTexture('prompt');
	sHandle.retention	= exp.Window.OpenTexture('retention');
	sHandle.test		= exp.Window.OpenTexture('test');
    sHandle.done		= exp.Window.OpenTexture('done');
    
    % make done screen
    exp.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
        '><color:' MWPI.Param('text','colDone') '>RELAX!</color></size>'], ...
        'window','done');
	
	%----------------------- EDIT LINE ----------------------------%
	
	cFProbe   = {@DoBlock; @DoFeedback; @DoRest};
	cFNoProbe = {@DoBlock; @DoRest};
	
	cFTrials  = conditional(reshape(sRun.bProbe,[],1),cFProbe,cFNoProbe);
	cFTrials  = cellnestflatten(cFTrials);

    % set up sequence %
    cF = [  {@DoMapping}
			{@DoRest}
			cFTrials          
            {@DoDone}
          ];
      
    trMapping	= MWPI.Param('time','mapping');
	trPre		= MWPI.Param('time','pre');
    trBlock		= MWPI.Param('time', 'block');
    trFeedback	= MWPI.Param('time','feedback');
    trRest		= MWPI.Param('time','rest');
	
	tSeqProbe   = [trBlock; trFeedback; trRest];
	tSeqNoProbe = [trBlock; trRest];
	
	tSeqTrials = conditional(sRun.bProbe,{tSeqProbe},{tSeqNoProbe});
	
	% fix timing of probe blocks
	tSeqTrials = cellfun(@(tSeq, bP, kB) FixProbeTiming(tSeq,bP,sRun, kB), ...
		tSeqTrials, num2cell(sRun.bProbe),num2cell(1:mwpi.nBlock),'uni',false);
	
	tSeqTrials = cell2mat(reshape(tSeqTrials,[],1));
      
    tSequence = cumsum([ trMapping
						 trPre
                         tSeqTrials
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

%======================= Nested Functions ==========================%

%----------------------------------------------------------------------%
	function tNow = DoMapping(tNow, ~)
		% show the mapping
		
		if ~opt.mapping
			mwpi.Mapping('wait',false);
			exp.Window.Flip;
		end
		
		exp.Scheduler.Wait;
	end
%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, ~)
        % Blank the screen, and if there is another block coming up,
        % prepare the textures for that block.
        
        exp.Show.Blank;       
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

%----------------------------------------------------------------------%
	function tSeqTrials = FixProbeTiming(tSeqIn, bProbe, sRun, kBlock)
		% fix timing of probe blocks
		% since the probe onset timing is random, the time the probe blocks
		% end is also random, so we lengthen the feedback period to
		% compensate.
		
		if ~bProbe
			tSeqTrials = tSeqIn;
		else
			tBlock = MWPI.Param('time','prompt') + sRun.tProbe(kBlock) + ...
					 MWPI.Param('time','probe');
			tExtra = MWPI.Param('time','block') - tBlock;
			
			tSeqTrials = [ tSeqIn(1) - tExtra
						   tSeqIn(2) + tExtra
						   tSeqIn(3:end)
						 ];
		end
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
