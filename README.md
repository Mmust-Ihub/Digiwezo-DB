# Digiwezo MongoDB Infrastructure
This repo contains the code for deploying, managing and scaling a production-ready **mongodb cluster** for the [**Digiwezo**](https://github.com/Mmust-Ihub/Digiwezo-web-system) project, designed to ensure data reliability, business continuity, and zero-downtime operations through:

1. **High Availability:** 3-node replica set(Primary + Secondary + Arbiter) with automatic failover.
2. **Automated Backups:** Daily scheduled backups with configurable retention policies
3. **Disaster Recevery:** Tested restore procedures with point-in-time recovery capabilities.
4. **Production Ready:** Docker-based deployment with persistent storage and security best practices.



## Architecture
```css
┌─────────────────────────────────────────────────────────┐
│                    MongoDB Cluster                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐       │
│  │ mongod1  │ ───► │ mongod2  │      │ mongod3  │       │
│  │ Primary  │ ◄─── │Secondary │      │ Arbiter  │       │
│  └──────────┘      └──────────┘      └──────────┘       │
│       │                  │                  │           │
│       └──────────────────┴──────────────────┘           │
│                    Replica Set: dbrs                    │
└─────────────────────────────────────────────────────────┘
           │                          │
           ▼                          ▼
    ┌─────────────┐          ┌─────────────┐
    │   Backup    │          │    Mongo    │
    │  Container  │          │   Express   │
    └─────────────┘          └─────────────┘
```

## Features
### High Availability
- **Automatic Failover:** If the primary falls, secondary is automatically promoted.
- **Data Redundancy:** All data is replicated across multiple nodes.
- **Read Scaling:** Read operations are distributed to secondary nodes
- **Zero RPO:** No data loss in case of single node failure.

### Backup and Recovery
- **Automated Daily Backups:** Scheduled backups with timestamp-based naming.
- **Configurable Retention:** Automatic cleanup of backups older than specified days.
- **Validated Restores:** Battle-tested restoration procedures with authentication handling.
- **Point-in-Time Recovery:** Optional oplog backups for granualar recovery points.

### Security
  - **Authentication Enabled:** Root user authentication on all nodes.
  - **Replica Set Keyfile:** Internal authentication between cluster members.
  - **Network Isolation:** Custom Docker network for secure communication.