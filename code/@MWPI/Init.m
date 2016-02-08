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
% bArrow = imread(MWPI.Param('path','arrow'));
% arrArrow = conditional(bArrow, reshape(MWPI.Param('color','back'),1,1,3), ...
% 							   reshape(MWPI.Param('color','fore'),1,1,3));
% mwpi.arrow = uint8(arrArrow);							 

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
		ability = exp.Subject.Get('ability');
		
		if isempty(ability)
			warning('no threshold ability calculated, using default start levels');
			ability = MWPI.Param('exp', 'startLevel');
		else
			exp.AddLog('Set start level based on subject''s saved ability');
		end
		
		mwpi.currD = ability;
		target = MWPI.Param('curve', 'thresholdPerformance');
		mwpi.dm = subject.difficultymatch(n, ...
			'assessment',	ability,	...
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
cTextureNames = {'stim',		...
				 'frame',		...
				 'retention',	...
				 'retentionLg',	...
				 'retentionSm',	...
				 'test',		...
				 'testYes',		...
				 'testNo'		...
				 };
			 
for i = 1:numel(cTextureNames)
	mwpi.sTexture.(cTextureNames{i}) = exp.Window.OpenTexture(cTextureNames{i});
end
    
exp.AddLog('initialized experiment');

end