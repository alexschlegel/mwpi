function DeleteRun(mwpi, kRun)
% MWPI.DeleteRun
%
% Description:  Delete the data from one or more runs (in case something bad happens).
%               This shifts all following run numbers back, i.e. if you delete run 2,
%               what was previously run 3 becomes run 2, etc.
%
% Syntax: mwpi.DeleteRun(kRun);
%
% In:
%   kRun - the number(s) of the run(s) to delete, as a scalar or array

sResults = mwpi.Experiment.Info.Get('mwpi','result');

nRun = numel(sResults);
goodRun = setdiff(1:nRun, kRun);
sResults = sResults(goodRun);

mwpi.Experiment.Info.Set('mwpi','result',sResults);

end