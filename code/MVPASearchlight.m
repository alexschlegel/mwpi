function res = MVPASearchlight(varargin)
%
% 
% Description: perform a searchlight analysis using MVPAClassify as an
%              interface to PyMVPA.
% 
% Syntax:	res = MVPASearchlight(<options>)
% 
% In:
% 	<options>:
%		<+ options for MRIParseDataPaths>
%		<+ options for MVPAClassify>
%		targets:	(<required>) a cell specifying the target for each sample,
%					or a cell of cells (one for each dataset)
%		chunks:		(<required>) an array specifying the chunks for each sample,
%					or a cell of arrays (one for each dataset)
%       radii:      ([4 5 6]) the spatial radii to use in the searchlight
%                   (in voxels)
%		cores:		(1) the number of processor cores to use
%		force:		(true) true to force classification if the outputs already
%					exist
%		force_pre:	(false) true to force preprocessing steps if the output
%					already exists
%		silent:		(false) true to suppress status messages
% 
% Out:
% 	info - struct containing cell of output paths with some other info
%
% Example:
%	cMask	= {'dlpfc';'occ';'ppc'};
%	res = MVPASearchlight(...
%			'dir_data'			, strDirData	, ...
%			'subject'			, cSubject		, ...
%			'targets'			, cTarget		, ...
%			'chunks'			, kChunk		, ...
%			'target_blank'		, 'Blank'		, ...
%			'dir_out'			, strDirOut		, ...
%           'radii'             , [3 5 6]       , ...
%			'cores'				, 11			  ...
%			);
% 
% Updated: 2017-03-31
% Copyright 2017 Ethan Blackwood (Ethan.B.Blackwood.17@dartmouth.edu).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

% parse the inputs
	opt		= ParseArgs(varargin,...
				'targets'		, []			, ...
				'chunks'		, []			, ...
                'radii'         , [4 5 6]       , ...
				'zscore'		, 'chunks'		, ...
				'cores'			, 1				, ...
				'force'			, true			, ...
				'force_pre'		, false			, ...
				'silent'		, false			  ...
				);
            
	assert(~isempty(opt.targets),'targets must be specified.');
	assert(~isempty(opt.chunks),'chunks must be specified.');
    
    opt_path	= optreplace(opt.opt_extra,...
					'require'	, {'functional','mask'}	  ...
					);
	cOptPath	= opt2cell(opt_path);
	sPath		= ParseMRIDataPaths(cOptPath{:});
    
    %analysis-specific parameters
    param   = optstruct(struct,struct);
	param	= optadd(param,...
				'default'		, struct				, ...
				'opt'			, struct				  ...
				);
	
	param.default	= optadd(param.default,...
						'dim'	, []	  ...
						);
	
	param.opt	= optadd(param.opt,...
					'mvpa'	, optstruct(struct,struct)	  ...
					);
                
% searchlight radii
cPathData = reshape(sPath.functional, [], 1);
cSession = reshape(sPath.functional_session, [], 1);
opt.radii = reshape(opt.radii, 1, []);

cPathDataRep = repmat(cPathData, 1, length(opt.radii));
cSessionRep = repmat(cSession, 1, length(opt.radii));
cRadiiRep = num2cell(repmat(opt.radii, length(cSession), 1));

% construct names
cName = cellfun(@(sess,rad) sprintf('%s-r%d',sess,rad), cSessionRep, cRadiiRep, 'uni', false);
    
%classify!
cOptMVPA	= opt2cell(param.opt.mvpa);
opt_mvpa	= optadd(sPath.opt_extra,...
                'type'              , 'searchlight' , ...
                'searchlight'       , true          , ...
                'searchlight_radius', cRadiiRep   , ...
                'spatiotemporal'    , true          , ...          
                'combine'           , false         , ...
                'stats'             , false           ...
                );

opt_mvpa	= optreplace(opt_mvpa,cOptMVPA{:},...
                'name'		, cName             , ...
                'zscore'	, opt.zscore		, ...
                'cores'		, opt.cores			, ...
                'force'		, opt.force			, ...
                'silent'	, opt.silent		  ...                
                );

cOptMVPA	= opt2cell(opt_mvpa);
res			= MVPAClassify(cPathDataRep,opt.targets,opt.chunks,cOptMVPA{:});

end