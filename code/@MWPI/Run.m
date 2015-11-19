function Run(mwpi)
% Run - do an MWPI run.
% 
% Syntax: mwpi.Run
%
% Updated: 2015-06-24
%

% global vars so cleanup will work
% even though they are global they are NOT used outside of this file!
global mwpi_g;
mwpi_g = mwpi;
global sRun;
sRun = struct('res',[], 'tStart', [], 'tEnd', [], 'tSequence', [], 'bAbort',[]);
global sHandle;
sHandle = [];
global finished;
finished = false; %#ok<NASGU>
global kRun;

% cleanup function
cleanupObj = onCleanup(@cleanupfn);

exp = mwpi.Experiment;
strDomain = conditional(mwpi.bPractice, 'practice', 'exp');

if mwpi.nRun > 1
	% calculate default run to execute
	sResults = exp.Info.Get('mwpi','run');
	kRunDefault = min([numel(sResults) + 1, mwpi.nRun]);
	kRun = 0;

	% prompt which run to run
	while ~ismember(kRun, 1:mwpi.nRun)
		kRunInput = exp.Prompt.Ask(['Which run (max=', num2str(mwpi.nRun),')'],...
			'mode','command_window','default', num2str(kRunDefault));
		kRun = str2double(kRunInput);
	end
else
	kRun = 1;
end

exp.AddLog(['Starting run ' num2str(kRun) ' of ' num2str(mwpi.nRun)]);

ListenChar(2);

% scanner starts
tRun = MWPI.Param(strDomain,'run','time');
exp.Scanner.StartScan(tRun);


% perform the run

	% shared variables
    kBlock = 0;
    mwpi.nCorrect = 0;
	
	% initialize texture handles
	sHandle.stim		= exp.Window.OpenTexture('stim');
	sHandle.arrow		= exp.Window.OpenTexture('arrow');
	sHandle.retention	= exp.Window.OpenTexture('retention'); 
	sHandle.test		= exp.Window.OpenTexture('test');
	sHandle.testYes		= exp.Window.OpenTexture('testYes');
	sHandle.testNo		= exp.Window.OpenTexture('testNo');    

    % set up sequence %
    cF = [	repmat({@DoRest; @DoBlock}, mwpi.nBlock,1)
            {@DoDone}
          ];
      
    trBlock		= MWPI.Param('exp','block','time');
    trRest		= MWPI.Param('exp','rest','time');
	trPost		= MWPI.Param('exp','post','time');
      
    tSequence = cumsum([ repmat([trRest; trBlock], mwpi.nBlock, 1)
						 trPost
                         ]) + 1;
	
	fUpdateLevel = MWPI.Param(strDomain,'fUpdateLevel');
	
								
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
ListenChar(0);
exp.AddLog(['Run ' num2str(kRun) ' complete']);

finished = true;
clear cleanupObj;

%======================= Nested Functions ==========================%

%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, ~)
        % Blank the screen, update the level, and
        % prepare the textures for the next block.
        
        exp.Show.Blank;       
        exp.Window.Flip;        
		
		kBlock = kBlock + 1;
		
		if kBlock > 1
			mwpi.level = fUpdateLevel(sRun.res, mwpi.sParam, kRun);
		end
		
        mwpi.PrepTextures(kRun, kBlock, mwpi.level);
        
        exp.Scheduler.Wait;
	end
%---------------------------------------------------------------------%
    function tNow = DoBlock(tNow, ~)
        % Run a block, then save the results.
        
        exp.AddLog(['block ' num2str(kBlock) ' start']);
        
        resCur = mwpi.Block(kRun, kBlock, sHandle);
		
		resCur.level =  mwpi.level;
        
        if isempty(sRun.res)
            sRun.res = resCur;
        else
            sRun.res(end+1) = resCur;
        end    
	end

%--------------------------------------------------------------------%
	function tNow = DoDone(tNow, ~)
		% show the done screen
		
		exp.Show.Blank('fixation',false);
		exp.Window.Flip;
		
		mwpi.level = fUpdateLevel(sRun.res);

		% wait for a second
		pause(1);
		
		exp.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
			'><color:' MWPI.Param('text','colDone') '>RELAX!</color></size>']);
		exp.Window.Flip;
		
		exp.Scheduler.Wait;
	end
end
% ==================== Local Functions =============================%

    function cleanupfn
        % cleanup if the run is interrupted / when it ends
        global sHandle;
        global mwpi_g;
        global sRun;
        global finished;
		global kRun;
		
		exp = mwpi_g.Experiment;
        
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
				sRuns = exp.Info.Get('mwpi','run');
				if isempty(sRuns)
					sRuns = sRun;
				else
					sRuns(kRun) = sRun;   
				end
                exp.Info.Set('mwpi','run', sRuns);
				exp.Info.Set('mwpi','currLevel',mwpi_g.level);
				exp.Info.Set('mwpi','currReward',mwpi_g.reward);
                exp.Info.AddLog('Results saved.');
				
				if mwpi_g.bPractice
					bCalc = exp.Prompt.YesNo('Calculate subject''s threshold levels?', ...
						'mode', 'command_window');
					if bCalc
						threshold = MWPI.CalcThreshold(sRun.res, mwpi_g.sParam, kRun);
						exp.Subject.Set('threshold', threshold);
						exp.Subject.AddLog('Threshold saved to subject info.');
					end
				end
            end
        end
	end
