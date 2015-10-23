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

res.bCorrect = [];
bFlushed = false;
dRewardFixation = 0;

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
	mwpi.Experiment.Sequence.Linear(cF, tSequence, ...
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
		
		tShow = [	cumsum( [	MWPI.Param('exp','block','prompt','tPrompt1')
								MWPI.Param('exp','block','prompt','tBlank1')
								MWPI.Param('exp','block','prompt','tPrompt2')
								MWPI.Param('exp','block','prompt','tBlank2')
								MWPI.Param('exp','block','prompt','cue')])
					@(tNow) deal(false, true) % make sure it ends ahead of time
				];
		
		res.prompt = struct;
		
		[res.prompt.tStart, res.prompt.tEnd, res.prompt.tShow, res.prompt.bAbort] = ...
			mwpi.Experiment.Show.Sequence(cX, tShow, ...
			'tunit',	'tr',		...
			'tbase',	'sequence', ...
			'fixation',	false		...
			);
	end
%----------------------------------------------------------------------%
	function tNow = DoRetention(tNow, tNext)
		
		% define some time functions
		tStartAbs = mwpi.Experiment.Scanner.TR;
		fTElapsed = @() mwpi.Experiment.Scanner.TR - tStartAbs;
		tDur = tNext - tNow;
		
		% show visual stimulus
		mwpi.Experiment.Show.Texture(sHandle.retention);
		mwpi.Experiment.Window.Flip;
		
		% initialize things for the fixation task
		tShowFixation = cumsum( [	MWPI.Param('fixation', 'tChange')
									MWPI.Param('fixation', 'tRespond')
								]);
		tPreMin  = MWPI.Param('fixation', 'tPreMin');
		tPreMax  = MWPI.Param('fixation', 'tPreMax');
		tRestMin = MWPI.Param('fixation', 'tRestMin');
		tRestMax = MWPI.Param('fixation', 'tRestMax');
		
		nYes = 0;
		nNo = 0;		
		
		kShrink    = mwpi.Experiment.Input.Get('shrink');
		kGrow	   = mwpi.Experiment.Input.Get('grow');
		shrinkMult = MWPI.Param('fixation', 'shrinkMult');
		growMult   = MWPI.Param('fixation', 'growMult');
		[~,~,~,szva] = mwpi.Experiment.Window.Get('main');
		
		tTaskStart = randBetween(tPreMin, tPreMax);
		sched = mwpi.Experiment.Scheduler;
		
		res.retention = struct;
		
		tTask = MWPI.Param('fixation', 'tTask'); % time required for one fixation task

		while tTaskStart < tDur - tTask
			
			% wait for a variable rest period
			while fTElapsed() < tTaskStart
				sched.Wait(sched.PRIORITY_CRITICAL, PTB.Now + 100);
			end
			
			% set up fixation task
			bGrow = randFrom([true, false]);
			kCorrect = conditional(bGrow, kGrow, kShrink);
			multiplier = conditional(bGrow, growMult, shrinkMult);			
			
			cXFixation = {	{'Texture', sHandle.retention, [], [], multiplier * szva}
							sHandle.retention
						  };
			 
			fWaitFixation = repmat({@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)}, 2,1);
			 
			bFlushed = false;
			
			% do fixation task
			[resOne.tStart, resOne.tEnd, resOne.tShow, resOne.bAbort, ...
				resOne.bCorrect, resOne.kResponse, resOne.tResponse] = ...
				mwpi.Experiment.Show.Sequence(cXFixation, tShowFixation, ...
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
		
		% calculate total change in reward
		fRewardFixation = MWPI.Param('reward','fFixation');
		dRewardFixation = fRewardFixation(nYes, nNo);
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

		kCorrect = cell2mat(mwpi.Experiment.Input.Get( ...
			conditional(bMatch,'match','noMatch')));

		fWait = {	@WaitDefault
					@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)
					@(tNow, tNext) WaitTest(kCorrect, tNow, tNext)
				};
			
		res.test = struct;
		
		[res.test.tStart, res.test.tEnd, res.test.tShow, res.test.bAbort, ...
			res.test.bCorrect, res.test.kResponse, res.test.tResponse] = ...
			mwpi.Experiment.Show.Sequence(cX, tShow, ...
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
		strCorrect  = conditional(bCorrect,'y','n');
		strTally    = [num2str(mwpi.nCorrect) '/' num2str(kBlock)];
		
		exp.AddLog(['feedback (' strCorrect ', ' strTally ')']);
		
		% show feedback texture and updated reward
		if bCorrect
			winFeedback = 'testYes';
			strFeedback = 'Yes!';
			strColor = MWPI.Param('text','colYes');
			dReward = MWPI.Param('reward','rewardPerBlock');
		else
			winFeedback = 'testNo';
			strFeedback = 'No!';
			strColor = MWPI.Param('text','colNo');
			dReward = -MWPI.Param('reward','penaltyPerBlock');
		end
		
		% take fixation task into account
		res.dWinning = dReward + dRewardFixation;
		res.rewardPost = max(mwpi.reward + dReward, MWPI.Param('reward','base'));		
		mwpi.reward = res.rewardPost;
		
		strText = ['<color:' strColor '>' strFeedback ' (' ...
			StringMoney(dReward,'sign',true) ')</color>\nCurrent total: ' ...
			StringMoney(mwpi.reward)];
		
		exp.Show.Text(strText,[0,MWPI.Param('text','fbOffset')], ...
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
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW, endTimeMS);
	end
%--------------------------------------------------------------------%
	function [bAbort, bCorrect, kResponse, tResponse] = WaitTest(kCorrect, tNow,~)
		bAbort = false;
        
		persistent bResponse; % whether a response has been recorded
		
        % flush serial port once (and reset bResponse)
		if ~bFlushed
            mwpi.Experiment.Serial.Clear;
			bResponse = false;
            bFlushed = true;
		end
		
		kResponse = [];
		tResponse = [];
		bCorrect = [];
		
		% check for a response
		if ~bResponse
			[bRespNow,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');

			if bRespNow
				kResponse = kButton;
				tResponse = tNow;
				bCorrect = all(ismember(kButton, kCorrect));
				bResponse = true;				
			end
		end
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
end