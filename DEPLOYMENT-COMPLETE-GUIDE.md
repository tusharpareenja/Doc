# Docker Deployment Guide - Complete Stack

This guide explains how to deploy the complete Document Server stack (with RabbitMQ, PostgreSQL, and Redis) to both ARM and Intel servers.

## Prerequisites

- **Docker** and **Docker Compose** installed on both servers
- **SSH access** to both servers
- **rsync** installed on your local machine (for file transfer)
- Project files ready

## Architecture Overview

Each deployment includes:

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  RabbitMQ    │  │  PostgreSQL  │  │    Redis     │    │
│  │   (5672)     │  │   (5432)     │  │   (6379)     │    │
│  │              │  │              │  │              │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│         ▲                ▲                  ▲              │
│         │                │                  │              │
│         └────────────────┼──────────────────┘              │
│                          │                                 │
│              ┌────────────▼──────────────┐                │
│              │   Document Server        │                │
│              │   (Node.js Application)  │                │
│              │   (Port 8000)            │                │
│              └────────────────────────────┘                │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### For ARM Server (91.107.191.124)

```bash
# From your local machine
./deploy-arm.sh root@91.107.191.124 latest
```

### For Intel Server

```bash
# From your local machine
./deploy-intel.sh root@your-intel-ip latest
```

---

## Step-by-Step Manual Deployment

If you prefer to deploy manually, follow these steps:

### On the Target Server

#### 1. Prepare the Server

```bash
# SSH into the server
ssh root@91.107.191.124

# Create deployment directory
mkdir -p /root/docserver-deploy
cd /root/docserver-deploy
```

#### 2. Transfer Project Files

From your **local machine**:

```bash
# For ARM Server
rsync -avz --exclude 'node_modules' --exclude '.git' \
    ./ root@91.107.191.124:/root/docserver-deploy/

# For Intel Server
rsync -avz --exclude 'node_modules' --exclude '.git' \
    ./ root@your-intel-ip:/root/docserver-deploy/
```

#### 3. Start Services (on target server)

```bash
cd /root/docserver-deploy

# For ARM Server - use default docker-compose.yml
docker-compose up -d

# For Intel Server - use docker-compose.intel.yml
docker-compose -f docker-compose.intel.yml up -d
```

#### 4. Verify Services

```bash
# Check all containers are running
docker-compose ps

# View logs
docker-compose logs -f

# Test the service
curl http://localhost:8000/healthcheck

# Check RabbitMQ
curl http://localhost:15672  # Management UI at http://your-ip:15672
```

---

## Service Configuration

### Environment Variables

The services are configured with the following environment variables:

```yaml
Document Server:
  - NODE_ENV=production-linux
  - AMQP_URI=amqp://guest:guest@rabbitmq:5672
  - DB_HOST=postgres
  - DB_PORT=5432
  - DB_NAME=onlyoffice
  - DB_USER=onlyoffice
  - DB_PASS=onlyoffice
  - REDIS_HOST=redis
  - REDIS_PORT=6379

RabbitMQ:
  - Default User: guest
  - Default Password: guest
  - Management UI: http://your-ip:15672

PostgreSQL:
  - User: onlyoffice
  - Password: onlyoffice
  - Database: onlyoffice
  - Port: 5432

Redis:
  - Default Port: 6379
  - No authentication
```

### Modifying Configuration

To customize environment variables, edit the `docker-compose.yml` or `docker-compose.intel.yml` file before deploying.

```yaml
environment:
  - NODE_ENV=production-linux
  - AMQP_URI=amqp://guest:guest@rabbitmq:5672
  - DB_HOST=postgres
  # ... add or modify variables here
```

---

## Common Tasks

### View Logs

```bash
# View all service logs
docker-compose logs

# View specific service logs
docker-compose logs docserver
docker-compose logs rabbitmq
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f docserver
```

### Stop Services

```bash
# Stop all services (but keep volumes)
docker-compose down

# Stop and remove volumes (WARNING: This deletes data!)
docker-compose down -v
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart docserver

# Restart and view logs
docker-compose restart docserver && docker-compose logs -f docserver
```

### Update Configuration

To update the Document Server configuration:

