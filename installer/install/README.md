# CyberPot Installer

Ansible-based installation system for deploying CyberPot honeypot infrastructure.

## Prerequisites

### System Requirements

- **Supported Operating Systems**:
  - Debian 11+
  - Ubuntu 20.04+
  - Raspbian (for ARM/Raspberry Pi)
  - AlmaLinux 8+
  - Rocky Linux 8+
  - Fedora 35+
  - RedHat Enterprise Linux 8+
  - openSUSE Tumbleweed

- **Hardware Requirements**:
  - Minimum 2GB RAM (4GB+ recommended)
  - 20GB+ available disk space
  - x86_64 or ARM64 architecture

### Software Requirements

- **Ansible**: Version 2.9 or higher
  ```bash
  # Install on macOS
  brew install ansible
  
  # Install on Debian/Ubuntu
  sudo apt update && sudo apt install ansible
  
  # Install on RHEL/Rocky/Alma
  sudo dnf install ansible
  ```

- **SSH Access**: Passwordless SSH access to target hosts
- **Python 3**: On target hosts (installed automatically if missing)

## Quick Start

### 1. Configure Inventory

Copy the example inventory and customize it:

```bash
cd installer/install
cp inventory.yml.example inventory.yml
```

Edit `inventory.yml` with your target host details:

```yaml
cyberpot:
  hosts:
    your-host-ip:
      ansible_port: 22
      ansible_user: your-username
```

> [!IMPORTANT]
> Never commit `inventory.yml` to version control. It's already in `.gitignore`.

### 2. Bootstrap Sudo (First-time only)

If your target system doesn't have sudo configured:

```bash
ansible-playbook -i inventory.yml sudo.yml --ask-become-pass
```

This will:
- Install sudo if not present
- Add your user to the sudo group
- Configure sudoers file

### 3. Install CyberPot

Run the main installation playbook:

```bash
ansible-playbook -i inventory.yml cyberpot.yml
```

This will:
- Install Docker and dependencies
- Configure system settings
- Clone CyberPot repository
- Install systemd service
- Set up daily maintenance cron job

### 4. Deploy Sensor (Optional)

To deploy a sensor node that reports to a central hive:

```bash
# Set required environment variables
export myCYBERPOT_HIVE_USER="your-hive-username"
export myCYBERPOT_HIVE_IP="your-hive-ip-address"

# Run sensor deployment
ansible-playbook -i inventory.yml deploy.yml
```

## Playbook Descriptions

### [sudo.yml](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/sudo.yml)

**Purpose**: Bootstrap sudo access on target systems

**When to use**: 
- First-time setup on fresh systems
- Systems where sudo is not installed
- When your user is not in the sudo group

**Requirements**:
- Root password (use `--ask-become-pass`)
- Must NOT be run as root user
- Must NOT be run as 'cyberpot' user

**Example**:
```bash
ansible-playbook -i inventory.yml sudo.yml --ask-become-pass
```

---

### [cyberpot.yml](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/cyberpot.yml)

**Purpose**: Main CyberPot installation playbook

**What it does**:
1. Bootstraps Python 3 if missing
2. Validates user and distribution
3. Installs recommended packages
4. Removes conflicting packages
5. Installs Docker Engine
6. Configures system settings (vm.max_map_count, DNS)
7. Creates cyberpot user and group
8. Clones CyberPot repository
9. Installs systemd service
10. Sets up daily reboot cron job

**Requirements**:
- Sudo access configured
- Internet connectivity
- Supported OS distribution

**Example**:
```bash
ansible-playbook -i inventory.yml cyberpot.yml
```

**Tags**: You can run specific sections using tags:
```bash
# Install only on Debian systems
ansible-playbook -i inventory.yml cyberpot.yml --tags "Debian"

# Skip specific distributions
ansible-playbook -i inventory.yml cyberpot.yml --skip-tags "Fedora"
```

---

### [deploy.yml](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/deploy.yml)

**Purpose**: Deploy sensor configuration to report to central hive

**What it does**:
1. Copies hive certificate to sensor
2. Switches to sensor docker-compose configuration
3. Configures hive connection settings
4. Reboots sensor to apply changes

**Requirements**:
- CyberPot already installed (run `cyberpot.yml` first)
- Environment variables set:
  - `myCYBERPOT_HIVE_USER`: Username on hive
  - `myCYBERPOT_HIVE_IP`: IP address of hive
- Nginx certificate from hive at `~/cyberpot/data/nginx/cert/nginx.crt`

**Example**:
```bash
export myCYBERPOT_HIVE_USER="admin"
export myCYBERPOT_HIVE_IP="192.168.1.100"
ansible-playbook -i inventory.yml deploy.yml
```

> [!WARNING]
> This playbook will reboot the sensor after deployment.

## Configuration

### Inventory Structure

The inventory file supports multiple hosts and groups:

