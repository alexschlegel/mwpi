function Init(mwpi)
% MWPI.Init
%
% Description: set up the experiment
%
% Syntax: mwpi.Init;
%
% Updated: 2015-08-10

% define keys
    mwpi.Experiment.Input.Set('response', MWPI.Param('key','response'));
    mwpi.Experiment.Input.Set('exactMatch', MWPI.Param('key','exactMatch'));
    mwpi.Experiment.Input.Set('classMatch', MWPI.Param('key','classMatch'));
    mwpi.Experiment.Input.Set('noMatch', MWPI.Param('key','noMatch'));

%set the reward
    if ~mwpi.bPractice
        % check if we're resuming an existing session
        mwpi.reward = mwpi.Experiment.Info.Get('mwpi','reward');

        if isempty(mwpi.reward)
            mwpi.reward	= MWPI.Param('reward','base');
            mwpi.Experiment.Info.Set('mwpi','reward',mwpi.reward);
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