# Python web application dependency management using `pip-tools`, `virtualenv` and `GNU Make`
I have used `pip-tools` and `virtualenv` with great success in the past.  
These tools are simple and reliable. And flexible, as a corollary of their simplicity.  
In the last project I brought everything under the same roof using a good old `Makefile`.  
This writeup is supposed to document my approach with these tools.

I'll start with `Makefile` right away, newcomers to `pip-tools` or `virtualenv` are encouraged to start from the later corresponding sections and come back after they've familiarized themselves with these tools.

## `Makefile` workflow

```Makefile
.DELETE_ON_ERROR:
SHELL := /bin/bash

.PHONY: clean
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
	@echo 'NOTE: Run `touch requirements/{base,deploy,dev}.txt` to snooze dependency upgrade'
	source venv/bin/activate && pip-sync requirements/pip-tools.txt requirements/base.txt requirements/dev.txt
	touch .make.venv.dev

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

.PHONY: test-unit
test-unit: .make.venv.dev
	source venv/bin/activate && python -c 'import pytest; print("pytest would run as version " + pytest.__version__ + "!")'

```

Above `Makefile` is very minimal and I actually use it as a template when bootstrapping new projects.  
It provides two "entry points": `make requirements-upgrade` and `make test-unit`.  
The former upgrades all of our dependencies, the latter creates an actual Python development environment and imports `pytest` to simulate testing. These two are enough to get the gist of how `make` glues `pip-tools` and `virtualenv` together - other targets could then be easily added.  

Both "compiled" and "source" requirement files are tucked away in the `requirements` directory. Otherwise, we would clutter project root since there are 8 of them in total.

`pip-compile` lends itself nicely to `make` since `GNU Make` is tailored for artifact-compilation style of workflows. `pip-compile` is pip dash _compile_, after all, right?  
Hence, `requirements/*.txt` targets and their prerequisites map nicely to how `requirements/*.in` files really depend on each other.  
For example, `requirements/deploy.in` is constrained by `requirements/pip-tools.txt` and `requirements/base.txt` and therefore `requirements/deploy.txt` target has both of those files as prerequisites. If we edit `requirements/base.in` and `make requirements-upgrade` all of the requirement files will get upgraded, since they all depend on the base one. If we edit just the `requirements/dev.in` file, only `requirements/dev.txt` will get compiled, since nothing else depends on that.


## The tools
I'd like to start with a quick review of the tools that we're using.


### `virtualenv`
Using `virtualenv` is very simple:
```bash
virtualenv venv --python=/usr/bin/python3.8
source venv/bin/activate.fish # ".fish" for fish shell
```
This essentially just:
1. copies specified Python executable to `venv` directory and
1. makes it the highest priority Python executable in shell by modifying `PATH`.  
`type python` will output `python is <current_directory>/venv/bin/python`.  
`type pip` will output `python is <current_directory>/venv/bin/pip`.  
`python --version` will output `Python 3.8.x`.

For all intents and purposes, that's all there's to it - we're getting a fresh, isolated Python environment.  
Note that I'm explicit about the Python version - as for libraries, we must lock the language version.  


### `pip-tools`

`pip-tools` provides us with two commands: `pip-compile` and `pip-sync`.  

#### `pip-compile`

Consider contrived requirements for the project: `requests_oauthlib` version higher than `1.1` and `requests` also higher than `1.1`.  
Also, I want to constrain both libraries to major version `1`, that is, `<2`. In general, ideally, every project should have major versions of its dependencies pinned exactly, and minor (feature) versions constrained with _greater than_ inequality.  
That's particularly true for interpreted languages. If the libraries are silently upgraded to newer major versions, some function calls will probably succeed, some will succeed and maybe cause unwanted results and some will straight up fail. If we didn't discover all the failures during CI testing, we're going to have to troubleshoot deployed application.  
Conveniently, `pip` already has special "compatible release" requirement specifier just for that purpose: `~=`.  
So, let's specify our requirements in familiar pip-requirements format:
```console
$ echo 'requests_oauthlib~=1.1
> requests~=1.1' > requirements.quickstart.in
```
And then run `pip-compile 'requirements.quickstart.in'`, observing the output.  
<details>
<summary>See command output.</summary>

