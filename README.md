# BitCast Protocol

**Decentralized Bitcoin Price Prediction Market on Stacks**

BitCast is a trustless prediction market protocol that enables users to stake STX tokens on Bitcoin price movements, creating a transparent and automated betting system with oracle-driven settlements.

## 🚀 Features

- **Oracle-Driven Settlement**: Trustless price resolution using verified Bitcoin price feeds
- **Proportional Payouts**: Fair distribution based on winning stake ratios
- **Multi-Market Support**: Create unlimited prediction markets with unique parameters
- **Automated STX Handling**: Seamless token transfers and balance management
- **Configurable Parameters**: Adjustable fees, minimum stakes, and oracle addresses
- **Administrative Controls**: Protocol governance and fee collection mechanisms

## 📊 System Overview

BitCast operates as a decentralized prediction market where users can:

1. **Create Markets**: Administrators set up time-bound Bitcoin price prediction markets
2. **Place Predictions**: Users stake STX tokens on "up" or "down" price movements
3. **Oracle Resolution**: Trusted oracles provide final Bitcoin prices for settlement
4. **Claim Winnings**: Winners automatically receive proportional payouts minus protocol fees

### Market Lifecycle

```
Market Creation → Prediction Period → Market Close → Oracle Resolution → Payout Distribution
```

## 🏗️ Contract Architecture

### Core Components

#### **Data Structures**

- `markets`: Stores market parameters, stakes, and resolution status
- `user-predictions`: Tracks individual user positions and claim status

#### **State Variables**

- `oracle-address`: Trusted price feed source
- `minimum-stake`: Minimum STX required for predictions
- `fee-percentage`: Protocol fee (default 2%)
- `market-counter`: Sequential market ID generator

#### **Access Control**

- Contract Owner: Market creation, parameter updates, fee withdrawal
- Oracle Address: Market resolution authority
- Users: Prediction placement and winnings claims

### Function Categories

#### **Market Operations**

- `create-market`: Initialize new prediction markets
- `make-prediction`: Place STX stakes on price direction
- `resolve-market`: Oracle-driven settlement
- `claim-winnings`: Automated payout distribution

#### **Data Access**

- `get-market`: Market information retrieval
- `get-user-prediction`: User position details
- `get-contract-balance`: Protocol STX holdings
- `get-protocol-config`: Current system parameters

#### **Administration**

- `set-oracle-address`: Update price feed source
- `set-minimum-stake`: Configure minimum position size
- `set-fee-percentage`: Adjust protocol fees
- `withdraw-fees`: Extract protocol revenue

## 🔄 Data Flow

### Prediction Flow

```
User → make-prediction() → STX Transfer → Position Recording → Market Update
```

### Settlement Flow

```
Oracle → resolve-market() → Price Verification → Market Resolution → Enable Claims
```

### Payout Flow

```
Winner → claim-winnings() → Calculation → Fee Deduction → STX Transfer → Position Update
```

### Payout Calculation

```
Individual Winnings = (User Stake × Total Pool) ÷ Winning Side Total
Final Payout = Individual Winnings - Protocol Fee
```

## 🛠️ Technical Specifications

### Market Parameters

- **Start Price**: Initial BTC/USD price in satoshis
- **End Price**: Final BTC/USD price for settlement
- **Block Range**: Stacks block heights defining market duration
- **Stake Totals**: Aggregate STX amounts for each prediction side

### Error Handling

- `ERR-OWNER-ONLY` (100): Unauthorized administrative access
- `ERR-NOT-FOUND` (101): Invalid market or prediction lookup
- `ERR-INVALID-PREDICTION` (102): Invalid prediction parameters
- `ERR-MARKET-CLOSED` (103): Operations on inactive markets
- `ERR-INSUFFICIENT-BALANCE` (105): Inadequate STX balance
- `ERR-MARKET-ENDED` (108): Late prediction attempts

## 📈 Economic Model

### Fee Structure

- **Protocol Fee**: 2% of winnings (configurable)
- **Minimum Stake**: 1 STX (configurable)
- **Fee Distribution**: Collected by contract owner

### Risk Management

- **Balance Verification**: Ensures user has sufficient STX
- **Market Timing**: Prevents predictions outside active periods
- **Duplicate Claims**: Prevents multiple payout attempts
- **Oracle Validation**: Restricts resolution to authorized addresses

## 🔐 Security Features

### Access Control

- **Owner-Only Functions**: Critical administrative operations
- **Oracle Authority**: Exclusive settlement permissions
- **Input Validation**: Comprehensive parameter checking

### State Protection

- **Claim Prevention**: Blocks duplicate reward claims
- **Market Integrity**: Prevents post-resolution modifications
- **Balance Safeguards**: Ensures adequate contract liquidity

## 🚀 Deployment Guide

### Prerequisites

- Stacks blockchain node access
- Clarinet development environment
- STX tokens for testing and operation

### Configuration

1. Set oracle address for price feeds
2. Configure minimum stake requirements
3. Adjust protocol fee percentage
4. Initialize market counter

### Testing

- Unit tests for all public functions
- Integration tests for complete market cycles
- Security audits for access control mechanisms

## 📝 Usage Examples

### Creating a Market

```clarity
(create-market u6000000000 u1000 u2000) ;; BTC at $60k, blocks 1000-2000
```

### Placing Predictions

```clarity
(make-prediction u0 "up" u5000000) ;; Market 0, bullish, 5 STX stake
```

### Claiming Winnings

```clarity
(claim-winnings u0) ;; Claim from market 0
```

## 🤝 Contributing

BitCast Protocol welcomes contributions from the Stacks community. Please ensure all submissions include comprehensive tests and follow the established coding standards.
