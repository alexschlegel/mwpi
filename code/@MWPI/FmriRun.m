function FmriRun(mwpi, kRun)
% Run - do an fMRI MWPI run.
% 
% Syntax: mwpi.FmriRun(kRun)
%
% In:
%	kRun: which run to execute
%
% Updated: 2015-06-24
%

% global vars so cleanup will work
% even though they are global they are NOT used outside of this file!
global mwpi_g;
mwpi_g = mwpi;
global sRun;
sRun = struct('res',[], 'tStart', [], 'tEnd', [], 'tSequence', [], 'bAbort',[]);
global finished;
finished = false; %#ok<NASGU>
global kRun_g;
kRun_g = kRun;

% cleanup function
cleanupObj = onCleanup(@cleanupfn);

exp = mwpi.Experiment;

exp.AddLog(['Starting run ' num2str(kRun) ' of ' num2str(mwpi.nRun)]);

ListenChar(2);

% scanner starts
tRun = MWPI.Param('exp','run','time');
exp.Scanner.StartScan(tRun);


% perform the run

	% shared variables
    kBlock = 0;
    mwpi.nCorrect = 0;   

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
	
	fUpdateLevel = MWPI.Param('exp','fUpdateLevel');
	
								
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
        % Blank the screen, update the level, and
        % prepare the textures for the next block.
        
        exp.Show.Blank;       
        exp.Window.Flip;        
		
		kBlock = kBlock + 1;
		
		if kBlock > 1
			mwpi.level = fUpdateLevel(sRun.res, mwpi.sParam, kRun);
		end
		
        mwpi.PrepTextures(mwpi.sParam, kRun, kBlock, mwpi.level);
        
        exp.Scheduler.Wait;
	end
%---------------------------------------------------------------------%
    function tNow = DoBlock(tNow, ~)
        % Run a block, then save the results.
        
        exp.AddLog(['block ' num2str(kBlock) ' start']);
        
        resCur = mwpi.Block(kRun, kBlock);
		
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
		
		mwpi.level = fUpdateLevel(sRun.res, mwpi.sParam, kRun);

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
        global mwpi_g;
        global sRun;
        global finished;
		global kRun_g;
		
		exp = mwpi_g.Experiment;
        
		ListenChar(0);
		
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
					sRuns(kRun_g) = sRun;   
				end
                exp.Info.Set('mwpi','run', sRuns);
				exp.Info.Set('mwpi','currLevel',mwpi_g.level);
				exp.Info.Set('mwpi','currReward',mwpi_g.reward);
                exp.Info.AddLog('Results saved.');
				
            end
        end
	end
