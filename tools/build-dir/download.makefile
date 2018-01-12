
$(DOWNLOADS):
	wget http://ftp.tudelft.nl/TUDelft/rvex/releases/4.x/4.2/toolsrc/$@.tar.bz2
	tar -xjf $@.tar.bz2
	rm $@.tar.bz2

