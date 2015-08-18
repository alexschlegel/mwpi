function res = Block(mwpi, kRun, kBlock, sHandle)
% Block - do one MWPI block.
%
% Syntax: mwpi.Block(kRun, kBlock, sHandle)
%
% In:
%   kRun - the run number
%   kBlock - the block number
%   sHandle - a struct of handles to textures that should be prepared before this function
%             is called. Fields must include at least "prompt", "task", and "probe".
%
% Updated: 2015-08-18