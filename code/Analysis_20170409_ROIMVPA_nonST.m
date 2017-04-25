% Analysis_20170409_ROIMVPA_nonST.m
% roi classification analysis with the 6 gridop ROIs - non-spatiotemporal.
% Separate analysis for each of the 4 TRs (excluding the first, for HRF)
% adapted from mwlearn code

global strDirData
global strDirAnalysis

nCore		= 12;
dimPCAMin	= 10;

%create directory for analysis results
	strNameAnalysis	= '20170409_roimvpa_nonst';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);

%get subject info
	ifo			= PercIm.SubjectInfo;
	cSession	= ifo.code.fmri;
	
	% the CorrectTimings function is not tracked by GitHub b/c it contains
	% subject codes.
	s	= arrayfun(@(kTR) PercIm.ClassificationInfo('session',cSession,...
		'ifo',ifo,'fcorrect',@CorrectTimings,'offset',kTR-1,'maxlen',1), ...
		(1:4)','uni',false);

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
				
	cScheme	= fieldnames(s{1}.attr.target);
	nScheme	= numel(cScheme);
	
	for kS=1:nScheme
		strScheme	= cScheme{kS};
		
		for kTR=1:4
			
			strTR = ['TR' num2str(kTR)];
			%current output directory
				strDirOutScheme	= DirAppend(strDirOut,strTR,strScheme);
				
			%targets and chunks
				cTarget	= s{kTR}.attr.target.(strScheme).correct;
				kChunk	= s{kTR}.attr.chunk.correct;
			
				durRun	= MWPI.Param('exp','run','time');
				nRun	= cellfun(@(c) numel(c)/durRun,kChunk,'uni',false);
				kRun	= cellfun(@(n) reshape(repmat(1:n,[durRun 1]),[],1),nRun,'uni',false);
		
			%ROI Classification!

				res(kTR).(strScheme) = MVPAROIClassify(...
								'dir_out'			, strDirOutScheme	, ...
								'dir_data'			, strDirData		, ...
								'subject'			, cSession			, ...
								'mask'				, cMask				, ...
								'mindim'			, dimPCAMin			, ...
                                'targets'			, cTarget			, ...
								'chunks'			, kChunk			, ...
								'target_blank'		, 'Blank'			, ...
								'zscore'			, kRun				, ...
								'confusion_model'	, idealSM			, ...
								'confcorr_method'	, 'subjectJK'		, ...
								'matched_confmodels', false				, ...
								'debug'				, 'all'				, ...
								'debug_multitask'	, 'info'			, ...
								'cores'				, nCore				, ...
								'force'				, true...false				  ...
								);
		end
	end

%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut,'res');
    
    
% figures
nMask = length(cMask);
cm = lines(nMask);

% Accuracy pfdr
fh = figure;
for kS = 1:nScheme
    subplot(1,3,kS);
    for kMask = 1:length(res(1).(cScheme{kS}).mask)
        series = arrayfun(@(kT) res(kT).(cScheme{kS}).result.allway.stats.accuracy.pfdr(kMask), 1:4);
        plot(series, 'color', cm(kMask,:));
        hold on;
    end
    legend(res(1).(cScheme{kS}).mask);
    title(['Accuracy over time for ' cScheme{kS}]);
    xlabel('Timepoint (TR)');
    ylabel('Significance (pfdr)');
end
saveas(fh, PathUnsplit(strDirOut, 'accuracy_sig', 'fig'));

% Confusion correlation pfdr
fh = figure;
for kS = 1:nScheme
    h = subplot(1,3,kS);
    for kMask = 1:length(res(1).(cScheme{kS}).mask)
        series = arrayfun(@(kT) res(kT).(cScheme{kS}).result.allway.stats.confusion.corr.pfdr(kMask), 1:4);
        plot(series, 'color', cm(kMask,:));
        hold on;
    end
    legend(res(1).(cScheme{kS}).mask);
    title(['Confusion corr over time for ' cScheme{kS}]);
    xlabel('Timepoint (TR)');
    ylabel('Significance (pfdr)');
end
saveas(fh, PathUnsplit(strDirOut, 'confusion_sig', 'fig'));

% Conclusion: distractor stimuli are never significant, so 
% don't have to clip any TRs for further analysis!
