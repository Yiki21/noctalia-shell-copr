SRPM_FILE := noctalia-shell-$(shell grep Version noctalia-shell.spec | awk '{print $$2}').src.rpm

srpm:
	rpmbuild -bs noctalia-shell.spec --define "_sourcedir $(PWD)" --define "_srcrpmdir $(PWD)"
