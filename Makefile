GROWBOT_USER := growbot
GROWBOT_GROUP := growbot
GROWBOT_HOME := /opt/growbot
GROWBOT_SERVICE := /etc/systemd/system/growbot.service

.PHONY: install update clean

install: update
	useradd --system --user-group --create-home -K UMASK=0022 --home $(GROWBOT_HOME) $(GROWBOT_USER)
	systemctl -f enable growbot.service;

update:
	install -m 0755 growbot $(GROWBOT_HOME)
	install -m 0644 growbot.service $(GROWBOT_SERVICE);
	cp -R public $(GROWBOT_HOME)
	cp -R templates $(GROWBOT_HOME)

clean:
	systemctl -f disable growbot.service;
	rm -R $(GROWBOT_HOME)