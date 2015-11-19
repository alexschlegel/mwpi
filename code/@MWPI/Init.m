function Init(mwpi)
% Init - set up the mwpi experiment
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

strDomain = conditional(mwpi.bPractice, 'practice','exp');

% hack to get the joystick to work (the triggers don't seem to
% work)
if strcmp(mwpi.Experiment.Info.Get('experiment','input'),'joystick')
	mwpi.Experiment.Input.Set('left','lupper');
	mwpi.Experiment.Input.Set('right','rupper');
end

% define keys
    mwpi.Experiment.Input.Set('responselr',		MWPI.Param('key','responselr'));
	mwpi.Experiment.Input.Set('responselrud',	MWPI.Param('key','responselrud'));
	mwpi.Experiment.Input.Set('shrink',			MWPI.Param('key','shrink'));
	mwpi.Experiment.Input.Set('grow',			MWPI.Param('key','grow'));
	
% read in the arrow image
bArrow = imread(MWPI.Param('path','arrow'));
arrArrow = conditional(bArrow, reshape(MWPI.Param('color','back'),1,1,3), ...
								 reshape(MWPI.Param('color','fore'),1,1,3));
mwpi.arrow = uint8(arrArrow);							 

%set the reward
	if ~mwpi.bPractice
        % check if we're resuming an existing session
        mwpi.reward = mwpi.Experiment.Info.Get('mwpi','currReward');

        if isempty(mwpi.reward)
            mwpi.reward	= MWPI.Param('reward','base');
            mwpi.Experiment.Info.Set('mwpi','currReward',mwpi.reward);
        end
	end
	
% set the level
	mwpi.level = mwpi.Experiment.Info.Get('mwpi','currLevel');
	
	if isempty(mwpi.level)
		mwpi.level = MWPI.Param(strDomain, 'startLevel');		
		
		if ~mwpi.bPractice
			threshold = mwpi.Experiment.Subject.Get('threshold');
			
			if isempty(threshold)
				warning('no threshold calculated, using default start levels');
			else
				mwpi.level = threshold;
			end
		end
	end
	
 % get experiment parameters, # of runs and # of blocks per run
	 % check if we're resuming an existing session
	 mwpi.sParam = mwpi.Experiment.Info.Get('mwpi','param');

	 if isempty(mwpi.sParam)
		mwpi.sParam = MWPI.CalcParams('practice', mwpi.bPractice);
		mwpi.Experiment.Info.Set('mwpi','param',mwpi.sParam);
	 end
    
mwpi.Experiment.AddLog('initialized experiment');

end