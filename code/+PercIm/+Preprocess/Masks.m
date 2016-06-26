function b = Masks(varargin)
% PercIm.Masks
%
% Description:	prepare masks from CI, an anatomical occipital mask, and a
%				ventricle mask for control analyses
%
% Syntax:	b = PercIm.Masks(<options>)
%
% In:
% 	<options>:
%		force:	(false)
%		cores:	(12)
%
% Updated: 2015-05-01
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData;

opt	= ParseArgs(varargin,...
		'force'	, false	, ...
		'cores'	, 12	  ...
		);

ifo	= PercIm.SubjectInfo;

cSubject	= ifo.code.mri;
cSubject	= cSubject(~cellfun(@isempty,cSubject));

strDirMaskOut	= DirAppend(strDirData,'mask');

%CI masks
	strDirMaskCI	= DirAppend(strDirData,'mask-ci');
	cPathMaskCI		= FindFilesByExtension(strDirMaskCI,'nii.gz');

	%remove the occ masks
		bRemove					= cellfun(@(f) ~isempty(strfind(PathGetFilePre(f,'favor','nii.gz'),'occ')),cPathMaskCI);
		cPathMaskCI(bRemove)	= [];

	nMask			= numel(cPathMaskCI);

	cDirReg		= cellfun(@(s) DirAppend(strDirData,'functional',s,'feat_cat','reg'),cSubject,'uni',false);
	bDo			= cellfun(@isdir,cDirReg);

	[cSubject,cDirReg]	= varfun(@(x) x(bDo),cSubject,cDirReg);
	nSubject			= numel(cSubject);

	cDirMask	= cellfun(@(s) DirAppend(strDirMaskOut,s),cSubject,'uni',false);
	cellfun(@CreateDirPath,cDirMask);

	cPathXFMMNI2Func	= cellfun(@(d) PathUnsplit(d,'standard2example_func','mat'),cDirReg,'uni',false);
	cPathFunc			= cellfun(@(d) PathUnsplit(d,'example_func','nii.gz'),cDirReg,'uni',false);

	cPathMaskCIRep		= repmat(cPathMaskCI,[1 nSubject]);
	cPathXFMMNI2FuncRep	= repmat(cPathXFMMNI2Func',[nMask 1]);
	cPathFuncRep		= repmat(cPathFunc',[nMask 1]);
	cDirMaskRep			= repmat(cDirMask',[nMask 1]);

	cPathMaskRep	= cellfun(@(dm,fm) PathUnsplit(dm,PathGetFileName(fm)),cDirMaskRep,cPathMaskCIRep,'uni',false);

	b	= FSLRegisterFLIRT(cPathMaskCIRep,cPathFuncRep,...
			'output'	, cPathMaskRep			, ...
			'xfm'		, cPathXFMMNI2FuncRep	, ...
			'interp'	, 'nearestneighbour'	, ...
			'force'		, opt.force				, ...
			'cores'		, opt.cores				  ...
			);

%occipital mask
	cMaskLabel	=	{
						{'ctx_lh_G_and_S_occipital_inf' 'ctx_lh_G_occipital_middle' 'ctx_lh_G_occipital_sup' 'ctx_lh_G_cuneus' 'ctx_lh_Pole_occipital' 'ctx_lh_S_oc_middle_and_Lunatus' 'ctx_lh_S_oc_sup_and_transversal' 'ctx_lh_S_occipital_ant'}
						{'ctx_rh_G_and_S_occipital_inf' 'ctx_rh_G_occipital_middle' 'ctx_rh_G_occipital_sup' 'ctx_rh_G_cuneus' 'ctx_rh_Pole_occipital' 'ctx_rh_S_oc_middle_and_Lunatus' 'ctx_rh_S_oc_sup_and_transversal' 'ctx_rh_S_occipital_ant'}
						{'ctx_lh_G_and_S_occipital_inf' 'ctx_lh_G_occipital_middle' 'ctx_lh_G_occipital_sup' 'ctx_lh_G_cuneus' 'ctx_lh_Pole_occipital' 'ctx_lh_S_oc_middle_and_Lunatus' 'ctx_lh_S_oc_sup_and_transversal' 'ctx_lh_S_occipital_ant' 'ctx_rh_G_and_S_occipital_inf' 'ctx_rh_G_occipital_middle' 'ctx_rh_G_occipital_sup' 'ctx_rh_G_cuneus' 'ctx_rh_Pole_occipital' 'ctx_rh_S_oc_middle_and_Lunatus' 'ctx_rh_S_oc_sup_and_transversal' 'ctx_rh_S_occipital_ant'}
					};
	cCrop		=	{
						[]
						[]
						[]
					};
	cMaskName	=	{
						'occ-left'
						'occ-right'
						'occ'
					};
	nMask		= numel(cMaskLabel);

	cDirFEAT		= reshape(cellfun(@(s) DirAppend(strDirData,'functional',s,'feat_cat'),cSubject,'uni',false),1,[]);
	cDirFreeSurfer	= reshape(cellfun(@(s) DirAppend(strDirData,'structural',s,'freesurfer'),cSubject,'uni',false),1,[]);

	%compute the Freesurfer to functional space transforms
		b	= FreeSurfer2FEAT(cDirFreeSurfer,cDirFEAT,...
				'force'	, opt.force	, ...
				'cores'	, opt.cores	  ...
				);

		cPathFS2F	= cellfun(@(d) PathUnsplit(DirAppend(d,'reg'),'freesurfer2example_func','mat'),cDirFEAT,'UniformOutput',false);
		cPathF		= cellfun(@(d) PathUnsplit(DirAppend(d,'reg'),'example_func','nii.gz'),cDirFEAT,'UniformOutput',false);
	%extract the masks
		cDirFreeSurferR	= repmat(cDirFreeSurfer,[nMask 1]);
		cDirMaskR		= repmat(cDirMask',[nMask 1]);
		cMaskLabelR		= repmat(cMaskLabel,[1 nSubject]);
		cMaskNameR		= repmat(cMaskName,[1 nSubject]);
		cCropR			= repmat(cCrop,[1 nSubject]);
		cPathFS2FR		= repmat(cPathFS2F,[nMask 1]);
		cPathFR			= repmat(cPathF,[nMask 1]);

		cPathMask		= cellfun(@(d,m) PathUnsplit(d,m,'nii.gz'),cDirMaskR,cMaskNameR,'uni',false);

		cInput	=	{...
						cDirFreeSurferR					, ...
						cMaskLabelR						, ...
						'crop'			, cCropR		, ...
						'xfm'			, cPathFS2FR	, ...
						'ref'			, cPathFR		, ...
						'output'		, cPathMask		, ...
						'force'			, opt.force		  ...
					};

		b	= MultiTask(@FreeSurferMask,cInput,...
					'description'	, 'extracting masks'	, ...
					'catch'			, true					, ...
					'cores'			, opt.cores				  ...
					);

%ventricle masks
	%construct the ventricle masks in freesurfer space
		[bSuccess,cPathVentricle]	= FreeSurferMaskVentricle(cDirFreeSurfer,...
										'force'	, opt.force	, ...
										'cores'	, opt.cores	  ...
										);
		cPathVentricle				= reshape(cPathVentricle,[],1);

	%convert to functional space
		cPathVFunc	= cellfun(@(d) PathUnsplit(d,'ventricle','nii.gz'),cDirMask,'uni',false);

		b	= FSLRegisterFLIRT(cPathVentricle,cPathFunc,...
			'output'	, cPathVFunc				, ...
			'xfm'		, reshape(cPathFS2F,[],1)	, ...
			'interp'	, 'nearestneighbour'		, ...
			'force'		, opt.force					, ...
			'cores'		, opt.cores					  ...
			);
