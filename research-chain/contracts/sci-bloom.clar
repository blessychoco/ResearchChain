;; ScienceBloom: Decentralized Scientific Research Funding
;; This contract allows researchers to submit proposals and receive funding

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

;; Define proposal statuses
(define-constant STATUS_OPEN u0)
(define-constant STATUS_FUNDED u1)
(define-constant STATUS_CLOSED u2)

;; Define data maps
(define-map proposals
  { proposal-id: uint }
  {
    researcher: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    funding-goal: uint,
    current-funding: uint,
    status: uint
  }
)

(define-map fundings
  { proposal-id: uint, funder: principal }
  { amount: uint }
)

;; Define variables
(define-data-var proposal-counter uint u0)

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
  (or (is-eq status STATUS_OPEN) (is-eq status STATUS_FUNDED) (is-eq status STATUS_CLOSED))
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
          status: STATUS_OPEN
        }
      )
      (var-set proposal-counter proposal-id)
      (ok proposal-id)
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
      (asserts! (is-eq (get status proposal) STATUS_OPEN) ERR_ALREADY_FUNDED)
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