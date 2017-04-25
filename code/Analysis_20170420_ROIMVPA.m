% Analysis_20170420_ROIMVPA.m
% roi classification analysis with the 6 gridop ROIs, on all 23 subjs,
% saving tabulated results.
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore		= 11;
dimPCAMin	= 10;

%create directory for analysis results
	strNameAnalysis	= '20170420_roimvpa';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);

%get subject info
	ifo			= PercIm.SubjectInfo;
	cSession	= ifo.code.fmri;
	
	% the CorrectTimings function is not tracked by GitHub b/c it contains
	% subject codes.
	s	= PercIm.ClassificationInfo('session',cSession,'ifo',ifo,'fcorrect',@CorrectTimings);

%the ROIs
	sMask	= PercIm.Masks;
	
	cMask	= sMask.ci;

%classify each scheme
	idealSM	=	[
					4 2 1 1
					2 4 1 1
					1 1 4 2
					1 1 2 4
				];
				
	cScheme	= fieldnames(s.attr.target);
	nScheme	= numel(cScheme);
	
	for kS=1:nScheme
		strScheme	= cScheme{kS};
        cExtraScheme = setdiff(cScheme,strScheme);
		
		%current output directory
			strDirOutScheme	= DirAppend(strDirOut,strScheme);
		
		%targets and chunks
			cTarget	= s.attr.target.(strScheme).correct;
            
            % extra targets
            sExtraTarget = struct();
            for kT = 1:numel(cExtraScheme)
                strCurrScheme = cExtraScheme{kT};
                sExtraTarget.(strCurrScheme) = s.attr.target.(strCurrScheme).correct;
            end
            sExtraTarget = restruct(sExtraTarget);
            
			kChunk	= s.attr.chunk.correct;
			
			durRun	= MWPI.Param('exp','run','time');
			nRun	= cellfun(@(c) numel(c)/durRun,kChunk,'uni',false);
			kRun	= cellfun(@(n) reshape(repmat(1:n,[durRun 1]),[],1),nRun,'uni',false);
		
		%ROI Classification!

			res.(strScheme) = MVPAROIClassify(...
								'dir_out'			, strDirOutScheme	, ...
								'dir_data'			, strDirData		, ...
								'subject'			, cSession			, ...
								'mask'				, cMask				, ...
								'mindim'			, dimPCAMin			, ...
								'targets'			, cTarget			, ...
                                'extra_targets'     , sExtraTarget      , ...
                                'tabulate_results'  , true              , ...
								'chunks'			, kChunk			, ...
								'target_blank'		, 'Blank'			, ...
								'zscore'			, kRun				, ...
								'spatiotemporal'	, true				, ...
								'confusion_model'	, idealSM			, ...
								'confcorr_method'	, 'subjectJK'		, ...
								'matched_confmodels', false				, ...
								'debug'				, 'all'				, ...
								'debug_multitask'	, 'info'			, ...
								'cores'				, nCore				, ...
								'force'				, false				  ...
								);
	end

%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut,'res');
