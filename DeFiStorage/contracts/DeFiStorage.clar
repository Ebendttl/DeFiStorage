;; DeFi File Storage Marketplace
;; This contract implements a decentralized marketplace for file storage services
;; where providers can offer storage space and users can purchase storage for their files.
;; The contract handles payments, service agreements, and dispute resolution.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-provider-not-found (err u103))
(define-constant err-listing-not-found (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-already-registered (err u106))
(define-constant err-storage-in-use (err u107))

;; platform fee percentage (0.5%)
(define-constant platform-fee-rate u5)
(define-constant fee-denominator u1000)

;; minimum storage period in blocks (approximately 1 month)
(define-constant min-storage-period u4320)

;; data maps and vars
;; track registered storage providers
(define-map storage-providers
  { provider: principal }
  {
    available-space: uint,  ;; in megabytes
    price-per-mb: uint,     ;; in microSTX per MB per block
    reputation-score: uint, ;; score from 0-100
    total-completed: uint,  ;; total completed storage contracts
    active: bool            ;; whether provider is currently active
  }
)

;; track storage listings
(define-map storage-listings
  { listing-id: uint }
  {
    provider: principal,
    space-mb: uint,
    price-per-block: uint,
    min-blocks: uint,
    max-blocks: uint,
    available: bool
  }
)

;; track active storage contracts
(define-map storage-contracts
  { contract-id: uint }
  {
    provider: principal,
    user: principal,
    listing-id: uint,
    space-mb: uint,
    price-per-block: uint,
    start-block: uint,
    end-block: uint,
    total-payment: uint,
    status: (string-ascii 20) ;; "active", "completed", "disputed"
  }
)

;; track file metadata (hash references)
(define-map file-metadata
  { contract-id: uint, file-id: uint }
  {
    file-hash: (buff 32),
    file-size-mb: uint,
    file-name: (string-ascii 64),
    encryption-key-hash: (buff 32)
  }
)

;; counters for IDs
(define-data-var next-listing-id uint u1)
(define-data-var next-contract-id uint u1)

;; private functions
(define-private (calculate-platform-fee (amount uint))
  (/ (* amount platform-fee-rate) fee-denominator)
)

(define-private (transfer-stx (amount uint) (sender principal) (recipient principal))
  (stx-transfer? amount sender recipient)
)

(define-private (is-provider-registered (provider principal))
  (default-to false (get active (map-get? storage-providers { provider: provider })))
)

(define-private (validate-storage-period (blocks uint))
  (>= blocks min-storage-period)
)

;; public functions
(define-public (register-as-provider (available-space uint) (price-per-mb uint))
  (let ((provider tx-sender))
    (asserts! (not (is-provider-registered provider)) err-already-registered)
    (asserts! (> available-space u0) err-invalid-amount)
    (asserts! (> price-per-mb u0) err-invalid-amount)
    
    (map-set storage-providers
      { provider: provider }
      {
        available-space: available-space,
        price-per-mb: price-per-mb,
        reputation-score: u80,  ;; default starting score
        total-completed: u0,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-provider-details (available-space uint) (price-per-mb uint) (active bool))
  (let ((provider tx-sender))
    (asserts! (is-provider-registered provider) err-provider-not-found)
    (asserts! (> available-space u0) err-invalid-amount)
    (asserts! (> price-per-mb u0) err-invalid-amount)
    
    (map-set storage-providers
      { provider: provider }
      (merge (default-to 
        {
          available-space: u0,
          price-per-mb: u0,
          reputation-score: u0,
          total-completed: u0,
          active: false
        }
        (map-get? storage-providers { provider: provider }))
        {
          available-space: available-space,
          price-per-mb: price-per-mb,
          active: active
        }
      )
    )
    (ok true)
  )
)

(define-public (create-storage-listing (space-mb uint) (price-per-block uint) (min-blocks uint) (max-blocks uint))
  (let (
    (provider tx-sender)
    (listing-id (var-get next-listing-id))
    (provider-info (default-to 
      { available-space: u0, price-per-mb: u0, reputation-score: u0, total-completed: u0, active: false }
      (map-get? storage-providers { provider: provider })))
  )
    ;; validate provider and parameters
    (asserts! (is-provider-registered provider) err-provider-not-found)
    (asserts! (>= (get available-space provider-info) space-mb) err-invalid-amount)
    (asserts! (> price-per-block u0) err-invalid-amount)
    (asserts! (validate-storage-period min-blocks) err-invalid-amount)
    (asserts! (>= max-blocks min-blocks) err-invalid-amount)
    
    ;; create the listing
    (map-set storage-listings
      { listing-id: listing-id }
      {
        provider: provider,
        space-mb: space-mb,
        price-per-block: price-per-block,
        min-blocks: min-blocks,
        max-blocks: max-blocks,
        available: true
      }
    )
    
    ;; increment the listing ID counter
    (var-set next-listing-id (+ listing-id u1))
    
    (ok listing-id)
  )
)

;; This function allows users to purchase storage from a provider's listing
;; It handles payment, creates a storage contract, and updates provider's available space
(define-public (purchase-storage (listing-id uint) (blocks uint) (file-hash (buff 32)) (file-size-mb uint) (file-name (string-ascii 64)) (encryption-key-hash (buff 32)))
  (let (
    (user tx-sender)
    (listing (unwrap! (map-get? storage-listings { listing-id: listing-id }) err-listing-not-found))
    (provider (get provider listing))
    (space-mb (get space-mb listing))
    (price-per-block (get price-per-block listing))
    (min-blocks (get min-blocks listing))
    (max-blocks (get max-blocks listing))
    (available (get available listing))
    (total-cost (* price-per-block blocks))
    (platform-fee (calculate-platform-fee total-cost))
    (provider-payment (- total-cost platform-fee))
    (contract-id (var-get next-contract-id))
  )
    ;; validate the purchase
    (asserts! available err-listing-not-found)
    (asserts! (>= blocks min-blocks) err-invalid-amount)
    (asserts! (<= blocks max-blocks) err-invalid-amount)
    (asserts! (<= file-size-mb space-mb) err-invalid-amount)
    
    ;; process payment - using try! for response types
    (try! (stx-transfer? total-cost user contract-owner))
    (try! (stx-transfer? provider-payment contract-owner provider))
    
    ;; create storage contract
    (map-set storage-contracts
      { contract-id: contract-id }
      {
        provider: provider,
        user: user,
        listing-id: listing-id,
        space-mb: space-mb,
        price-per-block: price-per-block,
        start-block: block-height,
        end-block: (+ block-height blocks),
        total-payment: total-cost,
        status: "active"
      }
    )
    
    ;; store file metadata
    (map-set file-metadata
      { contract-id: contract-id, file-id: u1 }
      {
        file-hash: file-hash,
        file-size-mb: file-size-mb,
        file-name: file-name,
        encryption-key-hash: encryption-key-hash
      }
    )
    
    ;; update provider's available space
    (map-set storage-providers
      { provider: provider }
      (merge (default-to 
        { available-space: u0, price-per-mb: u0, reputation-score: u0, total-completed: u0, active: false }
        (map-get? storage-providers { provider: provider }))
        { available-space: (- (get available-space (unwrap! (map-get? storage-providers { provider: provider }) err-provider-not-found)) space-mb) }
      )
    )
    
    ;; update listing availability if all space is used
    (map-set storage-listings
      { listing-id: listing-id }
      (merge listing { available: false })
    )
    
    ;; increment contract ID
    (var-set next-contract-id (+ contract-id u1))
    
    (ok contract-id)
  )
)