```
Could not find a version that matches requests>=2.0.0,~=1.1 (from -r requirements.quickstart.in (line 2))
Tried: 0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4, 0.3.0, 0.3.1, 0.3.2, 0.3.3, 0.3.4, 0.4.0, 0.4.1, 0.5.0, 0.5.1, 0.6.0, 0.6.1, 0.6.2, 0.6.3, 0.6.4, 0.6.5, 0.6.6, 0.7.0, 0.7.1, 0.7.2, 0.7.3, 0.7.4, 0.7.5, 0.7.6, 0.8.0, 0.8.1, 0.8.2, 0.8.3, 0.8.4, 0.8.5, 0.8.6, 0.8.7, 0.8.8, 0.8.9, 0.9.0, 0.9.1, 0.9.2, 0.9.3, 0.10.0, 0.10.1, 0.10.2, 0.10.3, 0.10.4, 0.10.6, 0.10.7, 0.10.8, 0.11.1, 0.11.2, 0.12.0, 0.12.1, 0.13.0, 0.13.1, 0.13.2, 0.13.3, 0.13.4, 0.13.5, 0.13.6, 0.13.7, 0.13.8, 0.13.9, 0.14.0, 0.14.1, 0.14.2, 1.0.0, 1.0.1, 1.0.2, 1.0.3, 1.0.4, 1.1.0, 1.2.0, 1.2.1, 1.2.2, 1.2.3, 2.0.0, 2.0.0, 2.0.1, 2.0.1, 2.1.0, 2.1.0, 2.2.0, 2.2.0, 2.2.1, 2.2.1, 2.3.0, 2.3.0, 2.4.0, 2.4.0, 2.4.1, 2.4.1, 2.4.2, 2.4.2, 2.4.3, 2.4.3, 2.5.0, 2.5.0, 2.5.1, 2.5.1, 2.5.2, 2.5.2, 2.5.3, 2.5.3, 2.6.0, 2.6.0, 2.6.1, 2.6.1, 2.6.2, 2.6.2, 2.7.0, 2.7.0, 2.8.0, 2.8.0, 2.8.1, 2.8.1, 2.9.0, 2.9.0, 2.9.1, 2.9.1, 2.9.2, 2.9.2, 2.10.0, 2.10.0, 2.11.0, 2.11.0, 2.11.1, 2.11.1, 2.12.0, 2.12.0, 2.12.1, 2.12.1, 2.12.2, 2.12.2, 2.12.3, 2.12.3, 2.12.4, 2.12.4, 2.12.5, 2.12.5, 2.13.0, 2.13.0, 2.14.0, 2.14.0, 2.14.1, 2.14.1, 2.14.2, 2.14.2, 2.15.1, 2.15.1, 2.16.0, 2.16.0, 2.16.1, 2.16.1, 2.16.2, 2.16.2, 2.16.3, 2.16.3, 2.16.4, 2.16.4, 2.16.5, 2.16.5, 2.17.0, 2.17.0, 2.17.1, 2.17.1, 2.17.2, 2.17.2, 2.17.3, 2.17.3, 2.18.0, 2.18.0, 2.18.1, 2.18.1, 2.18.2, 2.18.2, 2.18.3, 2.18.3, 2.18.4, 2.18.4, 2.19.0, 2.19.0, 2.19.1, 2.19.1, 2.20.0, 2.20.0, 2.20.1, 2.20.1, 2.21.0, 2.21.0, 2.22.0, 2.22.0, 2.23.0, 2.23.0
There are incompatible versions in the resolved dependencies:
  requests~=1.1 (from -r requirements.quickstart.in (line 2))
  requests>=2.0.0 (from requests-oauthlib==1.3.0->-r requirements.quickstart.in (line 1))
```
</details>

