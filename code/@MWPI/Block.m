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
		
		fWait = {	@WaitDefault
					@WaitTest
					@WaitTest
				};
			
		res.test = struct;
		
		[res.test.tStart, res.test.tEnd, res.test.tShow, res.test.bAbort, ...
			res.test.kResponse, res.test.tResponse] = ...
			mwpi.Experiment.Show.Sequence(cX, tShow, ...
			'tunit',	'tr',		...
			'tbase',	'sequence',	...
			'fixation',	false,		...
			'fwait',	fWait		...
			);
	end
%----------------------------------------------------------------------%
	function tNow = DoFeedback(tNow, ~)
		% update correct total, reward, show feedback screen
		
		if isempty(res.bCorrect)
			res.bCorrect = false;
		end		
		
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
			dWinning = MWPI.Param('reward','rewardPerBlock');
		else
			winFeedback = 'testNo';
			strFeedback = 'No!';
			strColor = MWPI.Param('text','colNo');
			dWinning = -MWPI.Param('reward','penaltyPerBlock');
		end
		mwpi.reward = max(mwpi.reward + dWinning, MWPI.Param('reward','base'));
		
		strText = ['<color:' strColor '>' strFeedback ' (' ...
			StringMoney(dWinning,'sign',true) ')</color>\nCurrent total: ' ...
			StringMoney(mwpi.reward)];
		
		exp.Show.Text(strText,[0,MWPI.Param('text','fbOffset')], ...
			'window', winFeedback);
		
		exp.Show.Texture(winFeedback);
		exp.Window.Flip;
	end
%=====================================================================%
	function [bAbort, kResponse, tResponse] = WaitDefault(tNow,tNext)
		bAbort = false;
		kResponse = [];
		tResponse = [];
		
		timeMS = MWPI.Param('trTime') * 1000 * (tNext - tNow);
		endTimeMS = PTB.Now + timeMS;
		
		bFlushed = false;
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_LOW, endTimeMS);
	end
%--------------------------------------------------------------------%
	function [bAbort, kResponse, tResponse] = WaitTest(tNow,~)
		bAbort = false;
        
        % flush serial port once
		if ~bFlushed
            mwpi.Experiment.Serial.Clear;
            bFlushed = true;
		end
		
		bMatch = mwpi.sParam.bTestMatch(kRun,kBlock);
		
		kCorrect = cell2mat(mwpi.Experiment.Input.Get( ...
			conditional(bMatch,'match','noMatch')));
		
		% check for a response
		[bResp,~,~,kButton] = mwpi.Experiment.Input.DownOnce('response');
		
		if ~bResp
			kResponse = [];
			tResponse = [];
		else
			kResponse = kButton;
			tResponse = tNow;
			if isempty(res.bCorrect)
				res.bCorrect = all(ismember(kButton, kCorrect));
			end
		end
		
		mwpi.Experiment.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
end