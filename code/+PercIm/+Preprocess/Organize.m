function b = Organize(varargin)
% PercIm.Preprocess.Organize
%
% Description:	organize the raw data
%
% Syntax:	PercIm.Preprocess.Organize(<options>)
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

strDirRaw	= DirAppend(strDirData,'raw');

%organize the data
b = PARRECOrganize(strDirRaw,...
				'cores'	, opt.cores	, ...
				'force'	, opt.force	  ...
				);
            
% convert DICOM data
ifo = PercIm.SubjectInfo;
cCode = ifo.code.fmri_new;

cDirDICOM = cellfun(@(code) DirAppend(strDirRaw,code,'DICOM'), cCode,'uni',false);
    
% structural
    strPathStructural = DirAppend(strDirData,'structural');
    cDestStructural = cellfun(@(code) DirAppend(strPathStructural, code),cCode,'uni',false);
    cellfun(@mkdir, cDestStructural);

    cSourceStructural = cellfun(@(dir) FindDirectories(dir,'anat-T1w'), cDirDICOM, 'uni', false);
    cDestStructural = arrayfun(@(k) repmat(cDestStructural(k),length(cSourceStructural{k}),1), ...
        (1:length(cDestStructural))','uni',false);
    cSourceStructural = cellnestflatten(cSourceStructural);
    cDestStructural = cellnestflatten(cDestStructural);
    
    % add staging area for converted files before renaming
    cStagingStructural = cellfun(@(dir) DirAppend(dir, 'staging'), cDestStructural, 'uni', false);
    cellfun(@mkdir, unique(cStagingStructural));

    cellfun(@dicm2nii, cSourceStructural, cStagingStructural);
    
    % rename files (add hard links)
    structuralOld = cellfun(@(dir) PathUnsplit(dir, 'anat_T1w_acq_MPRAGE','nii.gz'), ...
        cStagingStructural,'uni', false);
    structuralNew = cellfun(@(dir) PathUnsplit(dir, 'data', 'nii.gz'), ...
        cDestStructural, 'uni', false);
    cellfun(@(old,new) system(sprintf('ln -f %s %s',old,new)), structuralOld, structuralNew);


% diffusion
    strPathDiffusion = DirAppend(strDirData,'diffusion');
    cDestDiffusion = cellfun(@(code) DirAppend(strPathDiffusion, code),cCode,'uni',false);
    cellfun(@mkdir, cDestDiffusion);

    cSourceDiffusion = cellfun(@(dir) FindDirectories(dir,'dwi'), cDirDICOM, 'uni', false);
    cDestDiffusion = arrayfun(@(k) repmat(cDestDiffusion(k),length(cSourceDiffusion{k}),1), ...
        (1:length(cDestDiffusion))','uni',false);
    cSourceDiffusion = cellnestflatten(cSourceDiffusion);
    cDestDiffusion = cellnestflatten(cDestDiffusion);
    
    % add staging area for converted files before renaming
    cStagingDiffusion = cellfun(@(dir) DirAppend(dir, 'staging'), cDestDiffusion, 'uni', false);
    cellfun(@mkdir, unique(cStagingDiffusion));

    cellfun(@dicm2nii, cSourceDiffusion, cStagingDiffusion);
    
    % rename files (add hard links)
    diffusionOld = FindFiles(cStagingDiffusion, 'dwi_run_acq\w*\.nii\.gz');
    diffusionNew = cellfun(@(dir) PathUnsplit(dir, 'data', 'nii.gz'), ...
        cDestDiffusion, 'uni', false);
    cellfun(@(old,new) system(sprintf('ln -f %s %s',old,new)), diffusionOld, diffusionNew);
    
    bValOld = FindFiles(cStagingDiffusion, '.*\.bval');
    bValNew = cellfun(@(dir) PathUnsplit(dir,'bval'), cDestDiffusion, 'uni', false);
    cellfun(@(old,new) system(sprintf('ln -f %s %s',old,new)), bValOld, bValNew);
    
    bVecOld = FindFiles(cStagingDiffusion, '.*\.bvec');
    bVecNew = cellfun(@(dir) PathUnsplit(dir,'bvec'), cDestDiffusion, 'uni', false);
    cellfun(@(old,new) system(sprintf('ln -f %s %s',old,new)), bVecOld, bVecNew);
    
% functional
    strPathFunctional = DirAppend(strDirData,'functional');
    cDestFunctional = cellfun(@(code) DirAppend(strPathFunctional, code),cCode,'uni',false);
    cellfun(@mkdir, cDestFunctional);

    cSourceFunctional = cellfun(@(dir) FindDirectories(dir,'func'), cDirDICOM, 'uni', false);
    cDestFunctional = arrayfun(@(k) repmat(cDestFunctional(k),length(cSourceFunctional{k}),1), ...
        (1:length(cDestFunctional))','uni',false);
    cSourceFunctional = cellnestflatten(cSourceFunctional);
    cDestFunctionalFlat = cellnestflatten(cDestFunctional);
    
    % add staging area for converted files before renaming
    cStagingFunctional = cellfun(@(dir) DirAppend(dir, 'staging'), cDestFunctionalFlat, 'uni', false);
    cellfun(@mkdir, unique(cStagingFunctional));

    cellfun(@dicm2nii, cSourceFunctional, cStagingFunctional);
    
    % rename files (add hard links)
    functionalOld = cellfun(@(cSubDest) ...
        arrayfun(@(kRun) PathUnsplit(DirAppend(cSubDest{kRun},'staging'), sprintf('func_run_%d_task',kRun), 'nii.gz'), ...
        (1:length(cSubDest))', 'uni', false), cDestFunctional, 'uni', false);
    
    functionalNew = cellfun(@(cSubDest) ...
        arrayfun(@(kRun) PathUnsplit(cSubDest{kRun}, sprintf('data_%02d',kRun), 'nii.gz'), ...
        (1:length(cSubDest))', 'uni', false), cDestFunctional, 'uni', false);

    cellfun(@(old,new) system(sprintf('ln -f %s %s',old,new)), ...
        cellnestflatten(functionalOld), cellnestflatten(functionalNew));
end
