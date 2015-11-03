function res = Block(mwpi, kRun, kBlock, sHandle)
% Block - do one MWPI block.
%
% Syntax: mwpi.Block(kRun, kBlock, sHandle)
%
% In:
%   kRun - the run number
%   kBlock - the block number
%   sHandle - a struct of handles to textures that should be prepared before this function
%             is called. See PrepTextures for descriptions.
%
% Updated: 2015-08-18

exp = mwpi.Experiment;

res.bCorrect = [];
bFlushed = false;
% for fixation tasks:
nYes = 0;
nNo  = 0;

% set up sequence

cF = {@DoPrompt
	  @DoRetention
	  @DoTest
	  @DoFeedback
	 };

 
tSequence = cumsum([	MWPI.Param('exp','block','prompt','time')
						MWPI.Param('exp','block','retention','time')
						MWPI.Param('exp','block','test','time')
						MWPI.Param('exp','block','feedback','time');
					]);
				

[res.tStart, res.tEnd, res.tSequence, res.bAbort] = ...
	exp.Sequence.Linear(cF, tSequence, ...
	'tbase',	'sequence', ...
	'tunit',	'tr'		...
	);

%----------------------------------------------------------------------%
	function tNow = DoPrompt(tNow, ~)
		
		cX = {	sHandle.prompt1
				{'Blank','fixation',false}
				sHandle.prompt2
				{'Blank','fixation',false}
				sHandle.cue
				{'Blank','fixation',false}
			};
		
		tShow = [	num2cell(cumsum( [	MWPI.Param('exp','block','prompt','tPrompt1')
										MWPI.Param('exp','block','prompt','tBlank1')
										MWPI.Param('exp','block','prompt','tPrompt2')
										MWPI.Param('exp','block','prompt','tBlank2')
										MWPI.Param('exp','block','prompt','tCue')]))
					{@(tNow) deal(false, true)} % make sure it ends ahead of time
				];
		
		res.prompt = struct;
		
		[res.prompt.tStart, res.prompt.tEnd, res.prompt.tShow, res.prompt.bAbort] = ...
			exp.Show.Sequence(cX, tShow, ...
			'tunit',	'tr',		...
			'tbase',	'sequence', ...
			'fixation',	false		...
			);
	end
%----------------------------------------------------------------------%
	function tNow = DoRetention(tNow, tNext)
		
		% define some time functions
		tStartAbs = exp.Scanner.TR;
		fTElapsed = @() exp.Scanner.TR - tStartAbs;
		tDur = tNext - tNow;
		
		% show visual stimulus
		exp.Show.Texture(sHandle.retention);
		exp.Window.Flip;
		
		% initialize things for the fixation task
		tShowFixation = cumsum( [	MWPI.Param('fixation', 'tChange')
									MWPI.Param('fixation', 'tRespond')
								]);
		tPreMin  = MWPI.Param('fixation', 'tPreMin');
		tPreMax  = MWPI.Param('fixation', 'tPreMax');
		tRestMin = MWPI.Param('fixation', 'tRestMin');
		tRestMax = MWPI.Param('fixation', 'tRestMax');
				
		kShrink    = exp.Input.Get('shrink');
		kGrow	   = exp.Input.Get('grow');
		shrinkMult = MWPI.Param('fixation', 'shrinkMult');
		growMult   = MWPI.Param('fixation', 'growMult');
		[~,~,~,szva] = exp.Window.Get('main');
		
		tTaskStart = randBetween(tPreMin, tPreMax);
		sched = exp.Scheduler;
		
		res.retention = [];
		
		tTask = MWPI.Param('fixation', 'tTask'); % time required for one fixation task

		while tTaskStart < tDur - tTask
			
			% wait for a variable rest period
			while fTElapsed() < tTaskStart
				sched.Wait(sched.PRIORITY_CRITICAL, PTB.Now + 100);
			end
			
			% set up fixation task
			bGrow = randFrom([true, false]);
			kCorrect = cell2mat(conditional(bGrow, kGrow, kShrink));
			multiplier = conditional(bGrow, growMult, shrinkMult);			
			
			cXFixation = {	{'Texture', sHandle.retention, [], [], multiplier * szva}
							sHandle.retention
						  };
			 
			fWaitFixation = repmat({@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)}, 2,1);
			 
			bFlushed = false;
			
			% do fixation task
			[resOne.tStart, resOne.tEnd, resOne.tShow, resOne.bAbort, ...
				resOne.bCorrect, resOne.kResponse, resOne.tResponse] = ...
				exp.Show.Sequence(cXFixation, tShowFixation, ...
				'tunit',	'tr', ...
				'tbase',	'sequence', ...
				'fixation',	false, ...
				'fwait',	fWaitFixation ...
				);
			
			% record results
			if isempty(resOne.bCorrect) || ~resOne.bCorrect{1}
				nNo = nNo + 1;
			else
				nYes = nYes + 1;
			end
			
			if isempty(res.retention)
				res.retention = resOne;
			else
				res.retention(end+1) = resOne;
			end
			
			tTaskStart = tTaskStart + tTask + randBetween(tRestMin, tRestMax);
		end
		
		% show a log message
		pctCorrect = round(100 * (nYes / (nYes + nNo)));
		exp.AddLog(['fixations correct: ' num2str(nYes) '/' num2str(nYes + nNo) ...
			' (' num2str(pctCorrect) '%)']);
	end
