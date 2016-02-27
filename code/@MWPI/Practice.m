function Practice(mwpi, kRun)
% Practice - do an MWPI practice session.
%
% Syntax: mwpi.Practice(kRun)
%
% In:
%	kRun: which run to execute
%
% Updated: 2016-01-27

exp = mwpi.Experiment;

% turn on keyboard listening
ListenChar(2);

% initialize param struct to correct size
cParamField = {'cClass', 'vClass', 'ucClass', 'posCued', 'posUncued', 'posMatch', 'promptClass', 'seed'};
sParam = exp.Info.Get('mwpi','param');
if isempty(sParam)
	clear sParam;
end
sParam(kRun,1:mwpi.nBlock) = dealstruct(cParamField{:}, []);
exp.Info.Set('mwpi','param',sParam);

mwpi.nCorrect = 0;
exp.Info.Set('mwpi','currRes', []);

% get some params
indClass	= MWPI.Param('stim', 'class');
curve		= MWPI.Param('curve');
estimate	= MWPI.Param('practice', 'startLevel');
minPerClass = MWPI.Param('practice', 'nBlockPerClass');
maxPerClass = MWPI.Param('practice', 'nBlockPerClass');

% initialize assessment object
mwpi.assess = subject.assess(repmat({@OneBlock}, size(indClass)), ...
	'chance',		curve.chancePerformance,					...
	'estimate',		estimate,									...
	'target',		curve.thresholdPerformance,					...
	'd',			(curve.xmin : curve.xstep : curve.xmax)		...
	);

% pause the scheduler
exp.Scheduler.Pause;

% run the assessment
mwpi.assess.Run(...
	'param',	@GenParamStruct,	...
	'min',		minPerClass,		...
	'max',		maxPerClass			...
	);

% finish
exp.Scheduler.Resume;
exp.AddLog('Training run complete');
exp.Show.Text('Practice Finished!\nPlease wait for the experimenter.');
exp.Window.Flip;

% enable keyboard
ListenChar(0);

% save results
sRun.block = exp.Info.Get('mwpi','currRes');

sRuns = exp.Info.Get('mwpi','run');
if isempty(sRuns)
	sRuns = sRun;
else
	sRuns(kRun) = sRun;
end
exp.Info.Set('mwpi','run',sRuns);
exp.Info.Unset('mwpi','currRes');

sInfo = mwpi.assess.GetTaskInfo;
exp.Info.Set('mwpi','sTaskInfo', sInfo);
exp.Info.AddLog('Results saved.');

exp.Subject.Set('ability', sInfo.estimate.ability);
exp.Subject.AddLog('Ability estimate saved to subject info.');

% set or append trial history in subject info
thisHistory.task   = vertcat(sInfo.history.task{:});
thisHistory.d      = vertcat(sInfo.history.d{:});
thisHistory.result = vertcat(sInfo.history.result{:});

sHistory = exp.Subject.Get('history');
if ~isempty(sHistory)
	WaitSecs(0.5); % allow other log messages to display
	pmtRes = exp.Prompt.Ask('Trial history exists for this subject. What to do?', ...
		'mode', 'command_window', 'choice', {'append', 'overwrite_old', 'discard_new'});
	
	switch pmtRes
		case 'append'
			% append current results to existing.
			try
				sHistory.task	= [sHistory.task;	thisHistory.task];
				sHistory.d		= [sHistory.d;		thisHistory.d];
				sHistory.result = [sHistory.result;	thisHistory.result];
				assert(numel(sHistory.task) == numel(sHistory.d) && numel(sHistory.d) == numel(sHistory.result));
				exp.Subject.Set('history', sHistory);
				exp.Subject.AddLog('Trial history appended to subject info.');
			catch
				warning('Could not append data - saving to subject info as ''temp_history''. Please resolve manually.');
				exp.Subject.Set('temp_history', thisHistory);
			end
		case 'overwrite_old'
			% overwrite old results with new
			exp.Subject.Set('history', thisHistory);
			exp.Subject.AddLog('Overwrote trial history in subject info.');
		case 'discard_new'
			% do nothing
	end
