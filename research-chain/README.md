# ResearchChain Smart Contract

## Overview

ResearchChain is a decentralized scientific research funding platform implemented as a smart contract on the Stacks blockchain. It allows researchers to submit proposals, reviewers to evaluate them, and funders to support approved projects. The contract also includes a refund mechanism for certain scenarios.

## Features

- Proposal submission by researchers
- Review and voting system for quality control
- Funding mechanism for approved proposals
- Withdrawal process for funded projects
- Refund mechanism for eligible proposals
- Role-based access control (researchers, reviewers, funders, contract owner)
- Configurable voting and funding parameters

## Contract Structure

The contract consists of several key components:

1. **Proposals**: Researchers can submit proposals for funding.
2. **Review Process**: Authorized reviewers can vote on proposals.
3. **Funding**: Approved proposals can receive funding from supporters.
4. **Withdrawal**: Researchers can withdraw funds once their proposal is fully funded.
5. **Refunds**: Funders can request refunds under certain conditions.

## Proposal Lifecycle

1. **Submitted**: A researcher submits a new proposal.
2. **Under Review**: The contract owner moves the proposal to the review phase.
3. **Approved/Rejected**: Based on reviewer votes, the proposal is either approved or rejected.
4. **Open for Funding**: Approved proposals can be opened for funding by the contract owner.
5. **Funded**: The proposal reaches its funding goal.
6. **Closed**: The researcher withdraws the funds, and the proposal is closed.
7. **Refundable**: If a proposal doesn't meet its funding goal within the deadline or is closed, it becomes eligible for refunds.

## Key Functions

### For Researchers

- `submit-proposal`: Submit a new research proposal.
- `withdraw-funds`: Withdraw funds for a fully funded proposal.

### For Reviewers

- `vote-on-proposal`: Vote to approve or reject a proposal under review.

### For Funders

- `fund-proposal`: Contribute funds to an approved and open proposal.
- `request-refund`: Request a refund for an eligible proposal.

### For Contract Owner

- `update-proposal-status`: Update the status of a proposal.
- `add-reviewer`: Add a new reviewer to the system.
- `remove-reviewer`: Remove a reviewer from the system.
- `set-required-votes`: Set the number of votes required for a proposal decision.
- `set-funding-period`: Set the funding period for proposals.

## How to Use

1. **Submitting a Proposal**:
   Researchers call `submit-proposal` with their proposal details.

2. **Reviewing a Proposal**:
   - The contract owner updates the proposal status to "Under Review".
   - Authorized reviewers call `vote-on-proposal` to cast their votes.
   - Once the required number of votes is reached, the proposal is automatically approved or rejected.

3. **Funding a Proposal**:
   - The contract owner updates approved proposals to "Open" status.
   - Funders can call `fund-proposal` to contribute to open proposals.

4. **Withdrawing Funds**:
   Once a proposal is fully funded, the researcher can call `withdraw-funds` to receive the funds.

5. **Requesting Refunds**:
   If a proposal doesn't meet its funding goal within the deadline or is closed, funders can call `request-refund` to get their contributions back.

## Error Codes

- `ERR_NOT_AUTHORIZED (u100)`: User not authorized for the action.
- `ERR_INVALID_AMOUNT (u101)`: Invalid amount specified.
- `ERR_PROPOSAL_NOT_FOUND (u102)`: Proposal ID not found.
- `ERR_ALREADY_FUNDED (u103)`: Proposal already fully funded.
- `ERR_INVALID_TITLE (u104)`: Invalid proposal title.
- `ERR_INVALID_DESCRIPTION (u105)`: Invalid proposal description.
- `ERR_INVALID_FUNDING_GOAL (u106)`: Invalid funding goal.
- `ERR_INVALID_PROPOSAL_ID (u107)`: Invalid proposal ID.
- `ERR_INVALID_STATUS (u108)`: Invalid proposal status.
- `ERR_ALREADY_VOTED (u109)`: Reviewer has already voted on the proposal.
- `ERR_NOT_REVIEWER (u110)`: User is not an authorized reviewer.
- `ERR_INVALID_REVIEWER (u111)`: Invalid reviewer specified.
- `ERR_NOT_FUNDER (u112)`: User is not a funder of the proposal.
- `ERR_REFUND_NOT_AVAILABLE (u113)`: Refund is not available for the proposal.

## Security Considerations

- Only the contract owner can add or remove reviewers and update proposal statuses.
- Reviewers can only vote once per proposal.
- Funds are locked in the contract until the proposal is fully funded and the researcher withdraws them, or until a refund is requested.
- Input validation is performed on all public functions to ensure data integrity.
- The contract uses a deadline mechanism to determine when proposals become eligible for refunds.

## Read-Only Functions

- `get-proposal`: Retrieve details of a specific proposal.
- `get-proposal-count`: Get the total number of proposals.
- `get-funding`: Get the funding amount for a specific proposal and funder.
- `get-proposal-status`: Retrieve the status of a specific proposal.
- `is-active-reviewer`: Check if an account is an active reviewer.
- `get-required-votes`: Get the current number of required votes for proposal decisions.
- `get-funding-period`: Get the current funding period for proposals.
- `check-refund-eligibility`: Check if a proposal is eligible for refunds.

## Disclaimer

This smart contract is provided as-is. Users should review and understand the code before interacting with it on the blockchain. Always test thoroughly on a testnet before deploying to mainnet.

## Author

Blessing Eze