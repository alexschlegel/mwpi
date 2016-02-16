function SimTest(mwpi, varargin)
% SimTest - do a similarity test. This is an assessment of the subject's
% perception of how similar the four stimulus classes are. Ends after the next
% trial that is a multiple of 4 the escape key is pressed on the keyboard 
% during a trial (so that the classes tested are balanced).
%
% Syntax: mwpi.SimTest(<options>)
%
% In:
%	<options>:
%		d:			(calculated based on subject's trial history) a 4x1 array
%					of d values to use to generate stimuli from each class.
%
% Updated: 2016-02-08

ListenChar(2);

exp = mwpi.Experiment;

% figure out the parameters
opt = ParseArgs(varargin, 'd',	[]);

if ~isempty(opt.d)
	if isa(opt.d, 'float') && numel(opt.d) == 4 && max(opt.d) <= 1 && min(opt.d) >= 0
		opt.d = reshape(opt.d, 4,1);
	else
		error('Invalid input for d option: must be a 4x1 vector of floats between 0 and 1 inclusive');
	end
else
	% use saved trials to make a psychometric curve
	sHistory = exp.Subject.Get('history');
    if isempty(sHistory)
        sHistory = dealstruct('d', 'result', 'task', []);
    end
	
	% dummy function for subject.assess
	fDummy = @(d,p) true;
	
	curve		= MWPI.Param('curve');

	assess = subject.assess(repmat({fDummy},4,1), ...
		'chance',	curve.chancePerformance, ...
		'target',	curve.thresholdPerformance, ...
		'd',		(curve.xmin : curve.xstep : curve.xmax), ...
		'd_hist',	sHistory.d, ...
		'res_hist',	sHistory.result, ...
		'task_hist',sHistory.task ...
		);
	opt.d = assess.ability;
	clear('assess');	
end
exp.Info.Set('mwpi', 'simD', opt.d);

% now do the similarity tests.
secsWait = MWPI.Param('simtest', 'rest');

szStimVA  = MWPI.Param('stim', 'size');
szStim  = round(exp.Window.va2px(szStimVA));

colRank = MWPI.Param('simtest', 'colRank');

cKey = [exp.Input.Get('up')
		exp.Input.Get('right')
		exp.Input.Get('down')
		exp.Input.Get('left')
		];
arrKey = cell2mat(cKey);

kTrial = 0;

bEnd = false;
while ~bEnd
	% do a round of 4 similarity trials
	classOrder = randomize(1:4);
	for k = 1:4
		kClass = classOrder(k);
		kTrial = kTrial + 1;
		
		% show blank for a rest period
		exp.Show.Blank;
		exp.Window.Flip;
		WaitSecs(secsWait);
		
		exp.AddLog(['Starting trial ' num2str(kTrial) ]);
		if ~mwpi.bPractice
			exp.Scanner.StartScan;
		end
		thisRes = SimTrial(kClass);
		if ~mwpi.bPractice
			exp.Scanner.StopScan;
		end
		
		% save results
		sRes = exp.Info.Get('mwpi', 'simRes');
		if isempty(sRes)
			sRes = thisRes;
		else
			sRes(end+1) = thisRes;
		end
		exp.Info.Set('mwpi', 'simRes', sRes);
		exp.AddLog(['Saved trial ' num2str(kTrial)]);
	end
end

exp.Show.Blank;
exp.Window.Flip;

ListenChar(0);

%---------------------------------------------------------------------%
	function res = SimTrial(kClass)
		%
		% In: kClass: the stimulus class shown in the center for this trial
		
		% generate stimuli
		arrSeed = MWPI.GenSeeds(5);
		res.sampleSeed = arrSeed(1);
		res.sampleClass = kClass;
		res.sampleD     = opt.d(kClass);
		
		res.choiceSeed = arrSeed(2:5);
		res.choiceClass = randomize((1:4)');
		res.choiceD     = opt.d(res.choiceClass);
		
		sampleStim = MWPI.Stimulus(res.sampleClass, res.sampleSeed, res.sampleD, szStim);
		sampleStim = sampleStim.base;
		cChoiceStim = arrayfun(@(cl,sd,d) MWPI.Stimulus(cl, sd, d, szStim), ...
			res.choiceClass, res.choiceSeed, res.choiceD, 'uni', false);
		cChoiceStim = cellfun(@(s) s.base, cChoiceStim, 'uni', false);
		
		% show stimuli		
		stimOffset  = MWPI.Param('stim', 'offset') * 1.2;
		fPos =  @(offset) {[0,-offset]; [offset, 0]; [0, offset]; [-offset, 0]};
		cStimPos = fPos(stimOffset);
		
		% now let them rank them
		numOffset = stimOffset;
		cNumPos = fPos(numOffset);
		
		if ~mwpi.bPractice
			exp.Serial.Clear;
		end
		
		% let zero indicate no rank yet
		ranking = zeros(4,1);
		
		while true
			exp.Show.Image(sampleStim);
			cellfun(@(im,offset) exp.Show.Image(im, offset), cChoiceStim, cStimPos);
			
			ranked = find(ranking);
			% show current rankings
			arrayfun(@(pos,rank) exp.Show.Text(['<color:' colRank '>' num2str(rank) ...
				'</color>'], cNumPos{pos}), ranked, ranking(ranked), 'uni', false);
			
			exp.Window.Flip;
			if all(ranking)
				break;
			end
						
			% now wait for them to press a button
			if mwpi.bPractice
				keyboard = exp.Input;
			else
				keyboard = exp.Input.Key;
			end
			[~, ~, kButton, bAbort] = exp.Input.WaitDownOnce('responselrud', ...
				'fabort', @() keyboard.DownOnce('abort'));
			
			if bAbort
				bEnd = true;
			else
				kButton = kButton(1);
				indPressed = find(kButton == arrKey);
				
				if ranking(indPressed) ~= 0
					ranking(indPressed) = 0;
				else
					ranking(indPressed) = min(setdiff(1:4, ranking));
				end
			end
		end
		res.ranking = ranking;
		res.classesInOrderOfSimilarity = res.choiceClass(res.ranking);
		% invert permutation for alternate format
		res.similarityRankingOfClass = zeros(4,1);
		res.similarityRankingOfClass(res.classesInOrderOfSimilarity) = 1:4;
		WaitSecs(0.5);
	end
end