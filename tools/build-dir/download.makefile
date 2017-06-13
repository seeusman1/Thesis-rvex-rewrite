
# If you're on the development team, you have access to the code repositories.
# otherwise, use the release tarballs from the TUDelft FTP server
USE_BITBUCKET=FALSE
LOCAL_TEST=TRUE
LOCAL_TEST_LOC=/shares/group/ce-rvex/ARC2017/rvex-workshop/tools2

$(DOWNLOADS):
ifeq ($(USE_BITBUCKET), TRUE)
	git clone https://bitbucket.org/rvex/$@.git
else
ifeq ($(LOCAL_TEST), TRUE)
	cp $(LOCAL_TEST_LOC)/$@.tar.bz2 ./
else
	wget http://ftp.tudelft.nl/TUDelft/rvex/$@.tar.bz2
endif
	tar -xjf $@.tar.bz2 
	rm $@.tar.bz2
endif

