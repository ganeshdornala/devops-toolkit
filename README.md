# DevOps Toolkit

A Bash-based Developer Operations Toolkit for monitoring system health, managing applications, collecting logs, performing HTTP health checks, and deploying applications through SSH.

## Features

- Machine health monitoring
- CPU, memory, disk, and load monitoring
- Application start, stop, restart, and status management
- Application log collection and archiving
- HTTP health checks
- SSH-based application deployment
- Deployment rollback
- Automated test suites
- GitHub Actions CI

## Requirements

- Bash
- Linux or WSL2
- `curl`
- `nc`
- `ssh`
- `scp`
- `tar`
- `openssh-server` for deployment tests
- `sudo` for local SSH deployment tests

## Project Structure

```text
devops-toolkit/
├── apps/
│   ├── logs/
│   ├── pids/
│   ├── run/
│   ├── ssh-target/
│   ├── http-test-server.sh
│   └── test-app.sh
├── bin/
│   └── devops-toolkit
├── config/
│   └── devops-toolkit.conf
├── deploy/
│   ├── deploy.sh
│   └── rollback.sh
├── docs/
├── lib/
│   ├── app.sh
│   ├── common.sh
│   ├── deploy.sh
│   ├── health.sh
│   ├── http.sh
│   └── logs.sh
├── logs/
├── tests/
│   ├── test_app.sh
│   ├── test_deploy.sh
│   ├── test_health.sh
│   ├── test_http.sh
│   └── test_logs.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── .gitignore
└── README.md
```

## Usage

Run the toolkit from the project root:

```bash
./bin/devops-toolkit <command> <subcommand>
```

### Machine Health

```bash
./bin/devops-toolkit health
```

Displays:

- Hostname
- System uptime
- CPU usage
- Memory usage
- Disk usage
- Load average
- Individual metric status
- Overall health status

### Application Management

Check application status:

```bash
./bin/devops-toolkit app status
```

Start the application:

```bash
./bin/devops-toolkit app start
```

Stop the application:

```bash
./bin/devops-toolkit app stop
```

Restart the application:

```bash
./bin/devops-toolkit app restart
```

### Log Collection

Collect and archive application logs:

```bash
./bin/devops-toolkit logs collect
```

Archives are stored under:

```text
logs/
```

### HTTP Health Checks

Run the default HTTP health check:

```bash
./bin/devops-toolkit http health-check
```

Check a specific URL:

```bash
./bin/devops-toolkit http health-check http://localhost:8080
```

A 200 response is considered healthy.

### Deployment

Deploy the test application through SSH:

```bash
./bin/devops-toolkit deploy
```

Roll back the deployment:

```bash
./bin/devops-toolkit rollback
```

Deployment configuration is stored in:

```text
config/devops-toolkit.conf
```

The deployment tests create a temporary local SSH test environment and do not require an external server.

## Configuration

Health thresholds and deployment settings are configured in:

```text
config/devops-toolkit.conf
```

Default health thresholds:

```text
CPU warning:       70%
CPU critical:      90%

Memory warning:    70%
Memory critical:   90%

Disk warning:      70%
Disk critical:     90%
```

Deployment tests use:

```text
Host: 127.0.0.1
Port: 2222
```

SSH credentials used for local deployment testing are generated locally and ignored by Git.

## Testing

Run the individual test suites:

```bash
./tests/test_health.sh
./tests/test_app.sh
./tests/test_logs.sh
./tests/test_http.sh
./tests/test_deploy.sh
```

The deployment test starts a temporary SSH server, verifies SSH connectivity, deploys the application, verifies the deployed file and executable permissions, and then performs a rollback.

## Continuous Integration

GitHub Actions runs the complete test suite on:

- Pushes to `main`
- Pull requests targeting `main`

The workflow:

- Checks out the repository
- Installs the SSH server and Netcat
- Generates temporary SSH test credentials
- Makes project scripts executable
- Runs all test suites

Workflow file:

```text
.github/workflows/ci.yml
```

## Exit Codes

The health command uses the following exit codes:

| Status   | Exit code |
|----------|-----------|
| HEALTHY  | 0         |
| WARNING  | 1         |
| CRITICAL | 2         |

Other command failures return a non-zero exit code.

## Development Status

Implemented:

- [x] Project structure
- [x] Machine health monitoring
- [x] Application management
- [x] Log collection
- [x] HTTP health checks
- [x] SSH deployment
- [x] Deployment rollback
- [x] Automated tests
- [x] GitHub Actions CI

The project is developed incrementally with each feature implemented and tested before moving to the next stage.
