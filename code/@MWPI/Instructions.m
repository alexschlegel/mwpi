function Instructions(mwpi)
% mwpi.Instructions: show instructions sequence
%
% Syntax: mwpi.Instructions;
%
% Updated: 2015-11-20

% construct figures

exp = mwpi.Experiment;

sHandle.stim		= exp.Window.OpenTexture('stim');
sHandle.arrow		= exp.Window.OpenTexture('arrow');
sHandle.retention	= exp.Window.OpenTexture('retention');
sHandle.test		= exp.Window.OpenTexture('test');
sHandle.testYes		= exp.Window.OpenTexture('testYes');
sHandle.testNo		= exp.Window.OpenTexture('testNo');

% create dummy parameter struct
sParam.lClass   = 1;
sParam.rClass   = 3;
sParam.wClass   = 3;
sParam.dClass   = 1;
sParam.cue	    = 2;
sParam.vClass   = 2;
sParam.posMatch = 2;

kRun = 1;
kBlock = 1;
level = [0.05; 0.05; 0.05; 0.05];

mwpi.PrepTextures(sParam, kRun, kBlock, level);

% instruction sequence
strStimuli = 'You will see two shapes on the screen.';
exp.Show.Instructions(strStimuli, 'figure', sHandle.stim);

strArrow = ['Next, they will be replaced by an arrow.\n Remember the shape that was on ', ...
			'the side of the screen that the arrow points to.'];
exp.Show.Instructions(strArrow, 'figure', sHandle.arrow);

strRetention1 = ['For the next 5 seconds, you will see a third shape periodically ', ...
				 'shrink or grow,\n and then return to its original size.'];
exp.Show.Instructions(strRetention1, 'figure', sHandle.retention);

strRetention2 = ['Press <color:green>A</color> when it shrinks and '...
					   '<color:yellow>Y</color> when it grows.'];
fresponse = @() exp.Input.DownOnce('down', false);
strPrompt = 'Press <color:green>A</color> to continue.';
shrinkMult = MWPI.Param('fixation', 'shrinkMult');
[~,~,~,szva] = exp.Window.Get('main');
hRetentionShrink = exp.Window.OpenTexture('retShrink');
exp.Show.Texture(sHandle.retention, [], [], szva * shrinkMult, 'window', 'retShrink');
exp.Show.Instructions(strRetention2, 'figure', hRetentionShrink, ...
	'prompt', strPrompt, 'fresponse', fresponse);

strRetention3 = ['Pay attention to the shape and respond as quickly as ' ...
				 'possible when it changes.'];
exp.Show.Instructions(strRetention3, 'figure', sHandle.retention);

strTest = ['Next, your memory will be tested: you must press the button\n' ...
		   'corresponding to the shape you remembered at the beginning.'];
	   
offset = MWPI.Param('text', 'instrOffset');
exp.Show.Text('<color:blue>X</color>', [-offset, 0], 'window', 'test');
exp.Show.Text('<color:yellow>Y</color>', [0, -offset], 'window', 'test');
exp.Show.Text('<color:red>B</color>', [offset, 0], 'window', 'test');
exp.Show.Text('<color:green>A</color>', [0, offset], 'window', 'test');
exp.Show.Instructions(strTest, 'figure', sHandle.test);

strFeedback = 'Finally, you will see feedback and an indicator of your progress.';
posFeedback = [-MWPI.Param('text','horzOffset'),0];
fb = '<color:green>Yes!</color>\nTrials complete: 1/1';
exp.Show.Text(fb, posFeedback, 'window', 'testYes');
exp.Show.Instructions(strFeedback, 'figure', 'testYes');

exp.Show.Instructions('Any questions? Ask before starting!', 'blank', true, 'next', 'start');

cellfun(@(tName) exp.Window.CloseTexture(tName), fieldnames(sHandle));

end