That's why you need `pip-tools`, right there.  
If you were to install those requirements via `pip install -r requiremets.quickstart.in`, it would complete successfuly, giving us some arbitrary `requests` version. (Note that `pip` does check installed versions for consistency _after_ the fact and issues warnings accordingly.)  
If `pip` had a dependency resolver, we could just take our requirements file, run `pip install -r requiremets.quickstart.in` against a _fresh_, newly minted, clean virtual environment and `pip freeze > requirements.quickstart.txt` to lock dependency versions. Then we could use `pip install -r requirements.quickstart.txt` on, again, clean virtual environment to reproduce pinned environment. (Note that `--no-deps` wouldn't be necessary during installation if `pip` had a dependency resolver.)  
Now, let's say we took action and upgraded our code to support `requests` version 2. Imagine also, that `requests` developers messed up and our tests fail for any `requests` versions higher than `2.11`. (That probably won't happen to a widely used library such as `requests`, but the world is not ideal and some developers either don't respect semver, or just make mistakes. It's another question whether we should depend on such libraries.)  
We upgrade our requirements and pin it:
```console
$ echo 'requests_oauthlib~=1.1
> requests~=2.0,<=2.11' > requirements.quickstart_2.in
```
<details>
<summary>The command completes succesfuly.</summary>

```
#
# This file is autogenerated by pip-compile
# To update, run:
#
#    pip-compile requirements.quickstart_2.in
#
oauthlib==3.1.0           # via requests-oauthlib
requests-oauthlib==1.3.0  # via -r requirements.quickstart_2.in
requests==2.11.0          # via -r requirements.quickstart_2.in, requests-oauthlib
```
</details>

Note that `requests` was pinned to `2.11.0` version, which is not the latest version - to satisfy our `<=2.11` constraint.  

It is very important to keep in mind that `pip-compile` must run _in_ the same environment as we intend to deploy our app to, so that it can look at dependencies with the "same eyes" as prod environment, so to speak. By the "same environment" we basically mean Python version and platform (TODO: `setup.py` woes in appendix), as described in PEP425.  
To illustrate that, let's create a very simple `.in` file with single `tensorflow` dependency:
```console
$ echo 'tensorflow~=2.0' > requirements.quickstart_tf.in
```
Running `pip-compile requirements.quickstart_tf.in` yields an error, even though `tensorflow` version 2 is available on PYPI:
<details>
<summary>Stderr.</summary>

```
Could not find a version that matches tensorflow~=2.0 (from -r requirements.quickstart_tf.in (line 1))
Skipped pre-versions: 2.2.0rc1, 2.2.0rc2
There are incompatible versions in the resolved dependencies:
```
</details>

