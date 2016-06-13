function Functional(varargin)
% PercIm.Preprocess.Functional
%
% Description:	preprocess the perc/im functional data
%
% Syntax:	PercIm.Preprocess.Functional(<options>)
%
% In:
% 	<options>:
%		cores:	(12)
%		force:	(false)
%
% Updated: 2015-05-01
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

opt	= ParseArgs(varargin,...
		'cores'	, 12	, ...
		'force'	, false	  ...
		);

ifo	= PercIm.SubjectInfo;

%preprocess the fMRI data
	%BET the structurals
		bProcess1					= FileExists(ifo.path.structural.raw);
		cPathStructural				= ifo.path.structural.raw(bProcess1);
		[b,cPathStructuralBrain]	= FSLBet(cPathStructural,...
										'thresh'	, 0.25		, ...
										'cores'		, opt.cores	, ...
										'force'		, opt.force	  ...
										);

	%preprocess the functional data
		cPathFunctional		= ifo.path.functional.raw(bProcess1);
		bProcess2			= cellfun(@FileExists,cPathFunctional,'uni',false);
		cPathFunctional		= cellfun(@(cf,b) cf(b),cPathFunctional,bProcess2,'uni',false);
		cPathStructural		= cellfun(@(s,f) repmat({s},size(f)),cPathStructuralBrain,cPathFunctional,'uni',false);

		[cPathFunctional,cPathStructural]	= varfun(@cellnestflatten,cPathFunctional,cPathStructural);

		[bSuccess,cPathOut,tr]	= FSLFEATPreprocess(cPathFunctional,cPathStructural,...
									'motion_correct'		, true			, ...
									'slice_time_correct'	, 6				, ...
									'spatial_fwhm'			, 6				, ...
									'norm_intensity'		, false			, ...
									'highpass'				, 100			, ...
									'lowpass'				, false			, ...
									'force'					, opt.force		, ...
									'cores'					, opt.cores		  ...
									);

%concatenate the fMRI runs
	cPathFunctionalPP	= ifo.path.functional.pp(bProcess1);
	cPathFunctionalPP	= cellfun(@(cf,b) cf(b),cPathFunctionalPP,bProcess2,'uni',false);
	bProcess3			= ~cellfun(@isempty,cPathFunctionalPP);

	cPathFunctionalPP	= cPathFunctionalPP(bProcess3);

	[b,cPathCat,cDirFEATCat]	= FSLConcatenate(cPathFunctionalPP,...
									'cores'	, opt.cores	, ...
									'force'	, opt.force	  ...
									);
