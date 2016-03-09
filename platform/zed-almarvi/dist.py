
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
		
		# Ignore files listed as ignored by git, except for some stuff which should
		# be in the almarvi repo but not in the rvex-rewrite one.
		if (
			fname in ignored
			and not fname.startswith('almaif/impl/rvex/rtl/rvex')
      and not fname.startswith('almaif/impl/rvex/sw')
			and not fname.startswith('almaif/utils/rvd')
		):
			ignored.discard(fname)
			continue
		if os.path.isdir(fname):
			files += find_files(fname, ignored)
		else:
			files.append(fname)
	return files

files = find_files('almaif', ignored)

with tarfile.open('almaif.tar.gz', mode='w:gz') as tgz:
	for file in files:
		tgz.add(file)

