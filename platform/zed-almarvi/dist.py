
import os
import tarfile

with open('ignored', 'r') as f:
	ignored = f.readlines()
ignored = set([x.strip() for x in ignored])

def find_files(directory, ignored):
	
	# List files in this directory.
	entries = os.listdir(directory)
	
	# Don't include downloaded git repositories.
	if '.git' in entries:
		return []
	
	files = []
	for entry in entries:
		fname = os.path.join(directory, entry)
		
		# Ignore files listed as ignored by git, except for the
		# almarvi/rvex/rtl/rvex directory, which contains the rvex sources.
		if fname in ignored and not fname.startswith('almarvi/rvex/rtl/rvex'):
			ignored.discard(fname)
			continue
		if os.path.isdir(fname):
			files += find_files(fname, ignored)
		else:
			files.append(fname)
	return files

files = find_files('almarvi', ignored)

with tarfile.open('almarvi.tar.gz', mode='w:gz') as tgz:
	for file in files:
		tgz.add(file)