%----------------------------------------------------------------------%
	function tNow = DoTest(tNow, ~)
		
		cX = {	{'Blank','fixation',false}
				sHandle.test
				{'Blank','fixation',false}
			};
		
		tShow = cumsum([	MWPI.Param('exp','block','test','tBlankPre')
							MWPI.Param('exp','block','test','tTest')
							MWPI.Param('exp','block','test','tBlankPost')
						]);
					
		bMatch = mwpi.sParam.bTestMatch(kRun,kBlock);

		kCorrect = cell2mat(exp.Input.Get( ...
			conditional(bMatch,'match','noMatch')));

		fWait = {	@WaitDefault
					@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)
					@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)
				};
			
		res.test = struct;
		
		[res.test.tStart, res.test.tEnd, res.test.tShow, res.test.bAbort, ...
			res.test.bCorrect, res.test.kResponse, res.test.tResponse] = ...
			exp.Show.Sequence(cX, tShow, ...
			'tunit',	'tr',		...
			'tbase',	'sequence',	...
			'fixation',	false,		...
			'fwait',	fWait		...
			);
		
		if numel(res.test.bCorrect) > 0
			res.bCorrect = res.test.bCorrect{1};
		else
			res.bCorrect = false; % no response = wrong
		end
		
	end
%----------------------------------------------------------------------%
	function tNow = DoFeedback(tNow, ~)
		% update correct total, reward, show feedback screen	
		
		% add a log message
		mwpi.nCorrect    = mwpi.nCorrect + res.bCorrect;
		charCorrect  = conditional(res.bCorrect,'y','n');
		strTally    = [num2str(mwpi.nCorrect) '/' num2str(kBlock)];
		
		exp.AddLog(['feedback (' charCorrect ', ' strTally ')']);
		
		% show feedback texture and updated reward
		strColYes = MWPI.Param('text','colYes');
		strColNo  = MWPI.Param('text','colNo');
		if res.bCorrect
			winFeedback = 'testYes';
			strCorrect = 'Yes!';
			strColor = strColYes;
			dRewardTest = MWPI.Param('reward','rewardPerBlock');
		else
			winFeedback = 'testNo';
			strCorrect = 'No!';
			strColor = strColNo;
			dRewardTest = -MWPI.Param('reward','penaltyPerBlock');
		end
		
		% take fixation task into account				
		fRewardFixation = MWPI.Param('reward','fFixation');
		dRewardFixation = fRewardFixation(nYes, nNo);		
		
		res.dReward = dRewardTest + dRewardFixation;
		res.rewardPost = max(mwpi.reward + res.dReward, MWPI.Param('reward','base'));		
		mwpi.reward = res.rewardPost;
		
		if dRewardFixation ~= 0
			strFixationFeedback = [num2str(nNo) plural(nNo,' cue{,s} missed <color:')...
				strColNo '>(' StringMoney(dRewardFixation,'sign',true) ')</color>\n'];
		else
			strFixationFeedback = '';
		end
		
		strFeedback = ['<color:' strColor '>' strCorrect ' (' ...
			StringMoney(dRewardTest,'sign',true) ')</color>\n' strFixationFeedback ...
			'Current total: ' StringMoney(mwpi.reward)];
		
		exp.Show.Text(strFeedback,[0,MWPI.Param('text','fbOffset')], ...
			'window', winFeedback);
		
		exp.Show.Texture(winFeedback);
		exp.Window.Flip;
	end
%=====================================================================%
	function [bAbort, bCorrect, kResponse, tResponse] = WaitDefault(tNow,tNext)
		bAbort = false;
		bCorrect = [];
		kResponse = [];
		tResponse = [];
		
		timeMS = MWPI.Param('trTime') * 1000 * (tNext - tNow);
		endTimeMS = PTB.Now + timeMS;
		
		bFlushed = false;
		
		exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW, endTimeMS);
	end
%--------------------------------------------------------------------%
	function [bAbort, bCorrect, kResponse, tResponse] = WaitTest(kCorrect, tNow,~)
		bAbort = false;
        
		persistent bResponse; % whether a response has been recorded
		
        % flush serial port once (and reset bResponse)
		if ~bFlushed
            exp.Serial.Clear;
			bResponse = false;
            bFlushed = true;
		end
		
		kResponse = [];
		tResponse = [];
		bCorrect = [];
		
		% check for a response
		if ~bResponse
			[bRespNow,~,~,kButton] = exp.Input.DownOnce('response');

			if bRespNow
				kResponse = kButton;
				tResponse = tNow;
				bCorrect = all(ismember(kButton, kCorrect));
				bResponse = true;				
			end
		end
		
		exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
end