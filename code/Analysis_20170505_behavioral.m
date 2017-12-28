function res = Analysis_20170505_behavioral
% Analysis_20170505_behavioral.m
% compute ANOVAs on response accuracy (during scan) between same, related, and
% unrelated image/percept intersections.
% 2017-08-13 addendum: also compare response accuracy between classes (both perceptual and WM)

global strDirAnalysis

% create directory for analysis results
strNameAnalysis = '20170505_behavioral';
strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
CreateDirPath(strDirOut);

ifo = PercIm.SubjectInfo;
sCIfo = PercIm.ClassificationInfo('fcorrect', @CorrectTimings, 'ifo', ifo);

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

	% by consistency type
		cType = {'same', 'related', 'unrelated'};

		cAccPerCond = cellfun(@statPerCondition, cPercept, cImage, cCorrect, 'uni', false);
		tAccPerCond = vertcat(cAccPerCond{:});

		% fit repeated measures model
		tMeasure = table(cType', 'VariableNames', {'type'});
		res.consistency.acc.(strAnalysis).rm = fitrm(tAccPerCond, [strjoin(cType,',') '~1'], 'WithinDesign', tMeasure);
		res.consistency.acc.(strAnalysis).result = ranova(res.consistency.acc.(strAnalysis).rm);
		res.consistency.acc.(strAnalysis).post = multcompare(res.consistency.acc.(strAnalysis).rm, 'type');
		
	% by class
		cScheme = {'percept'; 'image'};
		for kScheme = 1:length(cScheme)
			strScheme = cScheme{kScheme};
			cClass = conditional(strcmp(strScheme, 'percept'), cPercept, cImage);
			
			cAccPerClass = cellfun(@statPerClass, cClass, cCorrect, 'uni', false);
			tAccPerClass = vertcat(cAccPerClass{:});
			
			% add source data
			res.class.acc.(strScheme).(strAnalysis).subjectMean = tAccPerClass;
			res.class.acc.(strScheme).(strAnalysis).grandMean = varfun(@mean, tAccPerClass);
			res.class.acc.(strScheme).(strAnalysis).stdErr = varfun(@(x) std(x)/sqrt(length(x)), tAccPerClass);
			
			% fit repeated measures model
			tClass = table(ifo.cClass, 'VariableNames', {'class'});
			res.class.acc.(strScheme).(strAnalysis).rm = fitrm(tAccPerClass, [strjoin(ifo.cClass, ',') '~1'], 'WithinDesign', tClass);
			res.class.acc.(strScheme).(strAnalysis).result = ranova(res.class.acc.(strScheme).(strAnalysis).rm);
			res.class.acc.(strScheme).(strAnalysis).post = multcompare(res.class.acc.(strScheme).(strAnalysis).rm, 'class');
		end
end

% reaction time (only correct trials)
	cInclude = sCIfo.block.correct;
	strAnalysis = 'correct';
	
	cPercept = cellfun(@(p,inc) p(inc), sCIfo.block.percept, cInclude, 'uni', false);
	cImage = cellfun(@(im,inc) im(inc), sCIfo.block.image, cInclude, 'uni', false);
	cRT = cellfun(@(rt,inc) rt(inc), sCIfo.block.rt, cInclude, 'uni', false);

	% by consistency type
		cRTPerCond = cellfun(@statPerCondition, cPercept, cImage, cRT, 'uni', false);
		tRTPerCond = vertcat(cRTPerCond{:});

		% fit repeated measures model
		res.consistency.rt.(strAnalysis).rm = fitrm(tRTPerCond, [strjoin(cType,',') '~1'], 'WithinDesign', tMeasure);
		res.consistency.rt.(strAnalysis).result = ranova(res.consistency.rt.(strAnalysis).rm);
		res.consistency.rt.(strAnalysis).post = multcompare(res.consistency.rt.(strAnalysis).rm, 'type');
		
	% by class
		cScheme = {'percept'; 'image'};
		for kScheme = 1:length(cScheme)
			strScheme = cScheme{kScheme};
			cClass = conditional(strcmp(strScheme, 'percept'), cPercept, cImage);
			
			cRTPerClass = cellfun(@statPerClass, cClass, cRT, 'uni', false);
			tRTPerClass = vertcat(cRTPerClass{:});
			
			% add source data
			res.class.rt.(strScheme).subjectMean = tRTPerClass;
			res.class.rt.(strScheme).grandMean = varfun(@mean, tRTPerClass);
			res.class.rt.(strScheme).stdErr = varfun(@(x) std(x)/sqrt(length(x)), tRTPerClass);
			
			% fit repeated measures model
			res.class.rt.(strScheme).rm = fitrm(tRTPerClass, [strjoin(ifo.cClass, ',') '~1'], 'WithinDesign', tClass);
			res.class.rt.(strScheme).result = ranova(res.class.rt.(strScheme).rm);
			res.class.rt.(strScheme).post = multcompare(res.class.rt.(strScheme).rm, 'class');
		end

	%save the results
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut,'res');

	%--------------------------------------------------%
	
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

	% statPerClass: get average value of a statistic for each class in arrClass (1 to 4)
	function tStat = statPerClass(arrClass, arrStat)
		arrAvgStat = zeros(1,4);
		for kClass = 1:4
			arrAvgStat(kClass) = mean(arrStat(arrClass == kClass));
		end
		tStat = array2table(arrAvgStat, 'VariableNames', ifo.cClass);
	end

end