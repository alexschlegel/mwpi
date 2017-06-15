function res = Analysis_20170505_behavioral
% Analysis_20170505_behavioral.m
% compute ANOVAs on response accuracy (during scan) between same, related, and
% unrelated image/percept intersections.

global strDirAnalysis

% create directory for analysis results
strNameAnalysis = '20170505_behavioral';
strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
CreateDirPath(strDirOut);

sCIfo = PercIm.ClassificationInfo('fcorrect', @CorrectTimings);

% filter out runs with low performance on fixation task
fixationThreshold = 0.85;

% accuracy
for filter = 0:1

	if filter
		cInclude = cellfun(@(fa) fa >= fixationThreshold, sCIfo.block.fixationAcc, 'uni', false);
		strAnalysis = 'filtered';
	else
		cInclude = cellfun(@(fa) true(size(fa)), sCIfo.block.fixationAcc, 'uni', false);
		strAnalysis = 'unfiltered';
	end

	cPercept = cellfun(@(p,inc) p(inc), sCIfo.block.percept, cInclude, 'uni', false);
	cImage = cellfun(@(im,inc) im(inc), sCIfo.block.image, cInclude, 'uni', false);
	cCorrect = cellfun(@(c,inc) c(inc), sCIfo.block.testCorrect, cInclude, 'uni', false);

	cType = {'same', 'related', 'unrelated'};

	cAccuracy = cellfun(@statPerCondition, cPercept, cImage, cCorrect, 'uni', false);
	tAccuracy = vertcat(cAccuracy{:});

	% fit repeated measures model
	tMeasure = table(cType', 'VariableNames', {'type'});
	res.acc.(strAnalysis).rm = fitrm(tAccuracy, [strjoin(cType,',') '~1'], 'WithinDesign', tMeasure);
	res.acc.(strAnalysis).table = ranova(res.acc.(strAnalysis).rm);
	res.acc.(strAnalysis).post = multcompare(res.acc.(strAnalysis).rm, 'type');
end

% reaction time (only correct trials)
	cInclude = sCIfo.block.correct;
	strAnalysis = 'correct';
	
	cPercept = cellfun(@(p,inc) p(inc), sCIfo.block.percept, cInclude, 'uni', false);
	cImage = cellfun(@(im,inc) im(inc), sCIfo.block.image, cInclude, 'uni', false);
	cRT = cellfun(@(rt,inc) rt(inc), sCIfo.block.rt, cInclude, 'uni', false);

	cRTPerCond = cellfun(@statPerCondition, cPercept, cImage, cRT, 'uni', false);
	tRT = vertcat(cRTPerCond{:});

	% fit repeated measures model
	res.rt.(strAnalysis).rm = fitrm(tRT, [strjoin(cType,',') '~1'], 'WithinDesign', tMeasure);
	res.rt.(strAnalysis).table = ranova(res.rt.(strAnalysis).rm);
	res.rt.(strAnalysis).post = multcompare(res.rt.(strAnalysis).rm, 'type');

	%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut,'res');

	% statPerCondition: get average value of a statistic for each of the 3 types of trials.
	function tStat = statPerCondition(arrPercept, arrImage, arrStat)
		matType = [ 1 2 3 3
					2 1 3 3
					3 3 1 2
					3 3 2 1 ];
		
		allPerType = zeros(1,3);
		statPerType = zeros(1,3);
		for kT = 1:3
			bThisType = arrayfun(@(p,im) matType(p,im) == kT, arrPercept, arrImage);
			allPerType(kT) = sum(bThisType);			
			statPerType(kT) = sum(arrStat(bThisType));
		end
		accPerType = statPerType ./ allPerType;
		tStat = array2table(accPerType,'VariableNames', cType);
	end

end