function sm = CalcSimMatrix(res)
% CalcSimMatrix
% 
% Description:	calculate an empirical similarity matrix based on the SimTest
%				results
% 
% Syntax: sm = CalcSimMatrix(res)
% 
% In:
%	res	- PTBIFO.mwpi.simRes
% 
% Updated:	2016-03-01
% Copyright 2016 Alex Schlegel (schlegel@gmail.com). This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
kClass	= unique(res.sampleClass);
nClass	= numel(kClass);

sm	= zeros(nClass);

%score for rank 1, 2, 3, 4
simScore	= [4 4 0 0];

nTrial	= numel(res.sampleClass);
for kT=1:nTrial
	kSample		= res.sampleClass(kT);
	kFlanker	= res.classesInOrderOfSimilarity{kT};
	
	sm(kSample,kFlanker)	= sm(kSample,kFlanker) + simScore;
end

%make symmetric
	sm	= sm + sm';

%normalize
	sm	= normalize(sm,'min',0,'max',100);