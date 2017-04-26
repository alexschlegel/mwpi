function Analysis_20170425_ANOVA
% Analysis_20170425_ANOVA.m
% compute ANOVAs on classification accuracy between same, related, and
% unrelated image/percept intersections.

global strDirData
global strDirAnalysis

% create directory for analysis results
	strNameAnalysis = '20170425_anova';
	strDirOut		= DirAppend(strDirAnalysis, strNameAnalysis);
	CreateDirPath(strDirOut);
	
cScheme = {'percept';'image'};
strSchemeExtra = 'image_uncued';

cType = {'same','related','unrelated'};
tMeasure = table(cType, 'VariableNames', {'type'});

res = struct();

% 1) ROI classification
	% load data struct
	sROIRes = load(PathUnsplit(DirAppend(strDirAnalysis, '20170420_roimvpa'),'result','mat'));
	
	for kS = 1:2
		strScheme = cScheme{kS};
		strSchemeOther = cScheme{3-kS};
		
		cMask = sROIRes.res.(strScheme).mask;
		sTab  = sROIRes.res.(strScheme).result.allway.tab;
		
		% convert everything to nMask x nSubject cells, then restruct
		sTab = structtreefun(@(x) squeeze(num2cell(x,1:ndims(x)-2)), sTab);
		sTab = restruct(sTab);
		[nMask, nSubject] = size(sTab);
		
		cMaskRep = repmat(cMask, 1, nSubject);
		
		% get accuracy values for each mask and subject
		cAccuracy = cellfun(@GetAccuracies, num2cell(sTab), cMaskRep, 'uni', false);
		tAccuracy = vertcat(cAccuracy{:});
		
		% fit a repeated measures model
		rm = fitrm(tAccuracy, [strjoin(cType,',') '~mask'], 'WithinDesign', tMeasure);
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
			
			tAccuracy = table({strMask}, accPerType(1), accPerType(2), accPerType(3), ...
				'VariableNames', [{'mask'} cType]);
	end
end