% Analysis_20170302_ROICCMVPA.m
% roi cross-classification analysis with the 6 gridop ROIs, on the 11 new
% subjects
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore	= 12;
dimPCA	= 50;

%create directory for analysis results
	strNameAnalysis	= '20170302_roiccmvpa';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);

%get subject info
	ifo			= PercIm.SubjectInfo;
	cSession	= ifo.code.fmri_new;
	
	s	= PercIm.ClassificationInfo('session',cSession,'ifo',ifo,'fcorrect',@CorrectTimings);

%the ROIs
	sMask	= PercIm.Masks;
	
	cMask	= sMask.ci;

%classify each scheme

	cEmpiricalSM = MWPI.CalcSimMatrix(cSession);

	idealSM	=	[
					4 2 1 1
					2 4 1 1
					1 1 4 2
					1 1 2 4
				];
			
	cModel = {cEmpiricalSM; idealSM};
	
	cScheme	= fieldnames(s.attr.target);
	nScheme	= numel(cScheme);
	
	for kS=1:nScheme
		strScheme	= cScheme{kS};
		
		%current output directory
			strDirOutScheme	= DirAppend(strDirOut,strScheme);
		
		%targets and chunks
			cTarget	= s.attr.target.(strScheme).correct;
			kChunk	= s.attr.chunk.correct;
			
			durRun	= MWPI.Param('exp','run','time');
			nRun	= cellfun(@(c) numel(c)/durRun,kChunk,'uni',false);
			kRun	= cellfun(@(n) reshape(repmat(1:n,[durRun 1]),[],1),nRun,'uni',false);
		
		%ROI Cross-classification!
			res.(strScheme)	= MVPAROICrossClassify(...
								'dir_out'			, strDirOutScheme	, ...
								'dir_data'			, strDirData		, ...
								'subject'			, cSession			, ...
								'mask'				, cMask				, ...
								'dim'				, dimPCA			, ...
								'targets'			, cTarget			, ...
								'chunks'			, kChunk			, ...
								'target_blank'		, 'Blank'			, ...
								'zscore'			, kRun				, ...
								'spatiotemporal'	, true				, ...
								'confusion_model'	, cModel			, ...
								'confcorr_method'	, 'subjectJK'		, ...
								'matched_confmodels', true				, ...
								'debug'				, 'all'				, ...
								'debug_multitask'	, 'info'			, ...
								'cores'				, nCore				  ...
								);
	end

%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');    
	save(strPathOut,'res');
