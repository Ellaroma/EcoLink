# EcoLink

EcoLink is a decentralized smart contract system built on Clarity for environmental conservationists to **track initiatives**, **share research**, **endorse impact**, and **build coalitions** securely and transparently.

## 🌍 Overview

EcoLink empowers individuals and organizations working in environmental conservation by providing tools to:

- Create and manage conservationist profiles
- Publish and verify environmental projects and research
- Endorse impact in ecological focus areas
- Connect with like-minded conservationists via a secure invite system
- Manage privacy levels to control access to sensitive information

## 🔐 Privacy Controls

EcoLink supports three privacy levels across profiles, projects, and publications:

- `PUBLIC` — viewable by anyone
- `CONSERVATION-NETWORK` — viewable by coalition members
- `PRIVATE` — viewable only by the profile owner

## 🧩 Features

### 👤 Conservationist Profiles

- Register with name, bio, focus areas, and privacy settings
- Profiles can be verified by the contract owner
- Update profile anytime

### 🌱 Environmental Projects

- Add detailed descriptions of initiatives
- Set privacy level and optional completion target
- Track project-specific ecosystem types and start dates

### 📚 Research Publications

- Record peer-reviewed research or field reports
- Include journal, DOI, URL, and publication date
- Verification supported by contract owner

### 🤝 Coalition Network

- Send and accept coalition invites
- Manage statuses like "pending", "accepted", and "blocked"
- Connection enables viewing private data based on privacy level

### 🌟 Impact Endorsements

- Endorse other conservationists with public or private statements
- One endorsement per unique impact area per pair
- Timestamped to ensure traceability

## 📑 Error Codes

| Code            | Meaning                            |
|-----------------|------------------------------------|
| `ERR-NOT-AUTHORIZED (u100)` | Only the contract owner can perform this action |
| `ERR-CONSERVATIONIST-NOT-FOUND (u101)` | Profile not found for a given principal |
| `ERR-ALREADY-ENDORSED (u102)` | Endorsement already exists for that area |
| `ERR-INVALID-PRIVACY-LEVEL (u103)` | Provided privacy level is not valid |
| `ERR-PUBLICATION-NOT-FOUND (u104)` | Publication ID does not exist |

## 🛠 Admin Functions

- `verify-conservationist-profile`: Admin verifies a profile as authentic
- `verify-research-publication`: Admin verifies scientific research
- `set-contract-owner`: Transfer contract ownership

## 🚀 Deployment

This Clarity smart contract is designed for deployment on the Stacks blockchain (mainnet or testnet). To deploy:

```bash
clarinet check
clarinet test
clarinet deploy
