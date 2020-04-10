.DELETE_ON_ERROR:
SHELL := /bin/bash

.PHONY:
clean:
	rm -f .make.*
	rm -rf venv*

# Environment:

venv/bin/activate:
	/usr/bin/python3.6 --version
	virtualenv --python=/usr/bin/python3.6 venv

.make.venv: venv/bin/activate
	touch .make.venv

.make.venv.pip-tools: .make.venv requirements/pip-tools.txt
	source venv/bin/activate && pip install -r requirements/pip-tools.txt
	touch .make.venv.pip-tools

# Requirements:

requirements/base.txt: .make.venv.pip-tools requirements/pip-tools.txt
requirements/base.txt: requirements/base.in
	source venv/bin/activate && pip-compile requirements/base.in

requirements/deploy.txt: .make.venv.pip-tools requirements/pip-tools.txt
requirements/deploy.txt: requirements/base.txt requirements/dev.in
	source venv/bin/activate && pip-compile requirements/deploy.in

requirements/dev.txt: .make.venv.pip-tools requirements/pip-tools.txt
requirements/dev.txt: requirements/base.txt requirements/deploy.txt requirements/dev.in
	source venv/bin/activate && pip-compile requirements/dev.in

.PHONY: requirements
requirements: requirements/base.txt requirements/dev.txt requirements/deploy.txt
