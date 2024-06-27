# this makefile is for convenience
# to start tests manually
# make test DEVICE_IP=10.11.4.000

DEVICE_IP?=10.11.4.228

build:
	rm -rf *.zip *.tar *.tar.gz
	# git archive --format=tar --output=compose-tests.tar master
	tar cvf compose-tests.tar apps test_docker.py

CMD:=$(CMD)'echo  Starting test on device $(DEVICE_IP);
CMD:=$(CMD) date;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo  Clean and Setup Working Directory;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) cd /tmp; rm -vrf compose-tests docker_test_result;
CMD:=$(CMD) mkdir compose-tests;
CMD:=$(CMD) cd compose-tests;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo  Extract TAR;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo  PWD: $$(pwd);
CMD:=$(CMD) tar -vxf ../compose-tests.tar;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo             RUN TESTS;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo  PWD: $$(pwd);
CMD:=$(CMD) tree;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo 'TEST CMD: python3 -m unittest -v';
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) python3 -m unittest -v;
# CMD:=$(CMD) false;
CMD:=$(CMD) echo -n $$? > /tmp/docker_test_result;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) echo  Clean-Up;
CMD:=$(CMD) echo  -----------------------------------;
CMD:=$(CMD) cd ..;
CMD:=$(CMD) rm -vrf compose-tests compose-tests.tar;
CMD:=$(CMD) exit $$(cat docker_test_result);'

echo:
	echo $(CMD)

test: build
	scp compose-tests.tar root@$(DEVICE_IP):/tmp/compose-tests.tar
	@echo  Connecting to root@$(DEVICE_IP)
	@echo  ----------------------------------
	@ssh root@$(DEVICE_IP) $(CMD)


.PHONY: build