else
	exp.Subject.Set('history', thisHistory);
	exp.Subject.AddLog('Trial history saved to subject info.');
end

%--------------------------------------------------------------------------%
	function sTaskParam = GenParamStruct(kTask, ~, kProbeTotal)
		% generate a parameter struct for a random block of type kTask
		% (param callback function for subject.assess/Run)
		
		sTaskParam.cClass = kTask;
		
		sTaskParam.vClass	 = randFrom(indClass);
		sTaskParam.ucClass	 = randFrom(setdiff(indClass, kTask));
		sTaskParam.posCued	 = randFrom(1:4);
		sTaskParam.posUncued = randFrom(setdiff(1:4, sTaskParam.posCued));
		sTaskParam.posMatch  = randFrom(1:4);
		
		sTaskParam.promptClass(1,1,sTaskParam.posCued) = kTask;
		sTaskParam.promptClass(1,1,sTaskParam.posUncued) = sTaskParam.ucClass;
		sTaskParam.promptClass(1,1,setdiff(1:4, [sTaskParam.posCued, sTaskParam.posUncued])) = ...
			randomize(setdiff(indClass, [kTask, sTaskParam.ucClass]));
		
		sTaskParam.seed = MWPI.GenSeeds;
		
		% update cumulative record of parameters
		sParam = exp.Info.Get('mwpi','param');
		sParam(kRun, kProbeTotal) = sTaskParam;
		exp.Info.Set('mwpi','param', sParam);
		
		% add additional fields to pass
		sTaskParam.mwpi = mwpi;
	end
%------------------------------------------------------------------------%
end

%---------------------------------------------------------------------%
function bCorrect = OneBlock(d, sTaskParam)
% Do a single block, including the preceding rest period.
% This is the callback function for the subject.assess object.
% Note: this function must be outside of the scope of the main Practice
% function, in order to avoid saving a huge workspace along with the
% function handle. Necessary pointers are passed within sTaskParam.
%
% In:
%	d:			difficulty of this block's wm / test stimulus
%	sTaskParam: parameter struct, with additional fields from
%				GenParamStruct
%
% Out:
%	bCorrect:	indicates whether the subject got the block correct
%

mwpi = sTaskParam.mwpi;
exp  = mwpi.Experiment;

kBlock = sTaskParam.kProbeTotal;

% rest and generate new textures
arrAbility = vertcat(sTaskParam.estimate(:).ability);
tPreBlock	= MWPI.Param('practice','tPreBlock');
DoRest(PTB.Now, tPreBlock, d, arrAbility, sTaskParam);

% write a log message
exp.AddLog(['starting block ' num2str(kBlock)]);

% run the block
newRes = mwpi.Block(kBlock, sTaskParam);
bCorrect = newRes.bCorrect;

% save results (including difficulty levels used)
newRes.d = d;
newRes.arrAbility = arrAbility;

res = exp.Info.Get('mwpi','currRes');
if isempty(res)
	res = newRes;
else
	res(end+1) = newRes;
end
exp.Info.Set('mwpi','currRes',res);

% pause before continue prompt
tPause = MWPI.Param('practice', 'tFbPause');
tNow = PTB.Now;
while PTB.Now < tNow + tPause
	exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_HIGH);
end

% add continue prompt
fbTexture = conditional(newRes.bCorrect, 'testYes', 'testNo');
strContinue = 'Press any key to continue.';
contOffset	= MWPI.Param('text', 'contOffset');
exp.Show.Text(strContinue, [0,contOffset], 'window', fbTexture);
exp.Show.Texture(fbTexture);
exp.Window.Flip;

% wait for a key to be pressed
while ~exp.Input.Down('any')
	exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
end

%---------------------------------------------------------------------%
	function DoRest(tStart, tWait, dNext, arrAbilityNext, sTaskParam)
		% tStart, tWait in ms
		exp.Show.Blank;
		exp.Window.Flip;
		
		mwpi.PrepTextures(sTaskParam, dNext, arrAbilityNext);
		
		while PTB.Now < tStart + tWait
			exp.Scheduler.Wait;
		end
	end
%---------------------------------------------------------------------%
end