1. Edit `/root/docserver-deploy/docker-compose.yml` or `.intel.yml`
2. Update environment variables as needed
3. Restart the service:
   ```bash
   docker-compose restart docserver
   ```

### Scale Services

To run multiple instances of Document Server (with load balancing):

```bash
# Scale to 3 instances (requires load balancer setup)
docker-compose up -d --scale docserver=3
```

---

## Troubleshooting

### AMQP Connection Refused

**Issue**: `[ERROR] [AMQP] Error: connect ECONNREFUSED 127.0.0.1:5672`

**Solution**: 
- Ensure RabbitMQ container is running: `docker-compose ps`
- Check RabbitMQ logs: `docker-compose logs rabbitmq`
- Verify network connectivity: `docker network ls`

### Database Connection Error

**Issue**: `Error: connect ECONNREFUSED 127.0.0.1:5432`

**Solution**:
- Check PostgreSQL is running: `docker-compose ps`
- Verify database credentials in `docker-compose.yml`
- Check PostgreSQL logs: `docker-compose logs postgres`

### Port Already in Use

**Issue**: `Error: Error starting userland proxy: listen tcp 0.0.0.0:8000: bind: address already in use`

**Solution**:
```bash
# Find what's using port 8000
lsof -i :8000

# Either kill that process or change the port in docker-compose.yml
# Change "8000:8000" to "8001:8000" to use port 8001
```

### Out of Disk Space

**Issue**: `no space left on device`

**Solution**:
```bash
# Check disk usage
df -h

# Clean up Docker resources
docker system prune -a
docker volume prune

# Or remove old logs
docker-compose logs --no-log-prefix docserver > /dev/null
```

---

## Backup and Recovery

### Backup Data

```bash
# Backup database volume
docker run --rm -v docserver-deploy_postgres-data:/data \
    -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Backup document data
docker run --rm -v docserver-deploy_docserver-data:/data \
    -v $(pwd):/backup alpine tar czf /backup/docserver-backup.tar.gz -C /data .
```

### Restore from Backup

```bash
# Stop services
docker-compose down -v

# Restore database
docker run --rm -v docserver-deploy_postgres-data:/data \
    -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/postgres-backup.tar.gz"

# Restore document data
docker run --rm -v docserver-deploy_docserver-data:/data \
    -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/docserver-backup.tar.gz"

# Start services
docker-compose up -d
```

---

## Performance Tuning

### Increase Resource Limits

Edit `docker-compose.yml`:

```yaml
docserver:
  # ... other config
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
```

### Enable Persistent Storage

All volumes are already persistent and stored on the host machine:

```bash
# Check volume locations
docker volume inspect docserver-deploy_postgres-data
docker volume inspect docserver-deploy_docserver-data
```

---

## Security Considerations

### Change Default Credentials

**RabbitMQ:**
```bash
docker exec docserver-rabbitmq rabbitmqctl change_password guest newpassword
```

Then update in `docker-compose.yml`:
```yaml
- AMQP_URI=amqp://guest:newpassword@rabbitmq:5672
```

**PostgreSQL:**

Edit `.env` file or directly in `docker-compose.yml`:
```yaml
postgres:
  environment:
    POSTGRES_PASSWORD: strong-password-here
```

### Firewall Rules

Restrict access to management ports:

```bash
# Allow only local access to RabbitMQ management UI
sudo iptables -A INPUT -p tcp --dport 15672 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 15672 -j DROP

# Allow only local access to PostgreSQL
sudo iptables -A INPUT -p tcp --dport 5432 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
```

---

## Next Steps

1. **Monitor Health**: Set up monitoring and alerting for the services
2. **Backup Strategy**: Implement regular backups of the database and document volumes
3. **Load Balancing**: Set up a reverse proxy (Nginx, HAProxy) for multiple instances
4. **SSL/TLS**: Configure HTTPS for Document Server access
5. **Authentication**: Set up user authentication and authorization

---

## Support

For issues or questions:
- Check the logs: `docker-compose logs -f`
- Review the Dockerfile: `Dockerfile.arm64` or `Dockerfile.intel`
- Check official ONLYOFFICE documentation: https://helpcenter.onlyoffice.com/

