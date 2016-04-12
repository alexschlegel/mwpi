function sync_mwpi(direction)
% sync_mwpi: Synchronize mwpi data files between helmholtz and kohler. 
% Must be run on a tse lab computer. If run on a computer other than 
% helmholtz or kohler, treats helmholtz as the local computer if it is
% mounted at /mnt/tsestudies/helmholtz.
%
% Syntax: sync_mwpi(direction)
%
% Input: direction: either 'push' or 'pull', the direction to sync.

HELMHOLTZ_DIR = '/mnt/tsestorage/helmholtz/mwpi/data';
KOHLER_DIR = '/media/windows/studies/mwpi/data';

switch direction
	case 'push'
		bPush = true;
	case 'pull'
		bPush = false;
	otherwise
		error('Syntax: sync_mwpi(direction); direction must be ''push'' or ''pull'''); 
end

% are we on kohler?
[~,hn] = system('hostname');

if strcmp(hn, 'kohler')
	local = KOHLER_DIR;
	remote = ['tselab@helmholtz.dartmouth.edu:' HELMHOLTZ_DIR];
elseif isdir(HELMHOLTZ_DIR)
	local = HELMHOLTZ_DIR;
	remote = ['tselab@kohler.dartmouth.edu:' KOHLER_DIR];
else
	error('sync_mwpi must be run on a Tse Lab computer.');
end

% do the sync
cmdFormat = 'rsync -dPz %s/ %s';

if bPush
	system(sprintf(cmdFormat, local, remote));
else
	system(sprintf(cmdFormat, remote, local));
end

end