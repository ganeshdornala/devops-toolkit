# DevOps Toolkit

A Bash-based Developer Operations Toolkit for monitoring system health, managing applications, collecting logs, performing HTTP health checks, and deploying applications through SSH.

## Features

- Machine health monitoring
- CPU, memory, and disk monitoring
- Application start, stop, restart, and status management
- Application log collection
- HTTP health checks
- Remote deployment through SSH
- Deployment rollback
- Automated tests
- GitHub Actions CI

## Project Structure

devops-toolkit/
├── bin/
│   └── devops-toolkit
├── config/
├── deploy/
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
├── .gitignore
└── README.md

## Usage

./bin/devops-toolkit health
./bin/devops-toolkit app status
./bin/devops-toolkit logs collect
./bin/devops-toolkit http health-check
./bin/devops-toolkit deploy
./bin/devops-toolkit rollback

## Status

This project is being developed incrementally, with each feature implemented, tested, and documented before moving to the next stage.
