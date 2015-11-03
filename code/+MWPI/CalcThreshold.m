function threshold = CalcThreshold(res)
% MWPI.CalcThreshold - calculate a psychometric curve for the results of a
%					   run of MWPI and find the threshold level, where the
%					   subject is expected to get a certain percentage of
%					   trials correct. 
%
% Syntax: threshold = MWPI.CalcThreshold(res);
%
% In:
%	res:		the result struct array for a run of MWPI. In 
%				particular, must include fields "level" and "bCorrect".
%
% Out:
%	threshold:	the level at which this subject would be expected to
%				perform at the threshold level, as defined in MWPI.Param
%
% Updated: 2015-11-03

xStim = [res.level];
bResponse = [res.bCorrect];

p = PsychoCurve(xStim, bResponse, ...
					'xmin',		MWPI.Param('curve','xmin'),	...
					'xmax',		MWPI.Param('curve','xmax'),	...
					'xstep',	MWPI.Param('curve','xstep'),...
					'g',		MWPI.Param('curve','minPerformance'), ...
					'a',		MWPI.Param('curve','thresholdPerformance') ...
					);

threshold = p.t;

end