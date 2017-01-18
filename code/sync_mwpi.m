function sync_mwpi(direction, remoteHost)
% sync_mwpi: Synchronize mwpi data files between helmholtz and kohler. 
% Must be run on a tse lab computer. If run on a computer other than 
% helmholtz or kohler, treats helmholtz as the local computer if it is
% mounted at /mnt/tsestudies/helmholtz.
%
% Syntax: sync_mwpi(direction)
%
% Input: direction: either 'push' or 'pull', the direction to sync.
%        remoteHost: the hostname of the computer to sync to or from.
%
% ** 1/13/17 update: "kohler" is now "golgi" (Ethan's laptop)
%                    now syncs between local copies on koffka, golgi and helmholtz.
%                    now must be run on one of these 3 computers.

local = '/home/tselab/studies/mwpi/data';
assert(isdir(local),'Local data folder does not exist.');

switch direction
	case 'push'
		bPush = true;
	case 'pull'
		bPush = false;
	otherwise
		error('Syntax: sync_mwpi(direction); direction must be ''push'' or ''pull'''); 
end

% identify hostname of this computer
[~,hn] = system('hostname');
assert(~strcmp(hn,sprintf('%s\n',remoteHost)), 'Remote host must be different from local host.');

remote = sprintf('tselab@%s.dartmouth.edu:%s', remoteHost, local);

% do the sync
cmdFormat = 'LD_LIBRARY_PATH= rsync -dPzt %s/ %s';

if bPush
	system(sprintf(cmdFormat, local, remote));
else
	system(sprintf(cmdFormat, remote, local));
end

end
