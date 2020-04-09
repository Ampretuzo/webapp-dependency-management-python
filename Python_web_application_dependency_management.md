# Python web application dependency management using `pip-tools`, `virtualenv` and `GNU Make`
I have used `pip-tools` and `virtualenv` with great success in the past.  
These tools are simple and reliable. And flexible, as a corollary of their simplicity.  
In the last project I brought everything under the same roof using a good old `Makefile`.  
This writeup is supposed to document my approach with these tools.



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
Running `pip-compile requirements.quickstart_tf.in` yields an error:
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
