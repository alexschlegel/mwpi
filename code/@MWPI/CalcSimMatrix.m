function cSM = CalcSimMatrix(varargin)
% CalcSimMatrix
% 
% Description:	calculate empirical similarity matrices based on the SimTest
%				results for a set of subjects
% 
% Syntax: sm = CalcSimMatrix([code]=(all fmri))
% 
% In: 
%	code - cell of session codes to operate on
%
% Out:
%	cSM - cell of similarity matrices for the given codes.
% 
% Updated:	2016-10-17
% Copyright 2016 Alex Schlegel (schlegel@gmail.com). This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

% get session codes
if nargin == 0
	cCode = getfield(PercIm.SubjectInfo,'code','fmri');
else
	cCode = ForceCell(varargin{1});
end

% get similarity test results
sPTBIFO = cellfun(@(code) getfield(load(PathUnsplit(strDirData, code, 'mat')),'PTBIFO'), cCode);
cSimRes = arrayfun(@(s) s.mwpi.simRes, sPTBIFO, 'uni', false);

% calculate matrices
cSM = cellfun(@CalcOneMatrix, cSimRes, 'uni', false);

end

function sm = CalcOneMatrix(res)

kClass	= unique([res.sampleClass]);
nClass	= numel(kClass);

sm	= zeros(nClass);

%score for rank 1, 2, 3, 4
simScore	= [3 1 -1 -3];

nTrial	= numel([res.sampleClass]);
for kT=1:nTrial
	kSample		= res(kT).sampleClass;
	kFlanker	= res(kT).classesInOrderOfSimilarity;
	
	sm(kSample,kFlanker)	= sm(kSample,kFlanker) + simScore;
end

%make symmetric
	sm	= sm + sm';

%normalize
	sm	= normalize(sm,'min',0,'max',100);
end