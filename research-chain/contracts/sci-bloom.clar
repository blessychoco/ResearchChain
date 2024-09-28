;; ScienceBloom: Decentralized Scientific Research Funding
;; This contract allows researchers to submit proposals and receive funding

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_FUNDED (err u103))

;; Define data maps
(define-map proposals
  { proposal-id: uint }
  {
    researcher: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    funding-goal: uint,
    current-funding: uint,
    is-active: bool
  }
)

(define-map fundings
  { proposal-id: uint, funder: principal }
  { amount: uint }
)

;; Define variables
(define-data-var proposal-counter uint u0)

;; Public functions

;; Submit a new research proposal
(define-public (submit-proposal (title (string-ascii 100)) (description (string-ascii 1000)) (funding-goal uint))
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
        is-active: true
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Fund a research proposal
(define-public (fund-proposal (proposal-id uint) (amount uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err ERR_PROPOSAL_NOT_FOUND)))
      (new-funding (+ (get current-funding proposal) amount))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (get is-active proposal) ERR_ALREADY_FUNDED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { current-funding: new-funding, is-active: (< new-funding (get funding-goal proposal)) })
    )
    (map-set fundings
      { proposal-id: proposal-id, funder: tx-sender }
      { amount: (default-to u0 (get amount (map-get? fundings { proposal-id: proposal-id, funder: tx-sender }))) }
    )
    (ok true)
  )
)

;; Withdraw funds for a fully funded proposal (only by the researcher)
(define-public (withdraw-funds (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err ERR_PROPOSAL_NOT_FOUND)))
    )
    (asserts! (is-eq (get researcher proposal) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (>= (get current-funding proposal) (get funding-goal proposal)) ERR_INVALID_AMOUNT)
    (try! (as-contract (stx-transfer? (get current-funding proposal) tx-sender (get researcher proposal))))
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { current-funding: u0, is-active: false })
    )
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