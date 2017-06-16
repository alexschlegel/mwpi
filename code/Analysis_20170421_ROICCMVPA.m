% Analysis_20170421_ROICCMVPA.m
% roi cross-classification analysis with the 6 gridop ROIs
% saving tabulated results.
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore	= 11;
dimPCA	= 50;

%create directory for analysis results
	strNameAnalysis	= '20170421_roiccmvpa';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);

%get subject info
	ifo			= PercIm.SubjectInfo;
	cSession	= ifo.code.fmri;
	
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
		
		%ROI Cross-classification!
			res.(strScheme)	= MVPAROICrossClassify(...
								'dir_out'			, strDirOutScheme	, ...
								'dir_data'			, strDirData		, ...
								'subject'			, cSession			, ...
								'mask'				, cMask				, ...
								'dim'				, dimPCA			, ...
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
	% correlation
	% construct connection matrices
	nMask = length(cMask);
	schemes = {'percept', 'image'};
	[cConnection, cSig, cSigCorr] = deal(repmat({NaN(nMask)}, 1, length(schemes)));
	trilInds = find(tril(cConnection{1}, -1));
	colors = GetPlotColors(2);
	
	% image
	for kS = 1:length(schemes)
		strScheme = schemes{kS};
		cConnection{kS}(trilInds) = res.(strScheme).result.allway.stats.confusion.corr.mr;
		cSig{kS}(trilInds) = res.(strScheme).result.allway.stats.confusion.corr.p;
		cSigCorr{kS}(trilInds) = res.(strScheme).result.allway.stats.confusion.corr.pfdr;
		cLUT{kS} = MakeLUT(colors(kS,:),1);
	end

	h = alexplot(cConnection, 'type', 'connection', 'label', upper(cMask), 'sig', cSig, ...
		'sigcorr', cSigCorr, 'arcwidth', 'scale', 'lut', cLUT);
	