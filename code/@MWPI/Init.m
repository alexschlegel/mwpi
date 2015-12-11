function Init(mwpi)
% Init - set up the mwpi experiment
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

exp = mwpi.Experiment;

% define keys
    exp.Input.Set('responseud',		MWPI.Param('key','responseud'));
	exp.Input.Set('responselrud',	MWPI.Param('key','responselrud'));
	exp.Input.Set('shrink',			MWPI.Param('key','shrink'));
	exp.Input.Set('grow',			MWPI.Param('key','grow'));
	
% read in the arrow image
bArrow = imread(MWPI.Param('path','arrow'));
arrArrow = conditional(bArrow, reshape(MWPI.Param('color','back'),1,1,3), ...
								 reshape(MWPI.Param('color','fore'),1,1,3));
mwpi.arrow = uint8(arrArrow);							 

%set the reward (fMRI only)
if ~mwpi.bPractice
	% check if we're resuming an existing session
	mwpi.reward = exp.Info.Get('mwpi','currReward');
	
	if isempty(mwpi.reward)
		mwpi.reward	= MWPI.Param('reward','base');
		exp.Info.Set('mwpi','currReward',mwpi.reward);
	end
end
	
% initialize difficultymatch and currD (fMRI only)
if ~mwpi.bPractice
	
	% saved from interrupted session?
	mwpi.dm		  = exp.Info.Get('mwpi','dm');
	mwpi.currD    = exp.Info.Get('mwpi', 'currD');
	
	if isempty(mwpi.dm)
		
		n = MWPI.Param('exp', 'nBlockPerClass');
		assess = exp.Subject.Get('assessment');
		
		if isempty(assess)
			warning('no threshold ability calculated, using default start levels');
			assess = MWPI.Param('exp', 'startLevel');
			mwpi.currD = assess;
		else
			mwpi.currD = assess.ability;
		end
		
		target = MWPI.Param('curve', 'thresholdPerformance');
		mwpi.dm = subject.difficultymatch(n, ...
			'assessment',	assess,	...
			'target',		target	...
			);
	end
end
	
 % generate block-specific parameters (fMRI only)
 if ~mwpi.bPractice
	 % check if we're resuming an existing session
	 mwpi.sParam = exp.Info.Get('mwpi','param');

	 if isempty(mwpi.sParam)
		mwpi.sParam = MWPI.CalcParams('practice', false);
		exp.Info.Set('mwpi','param',mwpi.sParam);
	 end
 else
	 mwpi.sParam = [];
 end
	 
% open textures
mwpi.sTexture.stim			= exp.Window.OpenTexture('stim');
mwpi.sTexture.arrow			= exp.Window.OpenTexture('arrow');
mwpi.sTexture.retention		= exp.Window.OpenTexture('retention');
mwpi.sTexture.retentionLg	= exp.Window.OpenTexture('retentionLg');
mwpi.sTexture.retentionSm	= exp.Window.OpenTexture('retentionSm');
mwpi.sTexture.test			= exp.Window.OpenTexture('test');
mwpi.sTexture.testYes		= exp.Window.OpenTexture('testYes');
mwpi.sTexture.testNo		= exp.Window.OpenTexture('testNo');
    
exp.AddLog('initialized experiment');

end