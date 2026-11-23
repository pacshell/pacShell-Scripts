# Java 25 LTS Browser IDE on Proxmox LXC

Set up a self-hosted Java development environment using **Eclipse Temurin 25 LTS**, **code-server**, **Maven**, **Gradle**, and **Git** inside a **Debian 13 (Trixie) LXC** on Proxmox VE. Access your editor from a browser—no desktop environment or Docker required.

> **Security:** This installer binds code-server to `0.0.0.0` and uses **password authentication over plain HTTP**. Only use it on a trusted, restricted LAN. For remote or public access, put it behind HTTPS with appropriate access controls or connect through a VPN. Do not port-forward port 8080 directly to the internet.

## Features

- Eclipse Temurin **Java 25 LTS** via the signed Adoptium APT repository
- `java` and `javac` configured to use Java 25; `JAVA_HOME` configured for login shells
- Browser-based VS Code experience with **code-server**
- Java Extension Pack, subject to Open VSX extension availability/compatibility
- Git, Maven, Gradle, ZIP/unzip and common utilities
- Dedicated unprivileged development user (`developer` by default)
- Password-protected code-server, run as a **systemd** service
- Example project at `~/projects/hello-java/Main.java`
- Re-running the script preserves an existing code-server config and sample source

## Requirements

- Proxmox VE with an LXC guest running **Debian 13** and `systemd` as PID 1
- A shell with **root** privileges inside the container
- Working internet, DNS, and access to APT, Adoptium, code-server and Open VSX endpoints
- Suggested resources: **2–4 vCPU**, **4–8 GB RAM**, **30 GB disk**
- A free TCP port (default **8080**) and LAN access to the container's IP

An **unprivileged LXC** is preferred; there is no need to enable nesting solely for this installation.

## Quick start

Create a Debian 13 container, copy this repository into it, and run as root:

```bash
git clone https://github.com/YOUR_USERNAME/pacShell-Scripts.git
cd pacShell-Scripts/java-ide-lxc
bash install-java-ide-lxc.sh
```

**Note:** Replace `YOUR_USERNAME` with your actual GitHub username *after* publishing the repository. Before publishing, just copy the ZIP or script into the LXC and run it locally.

To customize the development account and port:

```bash
bash install-java-ide-lxc.sh javauser 8081
```

The installer prints the browser URL and a newly generated password on first setup. By default, open:

```text
http://LXC_IP:8080
```

If a code-server config already exists, the script **preserves its existing bind address, port, and password**, so the port argument does not overwrite it. The actual URL is then determined by `~/.config/code-server/config.yaml`.

## Check the installation

From inside the LXC:

```bash
java -version
javac -version
mvn -version
gradle --version
systemctl status code-server@developer
```

Run the hello-world example:

```bash
runuser -u developer -- java /home/developer/projects/hello-java/Main.java
```

Expected output:

```text
Hello from Java in a Proxmox LXC!
```

Alternatively, log into the web IDE and open `~/projects/hello-java`.

## Manage the service

```bash
systemctl status code-server@developer
systemctl restart code-server@developer
journalctl -u code-server@developer -f
```

For another username, replace `developer` in the service name.

## Configuration and persistence

| Item | Default |
| --- | --- |
| Linux development user | `developer` |
| HTTP port | `8080` |
| code-server settings | `/home/developer/.config/code-server/config.yaml` |
| Project workspace | `/home/developer/projects` |
| Java environment file | `/etc/profile.d/java-lts.sh` |
| Adoptium APT source | `/etc/apt/sources.list.d/adoptium.list` |
| systemd service | `code-server@developer.service` |

On an existing install, edit the config manually to change its port or authentication, then restart the service. Protect the config because it contains the code-server password. Use Proxmox backups or snapshots before major upgrades.

## Caveats

- **Gradle** comes from Debian's repository; it may be older than Gradle upstream. For new projects, prefer the project's **Gradle Wrapper** (`./gradlew`).
- code-server uses the **Open VSX** extension registry, not the Microsoft VS Code Marketplace. Some extensions may be missing or work differently.
- The installer downloads and executes code-server's official installation script and installs third-party packages. Review the script and the upstream projects before running it with root privileges.
- This is not a full Spring Boot application deployment, a Docker stack, an HTTPS reverse proxy, or a Proxmox CT provisioning script. It runs **inside an already-created LXC**.
- Re-running the script refreshes system packages and restarts code-server; avoid running it while important unsaved work is in progress.

## Upstream documentation

- [Eclipse Adoptium — Linux package installation](https://adoptium.net/installation/linux)
- [code-server — installation](https://coder.com/docs/code-server/install)
- [code-server — FAQ and extensions](https://coder.com/docs/code-server/FAQ)
- [Apache Maven](https://maven.apache.org/)
- [Gradle](https://gradle.org/)

## License

MIT — see [LICENSE](../LICENSE). This license covers the original repository materials, **not** third-party dependencies, which retain their respective licenses.
