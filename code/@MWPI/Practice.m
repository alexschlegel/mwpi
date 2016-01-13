function Practice(mwpi, kRun)
% Practice - do an MWPI practice session.
%
% Syntax: mwpi.Practice(kRun)
%
% In:
%	kRun: which run to execute
%
% Updated: 2015-09-03

exp = mwpi.Experiment;

% turn on keyboard listening
ListenChar(2);

% initialize param struct to correct size
mwpi.sParam = MWPI.CalcParams('practice', true);
mwpi.sParam = structfun(@(f) f*0, mwpi.sParam, 'uni', false);

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
exp.Info.Set('mwpi','param', mwpi.sParam);
exp.Info.AddLog('Results saved.');

exp.Subject.Set('ability', sInfo.estimate.ability);
exp.Subject.AddLog('Ability estimate saved to subject info.');

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
		
		% update cumulative record of parameters
		cParam = fieldnames(mwpi.sParam);
		for i = 1:numel(cParam)
			mwpi.sParam.(cParam{i})(:, kProbeTotal, :) = sTaskParam.(cParam{i});
		end
		
		% add additional fields to pass
		sTaskParam.mwpi = mwpi;
		sTaskParam.kRun = kRun;
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
kRun   = sTaskParam.kRun;

% rest and generate new textures
arrAbility = vertcat(sTaskParam.estimate(:).ability);
tPreBlock	= MWPI.Param('practice','tPreBlock');
DoRest(PTB.Now, tPreBlock, d, arrAbility, sTaskParam);

% write a log message
exp.AddLog(['starting block ' num2str(kBlock)]);

% run the block
newRes = mwpi.Block(kRun, kBlock);
bCorrect = newRes.bCorrect;

% save results
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
		
		mwpi.PrepTextures(sTaskParam, 1, 1, dNext, arrAbilityNext);
		
		while PTB.Now < tStart + tWait
			exp.Scheduler.Wait;
		end
	end
%---------------------------------------------------------------------%
end