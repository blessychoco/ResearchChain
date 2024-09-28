;; ResearchChain: Decentralized Scientific Research Funding
;; This contract allows researchers to submit proposals, reviewers to vote, and funders to support approved projects

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_FUNDED (err u103))
(define-constant ERR_INVALID_TITLE (err u104))
(define-constant ERR_INVALID_DESCRIPTION (err u105))
(define-constant ERR_INVALID_FUNDING_GOAL (err u106))
(define-constant ERR_INVALID_PROPOSAL_ID (err u107))
(define-constant ERR_INVALID_STATUS (err u108))
(define-constant ERR_ALREADY_VOTED (err u109))
(define-constant ERR_NOT_REVIEWER (err u110))
(define-constant ERR_INVALID_REVIEWER (err u111))

;; Define proposal statuses
(define-constant STATUS_SUBMITTED u0)
(define-constant STATUS_UNDER_REVIEW u1)
(define-constant STATUS_APPROVED u2)
(define-constant STATUS_REJECTED u3)
(define-constant STATUS_OPEN u4)
(define-constant STATUS_FUNDED u5)
(define-constant STATUS_CLOSED u6)

;; Define vote options
(define-constant VOTE_APPROVE u1)
(define-constant VOTE_REJECT u0)

;; Define data maps
(define-map proposals
  { proposal-id: uint }
  {
    researcher: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    funding-goal: uint,
    current-funding: uint,
    status: uint,
    approve-votes: uint,
    reject-votes: uint
  }
)

(define-map fundings
  { proposal-id: uint, funder: principal }
  { amount: uint }
)

(define-map reviewers
  { reviewer: principal }
  { is-active: bool }
)

(define-map votes
  { proposal-id: uint, reviewer: principal }
  { vote: uint }
)

;; Define variables
(define-data-var proposal-counter uint u0)
(define-data-var required-votes uint u3)

;; Helper functions for input validation
(define-private (is-valid-title (title (string-ascii 100)))
  (and (> (len title) u0) (<= (len title) u100))
)

(define-private (is-valid-description (description (string-ascii 1000)))
  (and (> (len description) u0) (<= (len description) u1000))
)

(define-private (is-valid-funding-goal (funding-goal uint))
  (> funding-goal u0)
)

(define-private (is-valid-proposal-id (proposal-id uint))
  (<= proposal-id (var-get proposal-counter))
)

(define-private (is-valid-status (status uint))
  (and (>= status STATUS_SUBMITTED) (<= status STATUS_CLOSED))
)

(define-private (is-reviewer (account principal))
  (default-to false (get is-active (map-get? reviewers { reviewer: account })))
)

;; Public functions

;; Submit a new research proposal
(define-public (submit-proposal (title (string-ascii 100)) (description (string-ascii 1000)) (funding-goal uint))
  (begin
    (asserts! (is-valid-title title) ERR_INVALID_TITLE)
    (asserts! (is-valid-description description) ERR_INVALID_DESCRIPTION)
    (asserts! (is-valid-funding-goal funding-goal) ERR_INVALID_FUNDING_GOAL)
    (let
      (
        (proposal-id (+ (var-get proposal-counter) u1))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        {
          researcher: tx-sender,
          title: title,
          description: description,
          funding-goal: funding-goal,
          current-funding: u0,
          status: STATUS_SUBMITTED,
          approve-votes: u0,
          reject-votes: u0
        }
      )
      (var-set proposal-counter proposal-id)
      (ok proposal-id)
    )
  )
)

