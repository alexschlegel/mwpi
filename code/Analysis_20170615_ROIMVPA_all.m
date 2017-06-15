% Analysis_20170615_ROIMVPA_all.m
% roi classification analysis with the 6 gridop ROIs, on all 23 subjs,
% saving tabulated results, on all trials (not just correct)
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore		= 11;
dimPCAMin	= 10;

%create directory for analysis results
	strNameAnalysis	= '20170615_roimvpa_all';
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
			cTarget	= s.attr.target.(strScheme).all;
            
            % extra targets
            sExtraTarget = struct();
            for kT = 1:numel(cExtraScheme)
                strCurrScheme = cExtraScheme{kT};
                sExtraTarget.(strCurrScheme) = s.attr.target.(strCurrScheme).all;
            end
            sExtraTarget = restruct(sExtraTarget);
            
			kChunk	= s.attr.chunk.all;
			
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

	
% plot results
% 
% 	% accuracy
% 	barlabel = {'perceived';'remembered'};
% 	schemes = {'percept','image'};
% 	y = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.accuracy.mean, schemes, 'uni', false));
% 	sig = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.accuracy.pfdr, schemes, 'uni', false));
% 	err = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.accuracy.se, schemes, 'uni', false));
% 	chance = 0.25;
% 	
% 	h = alexplot(y, 'type', 'bar', 'grouplabel', upper(cMask), 'barlabel', barlabel, 'sig', sig, ...
% 		'hline', chance, 'ylabel', 'Accuracy (%)', 'error', repmat(err,1,1,2));
% 
% 	% confusion correlation
% 	y = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.confusion.corr.mz, schemes, 'uni', false));
% 	sig = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.confusion.corr.pfdr, schemes, 'uni', false));
% 	err = cell2mat(cellfun(@(sch) res.(sch).result.allway.stats.confusion.corr.sez, schemes, 'uni', false));
% 	
% 	h2 = alexplot(y, 'type', 'bar',  'grouplabel', upper(cMask), 'barlabel', barlabel, 'sig', sig, ...
% 		'ylabel', 'Fisher''s z (r)', 'error', repmat(err,1,1,2), 'axistype','zero');
% 
