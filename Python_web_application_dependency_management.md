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
To see a larger action, let's run `pip-compile` on a more involved requirements file:
```console
$ echo TODO
```
