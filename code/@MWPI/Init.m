function Init(mwpi)
% Init - set up the mwpi experiment
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

strDomain = conditional(mwpi.bPractice, 'practice','exp');
exp = mwpi.Experiment;

% hack to get the joystick to work (the triggers don't seem to
% work)
if strcmp(exp.Info.Get('experiment','input'),'joystick')
	exp.Input.Set('left','lupper');
	exp.Input.Set('right','rupper');
end

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

%set the reward
	if ~mwpi.bPractice
        % check if we're resuming an existing session
        mwpi.reward = exp.Info.Get('mwpi','currReward');

        if isempty(mwpi.reward)
            mwpi.reward	= MWPI.Param('reward','base');
            exp.Info.Set('mwpi','currReward',mwpi.reward);
        end
	end
	
% set the level
	mwpi.level = exp.Info.Get('mwpi','currLevel');
	
	if isempty(mwpi.level)
		mwpi.level = MWPI.Param(strDomain, 'startLevel');		
		
		if ~mwpi.bPractice
			threshold = exp.Subject.Get('threshold');
			
			if isempty(threshold)
				warning('no threshold calculated, using default start levels');
			else
				mwpi.level = threshold;
			end
		end
	end
	
 % get experiment parameters, # of runs and # of blocks per run
	 % check if we're resuming an existing session
	 mwpi.sParam = exp.Info.Get('mwpi','param');

	 if isempty(mwpi.sParam)
		mwpi.sParam = MWPI.CalcParams('practice', mwpi.bPractice);
		exp.Info.Set('mwpi','param',mwpi.sParam);
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