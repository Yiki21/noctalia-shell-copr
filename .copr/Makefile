SRPM_FILE := noctalia-shell-$(shell grep Version noctalia-shell.spec | awk '{print $$2}').src.rpm

srpm:
	cp ../noctalia-shell-*.tar.gz .
	rpkg srpm --spec noctalia-shell.spec --outdir .
