function Run(mwpi)
% Do an MWPI run.
% Calls either Practice or FmriRun, depending on whether the current
% session is a training session or not.
% 
% Syntax: mwpi.Run;
%
% Updated: 2015-11-20

exp = mwpi.Experiment;

if mwpi.nRun > 1
	% calculate default run to execute
	sResults = exp.Info.Get('mwpi','run');
	kRunDefault = min([numel(sResults) + 1, mwpi.nRun]);
	kRun = 0;

	% prompt which run to run
	while ~ismember(kRun, 1:mwpi.nRun)
		kRunInput = exp.Prompt.Ask(['Which run (max=', num2str(mwpi.nRun),')'],...
			'mode','command_window','default', num2str(kRunDefault));
		kRun = str2double(kRunInput);
	end
else
	kRun = 1;
end

if mwpi.bPractice
	if kRun == 1
		mwpi.Instructions;
	end
	mwpi.Practice(kRun);
else
	mwpi.FmriRun(kRun);
end
end