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

% figure out the parameters--------------------------------
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


% prepare for tests ---------------------------------------

szStimVA  = 0.95 * MWPI.Param('stim', 'size'); % so they don't run into each other
szStim  = round(exp.Window.va2px(szStimVA));

colRank = MWPI.Param('simtest', 'colRank');

cKey = [exp.Input.Get('up')
		exp.Input.Get('right')
		exp.Input.Get('down')
		exp.Input.Get('left')
		];
arrKey = cell2mat(cKey);

kTrial = 0;

% open textures for use during trials
if isempty(exp.Window.Get('current'))
	exp.Window.OpenTexture('current');
end
if isempty(exp.Window.Get('original'))
	exp.Window.OpenTexture('original');
end


% offset constants
stimOffset  = MWPI.Param('stim', 'offset');
fPos =  @(offset) {[0,-offset]; [offset, 0]; [0, offset]; [-offset, 0]};
cStimPos = fPos(stimOffset);
		
numOffset = stimOffset;
cNumPos = fPos(numOffset);


% show instructions-----------------------------------------

szInst = MWPI.Param('text','szInst');

exp.Show.Instructions(['<size:' num2str(szInst) '>In the following trials, a sample stimulus will appear ' ...
	'in the center, with four more stimuli around it. Using the button box, rank ' ...
	'each surrounding stimulus according to how perceptually similar it is to the ' ...
	'sample stimulus (most similar first, least similar last).</size>']);

% now do the similarity tests --------------------------------
bEnd = false;
while ~bEnd
	% do a round of 4 similarity trials
	classOrder = randomize(1:4);
	for k = 1:4
		kClass = classOrder(k);
		kTrial = kTrial + 1;
		
		% show blank
		exp.Show.Blank;
		exp.Window.Flip;
		
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
		exp.Info.Save;
		exp.AddLog(['Saved trial ' num2str(kTrial)]);
	end
end

exp.Show.Blank;
exp.Window.Flip;

exp.Window.CloseTexture('current');
exp.Window.CloseTexture('original');

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
		
		% Clear buttonbox entries in serial port
		if ~mwpi.bPractice
			exp.Input.State;
		end
		
		% stores the rank of each figure, in order of position
		% let zero indicate no rank yet
		ranking = zeros(4,1);
		
		% store stimuli in 'current' and 'original' textures
		exp.Show.Blank('window', 'original');
		exp.Show.Image(sampleStim, 'window', 'original');
		cellfun(@(im,offset) exp.Show.Image(im, offset, 'window', 'original'), ...
			cChoiceStim, cStimPos);

		% pause scheduler
		exp.Scheduler.Pause;
		
		% variables for fast rank updating
		bAdded = false;
		posAdded = 0;
		
		% rank selection loop (ends when figures have been ranked)
		while true
			% update the rankings on screen
			fStrRank = @(rank) ['<color:' colRank '>' num2str(rank) '</color>'];
			
			if bAdded
				exp.Show.Text(fStrRank(ranking(posAdded)), cNumPos{posAdded}, 'window', 'current');
				exp.Show.Texture('current');
			else
				exp.Show.Texture('original', 'window', 'current');
				ranked = find(ranking);
				arrayfun(@(pos,rank) exp.Show.Text(fStrRank(rank), cNumPos{pos}, 'window', 'current'), ...
					ranked, ranking(ranked), 'uni', false);
				exp.Show.Texture('current');
			end
			
			
			exp.Window.Flip;
			
			% wait so the log messages can print
			exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW, PTB.Now + 200);
			
			if all(ranking)
				break;
			end
						
			% now wait for them to press a button
			if mwpi.bPractice
				keyboard = exp.Input;
			else
				keyboard = exp.Input.Key;
			end
% 			[~, ~, kButton, bAbort] = exp.Input.WaitDownOnce('responselrud', ...
% 				'fabort', @() keyboard.DownOnce('abort'), ...
% 				'wait_priority', PTB.Scheduler.PRIORITY_CRITICAL);

			kButton = [];
			while true
				[bDown, ~, ~, kButton] = exp.Input.DownOnce('responselrud');
				bAbortDown = keyboard.DownOnce('abort');
				if bAbortDown
					bEnd = true;
				end
				
				if bDown
					break;
				end
				WaitSecs(0.01);
			end
			
			
			kButton = kButton(1);
			indPressed = find(kButton == arrKey);
			
			if ranking(indPressed) ~= 0
				ranking(indPressed) = 0;
				bAdded = false;
			else
				ranking(indPressed) = min(setdiff(1:4, ranking));
				bAdded = true;
				posAdded = indPressed;
			end
			
		end
		
		exp.Scheduler.Resume;
		
		res.ranking = ranking;
		res.classesInOrderOfSimilarity = res.choiceClass(res.ranking);
		% invert permutation for alternate format
		res.similarityRankingOfClass = zeros(4,1);
		res.similarityRankingOfClass(res.classesInOrderOfSimilarity) = 1:4;
		WaitSecs(0.5);
	end
end
