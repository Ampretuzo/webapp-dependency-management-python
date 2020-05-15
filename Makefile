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

.make.venv.dev: .make.venv.pip-tools
.make.venv.dev: requirements/pip-tools.txt requirements/base.txt requirements/dev.txt
	source venv/bin/activate && pip-sync requirements/pip-tools.txt requirements/base.txt requirements/dev.txt

# Requirements:

requirements/base.txt: requirements/pip-tools.txt requirements/base.in
requirements/base.txt: | .make.venv.pip-tools
	source venv/bin/activate && pip-compile --upgrade requirements/base.in

requirements/deploy.txt: requirements/pip-tools.txt requirements/base.txt requirements/deploy.in
requirements/deploy.txt: | .make.venv.pip-tools
	source venv/bin/activate && pip-compile  --upgrade requirements/deploy.in

requirements/dev.txt: requirements/pip-tools.txt requirements/base.txt requirements/deploy.txt requirements/dev.in
requirements/dev.txt: | .make.venv.pip-tools
	source venv/bin/activate && pip-compile  --upgrade requirements/dev.in

.PHONY: requirements-upgrade
requirements-upgrade: requirements/base.txt requirements/dev.txt requirements/deploy.txt

# Entrypoints:

.PHONY: test_unit
test-unit: .make.venv.dev
	source venv/bin/activate && python -c 'import pytest; print("pytest would run as version " + pytest.__version__ + "!")'
