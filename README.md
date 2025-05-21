# DeFiStorage

A decentralized, smart contract-powered marketplace for secure file storage services—connecting storage providers and users with automated payments, agreements, and dispute resolution.

---

## Overview

**DeFiStorage** is a Clarity smart contract that enables a decentralized marketplace for file storage. Storage providers can list available space and set their prices, while users can purchase storage and upload file metadata. The contract manages payments, service agreements, and provides a built-in dispute resolution system.

---

## Features

- **Provider Registration:** Providers register, set available space, and pricing.
- **Storage Listings:** Providers create listings specifying storage size, price, and duration.
- **Purchase & Payment:** Users purchase storage, with platform fees automatically handled.
- **File Metadata:** Users attach file hashes and encryption key references to contracts.
- **Reputation System:** Providers have a reputation score that adjusts based on contract outcomes.
- **Dispute Resolution:** Users and providers can file disputes; the contract owner arbitrates, with automatic and manual resolution paths.
- **Platform Fees:** A 0.5% fee is charged on every transaction.

---

## Motivation

Centralized file storage marketplaces suffer from trust, censorship, and single points of failure. **DeFiStorage** leverages blockchain to create a transparent, trustless environment for storage trading, ensuring fair payments, automated agreements, and robust dispute handling.

---

## How It Works

1. **Provider Registration:**  
   Providers register with available space and price per MB per block.

2. **Create Listing:**  
   Providers list storage offers with size, price, and duration limits.

3. **Purchase Storage:**  
   Users select a listing, specify storage duration, and upload file metadata. Payments (including platform fee) are processed atomically.

4. **Service Period:**  
   Storage contract tracks duration and status. Providers deliver storage off-chain; metadata is referenced on-chain.

5. **Dispute Handling:**  
   Users or providers can file disputes. The contract owner arbitrates, redistributes payments, and updates reputation scores.

---

## Smart Contract Structure

| Component           | Description                                                              |
|---------------------|--------------------------------------------------------------------------|
| storage-providers   | Map: Provider info (space, price, reputation, active status)             |
| storage-listings    | Map: Listings (provider, space, price, min/max duration, availability)   |
| storage-contracts   | Map: Active contracts (provider, user, duration, payment, status)        |
| file-metadata       | Map: File hash, size, name, encryption key reference                     |
| next-listing-id     | Counter: Auto-incremented listing IDs                                    |
| next-contract-id    | Counter: Auto-incremented contract IDs                                   |

---

## Usage

### Register as Provider

```clojure
(register-as-provider available-space price-per-mb)
```

### Create Storage Listing

```clojure
(create-storage-listing space-mb price-per-block min-blocks max-blocks)
```

### Purchase Storage

```clojure
(purchase-storage listing-id blocks file-hash file-size-mb file-name encryption-key-hash)
```

### Resolve Dispute

```clojure
(resolve-storage-dispute contract-id dispute-type evidence resolution-request)
```

---

## Error Codes

| Code | Meaning                      |
|------|------------------------------|
| 100  | Owner only                   |
| 101  | Not authorized               |
| 102  | Invalid amount               |
| 103  | Provider not found           |
| 104  | Listing not found            |
| 105  | Insufficient funds           |
| 106  | Already registered           |
| 107  | Storage in use               |

---

## Directory Structure

```
/contracts
  DeFiStorage.clar         # Main contract
/README.md                 # Project documentation
/LICENSE                   # License information
```

---

## Contribution

We welcome contributions! Please:

- Fork the repository and create a new branch.
- Write clear, tested code and update documentation as needed.
- Submit a pull request with a detailed description.

For bug reports or feature requests, open an issue with steps to reproduce or your proposal.

---

## License

This project is licensed under the MIT License, a permissive open-source license allowing commercial and private use, modification, and distribution. See the [LICENSE](LICENSE) file for details.

---

## Related Projects

- FSolidM / VeriSolid Solidity Framework
- Smart Contract Examples (ink!)
- SmartContractKit Examples

---

## Acknowledgements

Inspired by decentralized marketplace architectures and best practices in smart contract development.

---

> For questions, suggestions, or security concerns, please open an issue or contact the maintainers.
