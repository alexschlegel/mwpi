function res = Analysis_20170505_ANOVA_noPCU
% Analysis_20170425_ANOVA.m
% compute ANOVAs on classification accuracy between same, related, and
% unrelated image/percept intersections.

global strDirAnalysis

% create directory for analysis results
strNameAnalysis = '20170505_anova_no_pcu';
strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
CreateDirPath(strDirOut);

cScheme = {'percept';'image'};
strSchemeExtra = 'image_uncued';

cType = {'same','related','unrelated'};
tMeasure = table(cType', 'VariableNames', {'type'});

% 1) ROI classification
sROIRes = load(PathUnsplit(DirAppend(strDirAnalysis, '20170420_roimvpa'),'result','mat'));
res = DoANOVA(sROIRes);

%save the results
strPathOut	= PathUnsplit(strDirOut,'result','mat');
save(strPathOut,'res');

	function res = DoANOVA(sResult)
		for kS = 1:2
			strScheme = cScheme{kS};
			strSchemeOther = cScheme{3-kS};
			
			cMask = sResult.res.(strScheme).mask;
			bPCU = strcmp('pcu',cMask);
			cMask = cMask(~bPCU);
			res.mask = cMask;
			sTab  = sResult.res.(strScheme).result.allway.tab;
			
			% convert everything to nMask x nSubject cells, then restruct
			sTab = structtreefun(@(x) squeeze(num2cell(x,1:ndims(x)-2)), sTab);
			sTab = restruct(sTab);
			nSubject = size(sTab,2);
			
			% get rid of pcu
			sTab = sTab(~bPCU,:);	
			
			cMaskRep = repmat(cMask, 1, nSubject);
			
			% get accuracy values for each mask and subject
			cAccuracy = cellfun(@GetAccuracies, num2cell(sTab), cMaskRep, 'uni', false);
			tAccuracy = vertcat(cAccuracy{:});
			res.(strScheme).accuracy = tAccuracy;
			
			% fit repeated measures models
			rm = fitrm(tAccuracy, [strjoin(cType,',') '~mask'], 'WithinDesign', tMeasure);
			res.(strScheme).table = ranova(rm);
			res.(strScheme).post = multcompare(rm, 'type', 'By', 'mask');
			res.(strScheme).postCombined = multcompare(rm, 'type');
			
			% individual ANOVAs for each mask
			cAccuracyTable = cellfun(@(mask) tAccuracy(strcmp(tAccuracy.mask,mask),:), cMask, 'uni', false);
			res.(strScheme).perMask.accuracy = cAccuracyTable;
			cRM = cellfun(@(t) fitrm(t, [strjoin(cType,',') '~1'], 'WithinDesign', tMeasure), ...
				cAccuracyTable, 'uni', false);
			cResult = cellfun(@ranova, cRM, 'uni', false);
			res.(strScheme).perMask.p = cellfun(@(result) result.pValue(1), cResult);
		end
		
		
		function tAccuracy = GetAccuracies(sTab, strMask)
			% identify dimensions and permute
			sTab.dims = strip(num2cell(sTab.dims,2));
			kDimScheme = find(strcmp(sTab.dims, 'targets'));
			kDimOther = find(strcmp(sTab.dims, strSchemeOther));
			kDimExtra = find(strcmp(sTab.dims, strSchemeExtra));
			order = [kDimScheme, kDimOther, kDimExtra];
			sTab.all = permute(sTab.all, order);
			sTab.correct = permute(sTab.correct, order);
			
			% sum accross extra (irrelevant) dimension
			sTab.all = sum(sTab.all, 3);
			sTab.correct = sum(sTab.correct, 3);
			
			% reorder rows/columns if necessary
			cTarget = {'BR';'BS';'SC';'SW'};
			sTab.rows = structfun(@(x) num2cell(x,2), sTab.rows, 'uni', false);
			indScheme = zeros(1,length(cTarget));
			indOther  = zeros(1,length(cTarget));
			for kT = 1:length(cTarget)
				indScheme(kT) = find(strcmp(sTab.rows.targets, cTarget{kT}));
				indOther(kT)  = find(strcmp(sTab.rows.(strSchemeOther), cTarget{kT}));
			end
			sTab.all = sTab.all(indScheme, indOther);
			
			% sort into types and package as table
			matType = [ 1 2 3 3
						2 1 3 3
						3 3 1 2
						3 3 2 1 ];
			
			allPerType = arrayfun(@(kType) ...
				sum(arrayfun(@(entry,myType) ...
				conditional(myType == kType, entry, 0), sTab.all(:), matType(:))), ...
				1:3);
			
			correctPerType = arrayfun(@(kType) ...
				sum(arrayfun(@(entry,myType) ...
				conditional(myType == kType, entry, 0), sTab.correct(:), matType(:))), ...
				1:3);
			
			accPerType = correctPerType ./ allPerType;
			
			tAccuracy = cell2table([{strMask}, num2cell(accPerType)], ...
				'VariableNames', [{'mask'} cType]);
		end
	end
end