```yaml
cyberpot:
  hosts:
    hive-server:
      ansible_host: 192.168.1.100
      ansible_port: 22
      ansible_user: admin
    
    sensor-1:
      ansible_host: 192.168.1.101
      ansible_port: 22
      ansible_user: sensor
    
    sensor-2:
      ansible_host: 192.168.1.102
      ansible_port: 22
      ansible_user: sensor
```

### Ansible Configuration

Create `ansible.cfg` in the installer directory for custom settings:

```ini
[defaults]
host_key_checking = False
retry_files_enabled = False
timeout = 30

[ssh_connection]
pipelining = True
```

## Troubleshooting

### Common Issues

#### "Python not found" error

**Problem**: Target system doesn't have Python 3 installed

**Solution**: The playbook should install Python automatically. If it fails, manually install:
```bash
# Debian/Ubuntu
ssh user@host "sudo apt update && sudo apt install -y python3"

# RHEL/Rocky/Alma
ssh user@host "sudo dnf install -y python3"
```

---

#### "Permission denied" errors

**Problem**: SSH key authentication not set up

**Solution**: Set up SSH keys:
```bash
ssh-copy-id user@target-host
```

Or use password authentication:
```bash
ansible-playbook -i inventory.yml cyberpot.yml --ask-pass
```

---

#### "Sudo password required" errors

**Problem**: User doesn't have passwordless sudo

**Solution**: Use `--ask-become-pass`:
```bash
ansible-playbook -i inventory.yml cyberpot.yml --ask-become-pass
```

Or run `sudo.yml` first to configure sudo.

---

#### Docker installation fails

**Problem**: Conflicting packages or repository issues

**Solution**: 
1. Check internet connectivity
2. Manually remove conflicting packages:
   ```bash
   ssh user@host "sudo apt remove docker docker-engine docker.io containerd runc"
   ```
3. Re-run the playbook

---

#### Service fails to start

**Problem**: Docker compose file or configuration issue

**Solution**:
1. Check service status:
   ```bash
   ssh user@host "sudo systemctl status cyberpot.service"
   ```
2. Check Docker logs:
   ```bash
   ssh user@host "sudo journalctl -u cyberpot.service -n 50"
   ```
3. Verify docker-compose.yml exists:
   ```bash
   ssh user@host "ls -la ~/cyberpot/docker-compose.yml"
   ```

---

#### Environment variables not set (deploy.yml)

**Problem**: Required environment variables missing

**Solution**: Ensure variables are exported before running:
```bash
export myCYBERPOT_HIVE_USER="your-user"
export myCYBERPOT_HIVE_IP="your-ip"
ansible-playbook -i inventory.yml deploy.yml
```

## Security Considerations

### Sudo Configuration

The `sudo.yml` playbook grants sudo access to your user. This is required for system administration but should be used carefully:

- Only run on trusted systems
- Review the sudoers configuration after installation
- Consider restricting sudo access to specific commands in production

### SSH Access

- Use SSH key authentication instead of passwords
- Disable password authentication in `/etc/ssh/sshd_config`
- Use SSH agent forwarding carefully (only on trusted networks)

### Inventory File

- **Never commit `inventory.yml` to version control**
- Store sensitive credentials in Ansible Vault
- Use separate inventories for different environments

### Network Security

- Ensure target systems are on trusted networks during installation
- Review firewall rules after installation
- Change default passwords and credentials

## Advanced Usage

### Check Mode (Dry Run)

Test playbooks without making changes:

```bash
ansible-playbook -i inventory.yml cyberpot.yml --check
```

### Verbose Output

Get detailed execution information:

```bash
ansible-playbook -i inventory.yml cyberpot.yml -v    # verbose
ansible-playbook -i inventory.yml cyberpot.yml -vv   # more verbose
ansible-playbook -i inventory.yml cyberpot.yml -vvv  # very verbose
```

### Limit Execution to Specific Hosts

```bash
ansible-playbook -i inventory.yml cyberpot.yml --limit sensor-1
```

### Step-by-Step Execution

Execute tasks one at a time with confirmation:

```bash
ansible-playbook -i inventory.yml cyberpot.yml --step
```

### Start at Specific Task

Resume from a specific task:

```bash
ansible-playbook -i inventory.yml cyberpot.yml --start-at-task="Install Docker Engine packages"
```

## Files Reference

- **[a.txt](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/a.txt)**: Adjectives word list (27,321 words) for random name generation
- **[n.txt](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/n.txt)**: Nouns word list (82,150 words) for random name generation
- **[cyberpot.service](file:///Users/KhulnaSoft/projects/cyberpot/installer/install/cyberpot.service)**: Systemd service template for CyberPot

## Support

For issues and questions:

- **GitHub Issues**: https://github.com/khulnasoft/cyberpot/issues
- **Documentation**: Check the main CyberPot repository
- **Logs**: Check `/var/log/syslog` and `journalctl -u cyberpot.service`

## Contributing

When contributing improvements to the installer:

1. Test on multiple distributions
2. Ensure idempotency (playbooks can run multiple times safely)
3. Add appropriate error handling
4. Update this README with any new features or changes
5. Run `ansible-lint` before submitting PRs

## License

See the main CyberPot repository for license information.
