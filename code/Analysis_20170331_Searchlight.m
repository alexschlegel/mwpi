% Analysis_20170331_Searchlight.m
% SEARCHLIGHT mwpi analysis!
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore		= 11;

%create directory for analysis results
	strNameAnalysis	= '20170331_searchlight';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);

%get subject info
	ifo			= PercIm.SubjectInfo;
	cSession	= ifo.code.fmri;
	
	% the CorrectTimings function is not tracked by GitHub b/c it contains
	% subject codes.
	s	= PercIm.ClassificationInfo('session',cSession,'ifo',ifo,'fcorrect',@CorrectTimings);

%classify each scheme

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
		
		%ROI Classification!

			res.(strScheme) = MVPASearchlight(...
								'dir_out'			, strDirOutScheme	, ...
								'dir_data'			, strDirData		, ...
								'subject'			, cSession			, ...
								'targets'			, cTarget			, ...
								'chunks'			, kChunk			, ...
								'target_blank'		, 'Blank'			, ...
								'zscore'			, kRun				, ...
								'debug_multitask'	, 'info'			, ...
								'cores'				, nCore				, ...
								'force'				, false				  ...
								);
	end

%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut,'res');
