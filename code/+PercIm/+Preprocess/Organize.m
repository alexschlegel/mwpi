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
    cellfun(@(code) mkdir(strPathStructural,code),cCode);
    cDestStructural = cellfun(@(code) DirAppend(strPathStructural, code),cCode,'uni',false);

    cSourceStructural = cellfun(@(dir) FindDirectories(dir,'anat-T1w'), cDirDICOM, 'uni', false);
    cDestStructural = arrayfun(@(k) repmat(cDestStructural(k),length(cSourceStructural{k}),1), ...
        (1:length(cDestStructural))','uni',false);
    cSourceStructural = cellnestflatten(cSourceStructural);
    cDestStructural = cellnestflatten(cDestStructural);

    cellfun(@dicm2nii, cSourceStructural, cDestStructural);

% diffusion
    strPathDiffusion = DirAppend(strDirData,'diffusion');
    cellfun(@(code) mkdir(strPathDiffusion,code),cCode);
    cDestDiffusion = cellfun(@(code) DirAppend(strPathDiffusion, code),cCode,'uni',false);

    cSourceDiffusion = cellfun(@(dir) FindDirectories(dir,'dwi'), cDirDICOM, 'uni', false);
    cDestDiffusion = arrayfun(@(k) repmat(cDestDiffusion(k),length(cSourceDiffusion{k}),1), ...
        (1:length(cDestDiffusion))','uni',false);
    cSourceDiffusion = cellnestflatten(cSourceDiffusion);
    cDestDiffusion = cellnestflatten(cDestDiffusion);

    cellfun(@dicm2nii, cSourceDiffusion, cDestDiffusion);
    
% functional
    strPathFunctional = DirAppend(strDirData,'functional');
    cellfun(@(code) mkdir(strPathFunctional,code),cCode);
    cDestFunctional = cellfun(@(code) DirAppend(strPathFunctional, code),cCode,'uni',false);

    cSourceFunctional = cellfun(@(dir) FindDirectories(dir,'func'), cDirDICOM, 'uni', false);
    cDestFunctional = arrayfun(@(k) repmat(cDestFunctional(k),length(cSourceFunctional{k}),1), ...
        (1:length(cDestFunctional))','uni',false);
    cSourceFunctional = cellnestflatten(cSourceFunctional);
    cDestFunctional = cellnestflatten(cDestFunctional);

    cellfun(@dicm2nii, cSourceFunctional, cDestFunctional);

end
