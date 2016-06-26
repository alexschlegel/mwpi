function b = FreeSurfer(varargin)
% PercIm.Preprocess.FreeSurfer
%
% Description:	run the structural data through FreeSurfer
%
% Syntax:	b = PercIm.Preprocess.FreeSurfer(<options>)
%
% In:
%	<options>:
%		ifo:	(<load>) the subject info struct
%		cores:	(1) the number of processor cores to use
%		force:	(false) true to reprocess everything
%
% Updated: 2015-05-01
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData;

opt	= ParseArgs(varargin,...
		'ifo'	, []	, ...
		'cores'	, 12	, ...
		'force'	, false	  ...
		);

if isempty(opt.ifo)
	ifo	= PercIm.SubjectInfo;
else
	ifo	= opt.ifo;
end

cPathStructural	= ifo.path.structural.raw;
bProcess		= FileExists(cPathStructural);

b	= FreeSurferProcess(cPathStructural(bProcess),...
		'check_results'	, false		, ...
		'cores'			, opt.cores	, ...
		'force'			, opt.force	  ...
		);
