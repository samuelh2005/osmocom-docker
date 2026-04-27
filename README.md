# Osmocom in Docker

This stack is a minimal lab setup for OsmoMSC, OsmoHLR, and OsmoSTP. This does not provide any radio access network, but you can add one later.

What is included:
- `Dockerfile`
- `osmo-hlr.cfg`
- `osmo-msc.cfg`
- `docker-compose.yml`

How to use:
1. Run `docker compose up --build`.
2. Connect to the management ports on `localhost`.

Management ports published on the host:
- MSC VTY: `127.0.0.1:4254`
- MSC CTRL: `127.0.0.1:4255`
- HLR VTY: `127.0.0.1:4258`
- HLR CTRL: `127.0.0.1:4259`
- HLR GSUP: `127.0.0.1:4222`
- STP VTY: `127.0.0.1:4239`
