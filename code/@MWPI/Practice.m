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
res = [];

% get some params
contOffset	= MWPI.Param('text', 'contOffset');
tPreBlock	= MWPI.Param('practice','tPreBlock');
indClass	= MWPI.Param('stim', 'class');
curve		= MWPI.Param('curve');
estimate	= MWPI.Param('practice', 'startLevel');
minPerClass = MWPI.Param('practice', 'nBlockPerClass');
maxPerClass = MWPI.Param('practice', 'nBlockPerClass');

% initialize assessment object
assess = subject.assess(repmat({@OneBlock}, size(indClass)), ...
	'chance',		curve.chancePerformance,					...
	'estimate',		estimate,									...
	'target',		curve.thresholdPerformance,					...
	'd',			(curve.xmin : curve.xstep : curve.xmax)		...
	);

% pause the scheduler
exp.Scheduler.Pause;

% run the assessment
assess.Run(...
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
sRun.res = res;

sRuns = exp.Info.Get('mwpi','run');
if isempty(sRuns)
	sRuns = sRun;
else
	sRuns(kRun) = sRun;
end
exp.Info.Set('mwpi','run',sRuns);
exp.Info.Set('mwpi','assessment', assess);
exp.Info.Set('mwpi','param', mwpi.sParam);
exp.Info.AddLog('Results saved.');

exp.Subject.Set('assessment', assess);
exp.Subject.AddLog('Ability assessment saved to subject info.');

%---------------------------------------------------------------------%
	function bCorrect = OneBlock(d, sTaskParam)
		% Do a single block, including the preceding rest period.
		% This is the callback function for the subject.assess object.
		%
		% In:
		%	d:			difficulty of this block's wm / test stimulus
		%	sTaskParam: parameter struct, with additional fields from
		%				GenParamStruct
		%
		% Out:
		%	bCorrect:	indicates whether the subject got the block correct
		%	
		
		kBlock = sTaskParam.kProbeTotal;
		
		% rest and generate new textures
		arrAbility = vertcat(sTaskParam.estimate(:).ability);
		DoRest(PTB.Now, tPreBlock, d, arrAbility, sTaskParam);
		
		% write a log message
		exp.AddLog(['starting block ' num2str(kBlock)]);
		
		% run the block
		newRes = mwpi.Block(kRun, kBlock);
		bCorrect = newRes.bCorrect;
		
		% save results
		if isempty(res)
			res = newRes;
		else
			res(end+1) = newRes;
		end
				
		% pause before continue prompt
		tPause = MWPI.Param('practice', 'tFbPause');
		tNow = PTB.Now;
		while PTB.Now < tNow + tPause
			exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_HIGH);
		end
		
		% add continue prompt
		fbTexture = conditional(newRes.bCorrect, 'testYes', 'testNo');
		strContinue = 'Press any key to continue.';
		exp.Show.Text(strContinue, [0,contOffset], 'window', fbTexture);
		exp.Show.Texture(fbTexture);
		exp.Window.Flip;
		
		% wait for a key to be pressed
		while ~exp.Input.Down('any')
			exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
		end
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
	function sTaskParam = GenParamStruct(kTask, ~, kProbeTotal)
		% generate a parameter struct for a random block of type kTask
		% (param callback function for subject.assess/Run)

		sTaskParam.wClass = kTask;

		sTaskParam.vClass	= randFrom(indClass);
		sTaskParam.dClass	= randFrom(indClass);
		sTaskParam.cue		= randFrom(1:2);
		sTaskParam.posMatch = randFrom(1:4);

		sTaskParam.lClass = conditional(sTaskParam.cue == 1, sTaskParam.wClass, sTaskParam.dClass);
		sTaskParam.rClass = conditional(sTaskParam.cue == 2, sTaskParam.wClass, sTaskParam.dClass);
		
		% update cumulative record of parameters
		cParam = fieldnames(mwpi.sParam);
		for i = 1:numel(cParam)
			mwpi.sParam.(cParam{i})(kProbeTotal) = sTaskParam.(cParam{i});
		end
	end
end