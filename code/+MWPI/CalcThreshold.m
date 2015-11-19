function threshold = CalcThreshold(res, sParam, kRun)
% MWPI.CalcThreshold - calculate a psychometric curve for the results of a
%					   run of MWPI and find the threshold levels, where the
%					   subject is expected to get a certain percentage of
%					   trials correct. The levels are calculated seperately
%					   for each set of blocks with the same class of
%					   retained image.
%
% Syntax: threshold = MWPI.CalcThreshold(res, sParam, kRun);
%
% In:
%	res:		the result struct array for a run of MWPI. In 
%				particular, must include fields "level" and "bCorrect".
%
%	sParam:		the parameter struct for the experiment (see MWPI.CalcParams)
%
%	kRun:		the run number
%
% Out:
%	threshold:	a nClass x 1 array of the levels at which this subject 
%				would be expected to perform at the threshold accuracy, as
%				defined in MWPI.Param
%
% Updated: 2015-11-03

mLevel = [res.level];
arrResponse = [res.bCorrect];
arrClass = sParam.wClass(kRun, :);

threshold = arrayfun(@CalcOne, MWPI.Param('stim','class'));

	function myThresh = CalcOne(kClass)
		
		bClass = (arrClass == kClass);
		
		% get levels for kClass of blocks with retained image in kClass.
		xStim = 1-mLevel(kClass, bClass);
		
		% responses for blocks we are considering
		bResponse = arrResponse(bClass);
		
		p = PsychoCurve(xStim, bResponse, ...
			'xmin',		MWPI.Param('curve','xmin'),	...
			'xmax',		MWPI.Param('curve','xmax'),	...
			'xstep',	MWPI.Param('curve','xstep'),...
			'g',		MWPI.Param('curve','minPerformance'), ...
			'a',		MWPI.Param('curve','thresholdPerformance') ...
			);
		
		myThresh = 1-p.t;

	end

end