# Copilot Instructions for Self-Hosted Home Server

This document provides guidelines for GitHub Copilot when working with the Self-Hosted Home Server codebase.

## Project Structure

- **ansible/**: Ansible playbooks and configuration for deployment automation

  - **playbooks/**: Contains the main playbooks for system setup and service deployment
  - **group_vars/**: Variables used across the Ansible playbooks
  - **inventory/**: Defines the deployment targets (local and remote)

- **configs/**: Configuration files and backups

  - **backups/**: Stores backups of configurations and volumes
  - **services/**: Service-specific configurations

- **docker-compose/**: Docker Compose files for each service

  - Each subdirectory contains a service with its docker-compose.yml and related files

- **scripts/**: Automation scripts for deployment, backup, update, and shutdown

  - **deploy.sh**: Main deployment script
  - **update.sh**: Updates existing deployments
  - **backup.sh**: Creates backups of service data
  - **shutdown.sh**: Safely shuts down services

- **.vscode/tasks.json**: VS Code tasks for common operations

## Important Guidelines

1. **ALWAYS UPDATE TASKS.JSON WHEN ADDING NEW FUNCTIONALITY**:

   - When adding new scripts or modifying existing ones, make sure to update the VS Code tasks in `.vscode/tasks.json`
   - Tasks should follow the established pattern for naming and organization

2. **ALWAYS UPDATE README.MD WITH NEW FEATURES OR CHANGES**:

   - The README.md file serves as the main documentation for users
   - Document any new services, features, or script parameters
   - Keep the usage examples up to date

3. **Script Modifications**:

   - All scripts follow a consistent pattern with colored output and command-line arguments
   - When modifying scripts, preserve the existing style and argument handling patterns
   - Ensure help messages are updated when adding new options

4. **Ansible Integration**:

   - The system uses Ansible for deployment automation
   - New services should have corresponding entries in the Ansible playbooks
   - Understand the relationship between the docker-compose files and the Ansible deployment

5. **Docker Compose Structure**:
   - Each service has its own directory with a docker-compose.yml
   - Services are deployed through Ansible using these Docker Compose files

## Deployment Workflow

1. Setup system with Docker and dependencies (setup-system.yml)
2. Deploy services using Docker Compose (deploy-services.yml)
3. Configure services and set up networking

## Common Development Tasks

- Adding a new service:

  1. Create a new directory in docker-compose/
  2. Add the service to the Ansible playbooks
  3. Update tasks.json with any service-specific tasks
  4. Update README.md with service information

- Modifying deployment options:
  1. Update the relevant script(s) with new options
  2. Update tasks.json with new tasks
  3. Document the new options in README.md

## Terminal Command Execution

- **ALWAYS RUN TERMINAL COMMANDS TO VERIFY CODE**:
  - Use the terminal to test scripts and verify changes before committing
  - Run newly modified scripts to ensure they work as expected
  - Execute relevant commands to check for syntax errors or runtime issues
  - When adding new functionality to scripts, test all options and edge cases
  - After making changes to Docker configurations, verify with appropriate Docker commands
  - For Ansible changes, run playbooks with `--check` mode first when appropriate