To understand why that is, we can look at `tensorflow` page on PYPI. In the `2.1.0` downloads section we see a bunch of binary distributions, i.e. `wheels`. (Note that tensorflow doesn't even provide source distribution.) And none of them are compiled to support Python 3.8, the environment version we've been using from the start.  
By using the right environment (e.g Python 3.6 virtual environment), we can lock our application dependencies:
```bash
virtualenv venv36 --python=/usr/bin/python3.6
source venv36/bin/activate.fish
pip install pip-tools
pip-compile requirements.quickstart_tf.in
```
Compilation completes successfuly and produces `requirements.quickstart_tf.txt`:
<details>
<summary>(Now, that's a <strong>lot</strong> of dependencies.)</summary>

```
#
# This file is autogenerated by pip-compile
# To update, run:
#
#    pip-compile requirements.quickstart_tf.in
#
absl-py==0.9.0            # via tensorboard, tensorflow
astor==0.8.1              # via tensorflow
cachetools==4.1.0         # via google-auth
certifi==2020.4.5.1       # via requests
chardet==3.0.4            # via requests
gast==0.2.2               # via tensorflow
google-auth-oauthlib==0.4.1  # via tensorboard
google-auth==1.13.1       # via google-auth-oauthlib, tensorboard
google-pasta==0.2.0       # via tensorflow
grpcio==1.28.1            # via tensorboard, tensorflow
h5py==2.10.0              # via keras-applications
idna==2.9                 # via requests
keras-applications==1.0.8  # via tensorflow
keras-preprocessing==1.1.0  # via tensorflow
markdown==3.2.1           # via tensorboard
numpy==1.18.2             # via h5py, keras-applications, keras-preprocessing, opt-einsum, scipy, tensorboard, tensorflow
oauthlib==3.1.0           # via requests-oauthlib
opt-einsum==3.2.0         # via tensorflow
protobuf==3.11.3          # via tensorboard, tensorflow
pyasn1-modules==0.2.8     # via google-auth
pyasn1==0.4.8             # via pyasn1-modules, rsa
requests-oauthlib==1.3.0  # via google-auth-oauthlib
requests==2.23.0          # via requests-oauthlib, tensorboard
rsa==4.0                  # via google-auth
scipy==1.4.1              # via tensorflow
six==1.14.0               # via absl-py, google-auth, google-pasta, grpcio, h5py, keras-preprocessing, protobuf, tensorboard, tensorflow
tensorboard==2.1.1        # via tensorflow
tensorflow-estimator==2.1.0  # via tensorflow
tensorflow==2.1.0         # via -r requirements.quickstart_tf.in
termcolor==1.1.0          # via tensorflow
urllib3==1.25.8           # via requests
werkzeug==1.0.1           # via tensorboard
wheel==0.34.2             # via tensorboard, tensorflow
wrapt==1.12.1             # via tensorflow

# The following packages are considered to be unsafe in a requirements file:
# setuptools
```
</details>

In short, `.txt` files are a list of dependencies for the _specific_ Python and platform combination they were compiled in, from respective `.in` file. Hence, in case we'd like to support e.g. multiple platforms - we must compile `.in` files on those platforms separately. (Although, it's not entirely clear why a web application should support multiple environments.)  
In practice though, since the libraries are designed to support a wide range on environments, it is very likely that your `.txt` file will work cross-platform, e.g. on Linux and macOS. (Bar some specialized exceptions like `tensorflow-gpu`, which, like `tensorflow` itself, doesn't provide source `sdist` distribution or macOS `wheel`, for whatever reasons.)  

All non-trivial applications need to specify dependencies for at least two environments: production and development. Therefore we need to be able to compose `.in` and `.txt` files. We have two ways of requirement file composition: `-r` and `-c`.  
Note that none of them are `pip-tools` exclusive, they can be used with plain `pip` too. After all, `pip-tools` is, well, built over __`pip`__ and `.in` files are just yet-uncompiled/unpinned/non-locked regular requirements files - they are perfectly valid requirement files and can be fed directly to `pip`.  
As an example let's start with `requirements.quickstart.base.in`:
```console
$ echo 'Flask~=1.1
> loginpass~=0.3
> numpy~=1.1
> tensorflow~=2.0
> google-cloud-storage~=1.2
> google-cloud-ndb~=1.1' > requirements.quickstart.base.in
```
We will likely need `pytest`, `coverage` and some other utilities during development. As we said above, there is two ways to get there, one with `-r`:
```console
$ echo '-r requirements.quickstart.base.in
>
> pytest~=5.4
> coverage~=5.0' > requirements.quickstart.dev-r.in
```
And one with `-c`:
```console
$ echo '-c requirements.quickstart.base.in
>
> pytest~=5.4
> coverage~=5.0' > requirements.quickstart.dev-c.in
```
Their outputs are shown below.
<details>
<summary>For <code>-r</code>:</summary>

```
#
# This file is autogenerated by pip-compile
# To update, run:
#
#    pip-compile requirements.quickstart.dev-r.in
#
absl-py==0.9.0            # via tensorboard, tensorflow
astor==0.8.1              # via tensorflow
attrs==19.3.0             # via pytest
authlib==0.14.1           # via loginpass
cachetools==4.1.0         # via google-auth
certifi==2020.4.5.1       # via requests
cffi==1.14.0              # via cryptography
chardet==3.0.4            # via requests
click==7.1.1              # via flask
coverage==5.0.4           # via -r requirements.quickstart.dev_r.in
cryptography==2.9         # via authlib
flask==1.1.2              # via -r requirements.quickstart.base.in
gast==0.2.2               # via tensorflow
google-api-core[grpc]==1.16.0  # via google-cloud-core, google-cloud-datastore
google-auth-oauthlib==0.4.1  # via tensorboard
google-auth==1.13.1       # via google-api-core, google-auth-oauthlib, google-cloud-storage, tensorboard
google-cloud-core==1.3.0  # via google-cloud-datastore, google-cloud-storage
google-cloud-datastore==1.12.0  # via google-cloud-ndb
google-cloud-ndb==1.1.2   # via -r requirements.quickstart.base.in
google-cloud-storage==1.27.0  # via -r requirements.quickstart.base.in
google-pasta==0.2.0       # via tensorflow
google-resumable-media==0.5.0  # via google-cloud-storage
googleapis-common-protos==1.51.0  # via google-api-core
grpcio==1.28.1            # via google-api-core, tensorboard, tensorflow
h5py==2.10.0              # via keras-applications
idna==2.9                 # via requests
importlib-metadata==1.6.0  # via pluggy, pytest
itsdangerous==1.1.0       # via flask
jinja2==2.11.1            # via flask
keras-applications==1.0.8  # via tensorflow
keras-preprocessing==1.1.0  # via tensorflow
loginpass==0.4            # via -r requirements.quickstart.base.in
markdown==3.2.1           # via tensorboard
markupsafe==1.1.1         # via jinja2
more-itertools==8.2.0     # via pytest
numpy==1.18.2             # via -r requirements.quickstart.base.in, h5py, keras-applications, keras-preprocessing, opt-einsum, scipy, tensorboard, tensorflow
oauthlib==3.1.0           # via requests-oauthlib
opt-einsum==3.2.0         # via tensorflow
packaging==20.3           # via pytest
pluggy==0.13.1            # via pytest
protobuf==3.11.3          # via google-api-core, googleapis-common-protos, tensorboard, tensorflow
py==1.8.1                 # via pytest
pyasn1-modules==0.2.8     # via google-auth
pyasn1==0.4.8             # via pyasn1-modules, rsa
pycparser==2.20           # via cffi
pyparsing==2.4.7          # via packaging
pytest==5.4.1             # via -r requirements.quickstart.dev_r.in
pytz==2019.3              # via google-api-core
redis==3.4.1              # via google-cloud-ndb
requests-oauthlib==1.3.0  # via google-auth-oauthlib
requests==2.23.0          # via google-api-core, loginpass, requests-oauthlib, tensorboard
rsa==4.0                  # via google-auth
scipy==1.4.1              # via tensorflow
six==1.14.0               # via absl-py, cryptography, google-api-core, google-auth, google-pasta, google-resumable-media, grpcio, h5py, keras-preprocessing, packaging, protobuf, tensorboard, tensorflow
tensorboard==2.1.1        # via tensorflow
tensorflow-estimator==2.1.0  # via tensorflow
tensorflow==2.1.0         # via -r requirements.quickstart.base.in
termcolor==1.1.0          # via tensorflow
urllib3==1.25.8           # via requests
wcwidth==0.1.9            # via pytest
werkzeug==1.0.1           # via flask, tensorboard
wheel==0.34.2             # via tensorboard, tensorflow
wrapt==1.12.1             # via tensorflow
zipp==3.1.0               # via importlib-metadata

# The following packages are considered to be unsafe in a requirements file:
# setuptools
```
</details>

<details>
<summary>And for <code>-c</code>:</summary>

```
#
# This file is autogenerated by pip-compile
# To update, run:
#
#    pip-compile requirements.quickstart.dev-c.in
#
attrs==19.3.0             # via pytest
coverage==5.0.4           # via -r requirements.quickstart.dev_c.in
importlib-metadata==1.6.0  # via pluggy, pytest
more-itertools==8.2.0     # via pytest
packaging==20.3           # via pytest
pluggy==0.13.1            # via pytest
py==1.8.1                 # via pytest
pyparsing==2.4.7          # via packaging
pytest==5.4.1             # via -r requirements.quickstart.dev_c.in
six==1.14.0               # via packaging
wcwidth==0.1.9            # via pytest
zipp==3.1.0               # via importlib-metadata
```
</details>

We see that the former output contains all the base dependencies plus development dependencies, but the latter pinned only what's inside `.dev_c.in`. As you can see, `-r` option "includes" everything from base file, whereas `-c` only _respects_ it - C stands for constraint.  
Which one should we use? I personally prefer composition over inheritance. For one, there's not so much duplication going on. Second - it's more verbose during installation. Compare:  
`pip install --no-deps -r requirements.quickstart.dev-r.txt`  
vs  
`pip install --no-deps -r requirements.quickstart.base.txt -r requirements.quickstart.dev-c.txt`  
And third - composition affords greater flexibility. As an example you can check out PyPA Warehouse project, they have all sorts of requirement files: one for deployment with `gunicorn` in it, one for linting, one testing, one for docs and so on. You could install only what you need based on the environment, e.g. only base and test dependencies for integration testing on CI, only base + lint dependencies for linter CI Docker image, or just everything together in local development environment.

There's one glaring mistake in the previous example - we're layering on top of `.in` requirements. Respecting `.base.in` is not enough, to maintain air-tight consistency across environments we must respect its compiled version, i.e. `.base.txt`. I'll leave it to you to guess why.  
To correct for that mistake we would:
```console
$ cp requirements.quickstart.dev-c.in requirements.quickstart.dev.in
$ sed -i -e 's/.in/.txt/' requirements.quickstart.dev.in
$ pip-compile requirements.quickstart.dev.in
```
Now we can combine`.base.txt` and `.dev.txt` to create our development environment:
```bash
virtualenv venv_dev --python=/usr/bin/python3.6
source venv_dev/bin/activate.fish
pip install --no-deps -r requirements.quickstart.base.txt -r requirements.quickstart.dev.txt
```
Again, it's _important_ to use `--no-deps` flag. (TODO: maybe illustrate, or explain that? EDIT: turns out `--no-deps` is not necessary with _pinned_ requirement files, should edit text accordingly.)


#### `pip-sync`

The name is self-descriptive: while `pip install -r` only installs stuff, it doesn't attempt to synchronize the environment to given `.txt` files, whereas `pip-sync` does just that.  
To see it in action we run it in `venv_dev`, created above:
```console
(venv_dev) $ pip install pip-tools
(venv_dev) $ pip-sync requirements.quickstart.base.txt
Found existing installation: attrs 19.3.0
Uninstalling attrs-19.3.0:
  Successfully uninstalled attrs-19.3.0
Found existing installation: coverage 5.0.4
Uninstalling coverage-5.0.4:
  Successfully uninstalled coverage-5.0.4
...
Found existing installation: zipp 3.1.0
Uninstalling zipp-3.1.0:
  Successfully uninstalled zipp-3.1.0
```
Basically, `pip-sync` had to uninstall every dependeny in `requirements.quickstart.dev.txt` to leave us with only `requirements.quickstart.base.txt` libraries. With one exception: it doesn't uninstall itself:
```console
$ pip freeze | grep pip-tools
pip-tools==4.5.1
```
We might not want to have `pip-tools` in e.g. our production environment, which means that `pip-sync` is not a `pip install -r` replacement, but a convenience tool to help during development, when making edits to requirement files. We would compile and synchronize dependencies as necessary, removing the need of creating fresh virtual environment each time.  