;; Vote on a proposal (only for reviewers)
(define-public (vote-on-proposal (proposal-id uint) (vote uint))
  (begin
    (asserts! (is-reviewer tx-sender) ERR_NOT_REVIEWER)
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (or (is-eq vote VOTE_APPROVE) (is-eq vote VOTE_REJECT)) ERR_INVALID_STATUS)
    (let
      (
        (proposal (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
        (existing-vote (map-get? votes { proposal-id: proposal-id, reviewer: tx-sender }))
      )
      (asserts! (is-eq (get status proposal) STATUS_UNDER_REVIEW) ERR_INVALID_STATUS)
      (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
      (map-set votes { proposal-id: proposal-id, reviewer: tx-sender } { vote: vote })
      (if (is-eq vote VOTE_APPROVE)
        (map-set proposals { proposal-id: proposal-id }
          (merge proposal { approve-votes: (+ (get approve-votes proposal) u1) }))
        (map-set proposals { proposal-id: proposal-id }
          (merge proposal { reject-votes: (+ (get reject-votes proposal) u1) }))
      )
      (let
        (
          (updated-proposal (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
          (total-votes (+ (get approve-votes updated-proposal) (get reject-votes updated-proposal)))
        )
        (if (>= total-votes (var-get required-votes))
          (if (> (get approve-votes updated-proposal) (get reject-votes updated-proposal))
            (map-set proposals { proposal-id: proposal-id }
              (merge updated-proposal { status: STATUS_APPROVED }))
            (map-set proposals { proposal-id: proposal-id }
              (merge updated-proposal { status: STATUS_REJECTED }))
          )
          true
        )
      )
      (ok true)
    )
  )
)

;; Fund a research proposal
(define-public (fund-proposal (proposal-id uint) (amount uint))
  (begin
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let
      (
        (proposal (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
        (new-funding (+ (get current-funding proposal) amount))
      )
      (asserts! (is-eq (get status proposal) STATUS_OPEN) ERR_INVALID_STATUS)
      (asserts! (<= new-funding (get funding-goal proposal)) ERR_INVALID_AMOUNT)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal {
          current-funding: new-funding,
          status: (if (is-eq new-funding (get funding-goal proposal)) STATUS_FUNDED STATUS_OPEN)
        })
      )
      (map-set fundings
        { proposal-id: proposal-id, funder: tx-sender }
        { amount: (+ amount (default-to u0 (get amount (map-get? fundings { proposal-id: proposal-id, funder: tx-sender })))) }
      )
      (ok true)
    )
  )
)

;; Withdraw funds for a fully funded proposal (only by the researcher)
(define-public (withdraw-funds (proposal-id uint))
  (begin
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (let
      (
        (proposal (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
      )
      (asserts! (is-eq (get researcher proposal) tx-sender) ERR_NOT_AUTHORIZED)
      (asserts! (is-eq (get status proposal) STATUS_FUNDED) ERR_INVALID_STATUS)
      (try! (as-contract (stx-transfer? (get current-funding proposal) tx-sender (get researcher proposal))))
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { current-funding: u0, status: STATUS_CLOSED })
      )
      (ok true)
    )
  )
)

;; Update proposal status (only by CONTRACT_OWNER)
(define-public (update-proposal-status (proposal-id uint) (new-status uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    (let
      (
        (proposal (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { status: new-status })
      )
      (ok true)
    )
  )
)

;; Add a reviewer (only by CONTRACT_OWNER)
(define-public (add-reviewer (reviewer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq reviewer CONTRACT_OWNER)) ERR_INVALID_REVIEWER)
    (map-set reviewers { reviewer: reviewer } { is-active: true })
    (ok true)
  )
)

;; Remove a reviewer (only by CONTRACT_OWNER)
(define-public (remove-reviewer (reviewer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq reviewer CONTRACT_OWNER)) ERR_INVALID_REVIEWER)
    (map-delete reviewers { reviewer: reviewer })
    (ok true)
  )
)

;; Set required votes (only by CONTRACT_OWNER)
(define-public (set-required-votes (new-required-votes uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> new-required-votes u0) ERR_INVALID_AMOUNT)
    (var-set required-votes new-required-votes)
    (ok true)
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get total number of proposals
(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

;; Get funding amount for a specific proposal and funder
(define-read-only (get-funding (proposal-id uint) (funder principal))
  (map-get? fundings { proposal-id: proposal-id, funder: funder })
)

;; Get proposal status
(define-read-only (get-proposal-status (proposal-id uint))
  (get status (unwrap-panic (map-get? proposals { proposal-id: proposal-id })))
)

;; Check if an account is a reviewer
(define-read-only (is-active-reviewer (account principal))
  (is-reviewer account)
)

;; Get required votes
(define-read-only (get-required-votes)
  (var-get required-votes)
)