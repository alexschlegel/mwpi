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
sRun = dealstruct('res','tStart','tEnd','tSequence','bAbort', 'fracCorrect', ...
	'meanFracFixationCorrect', []);
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
	
	% pause the scheduler and stop autosaving
	exp.Scheduler.Pause;
	exp.Info.AutoSave(false);
    
	% go!
    
	[sRun.tStart, sRun.tEnd, sRun.tSequence, sRun.bAbort] = ...
		exp.Sequence.Linear(cF,tSequence, ...
		'tstart',1,			...
		'tbase','absolute', ...
		'tunit','tr'		...
		);
	
	exp.Scheduler.Resume;
	
	% scanner ends
	exp.Scanner.StopScan;
	
	
% get some statistics
sRun.fracCorrect = mean([sRun.res.bCorrect]);
sRun.meanFracFixationCorrect = mean([sRun.res.fracFixationCorrect]);

% finish up
exp.AddLog(['Run ' num2str(kRun) ' complete']);
exp.AddLog(['Test accuracy: ' num2str(round(100 * sRun.fracCorrect)) '%']);
exp.AddLog(['Average fixation accuracy per trial: ' num2str(round(100 * sRun.meanFracFixationCorrect)) '%']);

finished = true;
clear cleanupObj;

%======================= Nested Functions ==========================%

%----------------------------------------------------------------------%
    function tNow = DoRest(tNow, tNext)
        % Blank the screen, update the level, and
        % prepare the textures for the next block.
        
        exp.Show.Blank;       
        exp.Window.Flip;        
		
		% report the result of the last probe to difficultymatch
		if kBlock > 0
			UpdateDM;
		end
		
		kBlock = kBlock + 1;
		
		% update currD with difficulty for next probe
		kTask = mwpi.sParam(kRun, kBlock).cClass;
		mwpi.currD(kTask) = mwpi.dm.GetNextProbe(kTask);
		d = mwpi.currD(kTask);
		
		% prepare the next probe		
		mwpi.PrepTextures(mwpi.sParam(kRun, kBlock), d, mwpi.currD);
			
        exp.Scheduler.Wait([], exp.Scanner.TR2ms(tNext-0.25));
	end
%---------------------------------------------------------------------%
    function tNow = DoBlock(tNow, ~)
        % Run a block, then save the results.
        
        exp.AddLog(['block ' num2str(kBlock) ' start']);
        
        resCur = mwpi.Block(kBlock, mwpi.sParam(kRun, kBlock));
		
		% save difficulties used for this block
		resCur.d =  mwpi.currD(mwpi.sParam(kRun,kBlock).cClass);
		resCur.arrAbility = mwpi.currD;
        
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
		
		UpdateDM;
		
		% wait for a second
		pause(1);
		
		exp.Show.Text(['<size:' num2str(MWPI.Param('text','sizeDone')) ...
			'><color:' MWPI.Param('text','colDone') '>RELAX!</color></size>']);
		exp.Window.Flip;
		
		exp.Scheduler.Wait;
	end
%-------------------------------------------------------------------%
	function UpdateDM
		% update the difficultymatch object with results from the last
		% probe
		
		resLast = sRun.res(end);
		kTaskLast = mwpi.sParam(kRun, kBlock).cClass;
		mwpi.dm.AppendProbe(kTaskLast, mwpi.currD(kTaskLast), resLast.bCorrect);
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
		exp.Info.Set('mwpi','dm',mwpi_g.dm);
		exp.Info.Set('mwpi','dmStat', mwpi_g.dm.CompareTasks());
		exp.Info.Set('mwpi','currD', mwpi_g.currD);
		exp.Info.Set('mwpi','currReward',mwpi_g.reward);
        bSuccess = exp.Info.Save;
        if bSuccess
            exp.Info.AddLog('Results saved.');
        else
            exp.Info.AddLog('Warning: error saving results.');
        end
		
		% append trial result history to subject info
		thisHistory.task   = vertcat(sRun.res.cClass);
		thisHistory.d      = vertcat(sRun.res.d);
		thisHistory.result = vertcat(sRun.res.bCorrect);
		
		sHistory = exp.Subject.Get('history');
        if isempty(sHistory)
			exp.Subject.Set('history', thisHistory);
		else
			% append to existing
			try
				sHistory.task	= [sHistory.task;	thisHistory.task];
				sHistory.d		= [sHistory.d;		thisHistory.d];
				sHistory.result = [sHistory.result;	thisHistory.result];
				assert(numel(sHistory.task) == numel(sHistory.d) && numel(sHistory.d) == numel(sHistory.result));
				exp.Subject.Set('history', sHistory);
				exp.Subject.AddLog('Trial history appended to subject info.');
			catch
				warning('Could not append history - saving to subject info as ''temp_history''. Please resolve manually.');
				exp.Subject.Set('temp_history', thisHistory);
			end
        end
        
        bSuccess = exp.Info.Save;
        if bSuccess
            exp.Info.AddLog('Subject info saved.');
        else
            exp.Info.AddLog('Warning: error saving subject info.');
        end
		
	end
end
end
