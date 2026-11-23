# pacShell-Scripts



**A collection of practical Bash scripts for Linux system administration, infrastructure management, automation, and self-hosted environments.**



`pacShell-Scripts` is a growing collection of shell scripts designed to simplify repetitive tasks, accelerate deployments, and streamline system administration.



The project focuses on practical, reusable solutions for Linux-based environments, including Debian, Proxmox VE, LXC containers, networking, and DevOps workflows.



## Repository Structure



Each script is organized in its own directory, containing the executable script and a dedicated README with installation instructions, requirements, configuration options, and usage examples.



```text

pacShell-Scripts/

├── README.md

├── LICENSE

├── java-ide-lxc/

│   ├── README.md

│   └── install-java-ide-lxc.sh

└── ...

```



## Available Scripts



| Script | Description |

| --- | --- |

| [Java IDE LXC](java-ide-lxc/README.md) | Deploy a browser-based Java 25 LTS development environment inside a Debian LXC container, using code-server. |



Additional scripts will be added as the project evolves.



## Getting Started



Clone the repository:



```bash

git clone https://github.com/YOUR_USERNAME/pacShell-Scripts.git

cd pacShell-Scripts

```



Navigate to the directory of the script you want to use:



```bash

cd java-ide-lxc

```



Read its documentation before execution:



```bash

cat README.md

```



Make the script executable:



```bash

chmod +x install-java-ide-lxc.sh

```



Run the script according to its documentation.



> **Important:** Some scripts require root privileges or modify system configurations. Always review the source code and requirements before execution, especially in production environments.



## Project Goals



- **Simplicity:** Straightforward scripts with minimal unnecessary dependencies.

- **Automation:** Reduce manual configuration and repetitive administrative tasks.

- **Reusability:** Build tools that can be adapted to different environments.

- **Transparency:** Keep the source code accessible, readable, and documented.

- **Self-Hosting:** Encourage control over infrastructure, services, and development environments.



## Compatibility



Scripts may target different Linux distributions, software versions, and execution environments.



Compatibility requirements are documented individually within each script's directory.



Not all scripts are intended to run on every Linux distribution.



## Contributions



Suggestions, improvements, bug reports, and pull requests are welcome.



When contributing a new script, please include:



- A dedicated directory.

- A descriptive script filename.

- A README explaining requirements, installation, and usage.

- Appropriate error handling and clear output messages.

- Relevant licensing and attribution information.



## Disclaimer



All scripts are provided **as is**, without warranties of any kind.



Review and test scripts in a controlled environment before deploying them to production systems.



The repository may include scripts that install third-party software. Such software remains subject to its respective licenses.



## License



Unless otherwise stated in an individual script directory, original scripts in this repository are distributed under the [MIT License](LICENSE).



Third-party software and externally sourced code remain subject to their respective licenses.



---



**Developed and maintained by pacShell**



*Open tools. Practical automation. Infrastructure under control.*
