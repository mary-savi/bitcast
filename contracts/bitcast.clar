;; BitCast - Decentralized Bitcoin Price Prediction Market
;;
;; Title: BitCast Protocol - On-Chain Bitcoin Price Predictions
;;
;; Summary: A trustless prediction market protocol built on Stacks that enables 
;; users to stake STX tokens on Bitcoin price movements, creating a decentralized 
;; oracle-driven betting system with automated payouts and transparent settlement.
;;
;; Description: BitCast transforms Bitcoin price speculation into a fair, 
;; transparent, and decentralized prediction market. Users can create time-bound 
;; markets predicting whether Bitcoin will go "up" or "down" from a starting price, 
;; stake STX tokens on their predictions, and automatically claim winnings based 
;; on oracle-verified settlement prices. The protocol features configurable 
;; parameters, fee collection, and robust market lifecycle management, making it 
;; the premier destination for Bitcoin price discovery and speculation on Stacks L2.
;;
;; Key Features:
;; - Oracle-driven price settlements for trustless resolution
;; - Proportional payout system based on winning stake distribution
;; - Configurable market parameters and fee structures
;; - Multi-market support with sequential ID management
;; - Automated STX token handling and balance verification
;; - Administrative controls for protocol governance

;; CONSTANTS & ERROR CODES

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PREDICTION (err u102))
(define-constant ERR-MARKET-CLOSED (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-PARAMETER (err u106))
(define-constant ERR-MARKET-NOT-STARTED (err u107))
(define-constant ERR-MARKET-ENDED (err u108))
(define-constant ERR-MARKET-ALREADY-RESOLVED (err u109))

;; PROTOCOL CONFIGURATION

(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum
(define-data-var fee-percentage uint u2) ;; 2% protocol fee
(define-data-var market-counter uint u0)

;; DATA STRUCTURES

;; Market Definition: Bitcoin Price Prediction Markets
(define-map markets
  uint ;; market-id
  {
    start-price: uint, ;; Initial BTC/USD price in sats
    end-price: uint, ;; Final BTC/USD price in sats
    total-up-stake: uint, ;; Total STX staked on price increase
    total-down-stake: uint, ;; Total STX staked on price decrease
    start-block: uint, ;; Market opening block height
    end-block: uint, ;; Market closing block height
    resolved: bool, ;; Settlement status flag
  }
)

;; User Position Tracking
(define-map user-predictions
  {
    market-id: uint,
    user: principal,
  }
  {
    prediction: (string-ascii 4), ;; "up" or "down"
    stake: uint, ;; STX amount staked
    claimed: bool, ;; Reward claim status
  }
)

;; CORE MARKET OPERATIONS

;; Create New Bitcoin Price Prediction Market
(define-public (create-market
    (start-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> end-block start-block) ERR-INVALID-PARAMETER)
    (asserts! (> start-price u0) ERR-INVALID-PARAMETER)
    (map-set markets market-id {
      start-price: start-price,
      end-price: u0,
      total-up-stake: u0,
      total-down-stake: u0,
      start-block: start-block,
      end-block: end-block,
      resolved: false,
    })
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Place Bitcoin Price Prediction
(define-public (make-prediction
    (market-id uint)
    (prediction (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (current-block-height stacks-block-height)
    )
    ;; Validate market timing
    (asserts!
      (and
        (>= current-block-height (get start-block market))
        (< current-block-height (get end-block market))
      )
      ERR-MARKET-ENDED
    )
    ;; Validate prediction parameters
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down"))
      ERR-INVALID-PREDICTION
    )
    (asserts! (>= stake (var-get minimum-stake)) ERR-INVALID-PARAMETER)
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR-INSUFFICIENT-BALANCE)
    ;; Transfer STX to contract
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    ;; Record user prediction
    (map-set user-predictions {
      market-id: market-id,
      user: tx-sender,
    } {
      prediction: prediction,
      stake: stake,
      claimed: false,
    })
    ;; Update market stake totals
    (map-set markets market-id
      (merge market {
        total-up-stake: (if (is-eq prediction "up")
          (+ (get total-up-stake market) stake)
          (get total-up-stake market)
        ),
        total-down-stake: (if (is-eq prediction "down")
          (+ (get total-down-stake market) stake)
          (get total-down-stake market)
        ),
      })
    )
    (ok true)
  )
)

;; Resolve Market with Oracle Price
(define-public (resolve-market
    (market-id uint)
    (end-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-OWNER-ONLY)
    (asserts! (>= stacks-block-height (get end-block market)) ERR-MARKET-ENDED)
    (asserts! (not (get resolved market)) ERR-MARKET-ALREADY-RESOLVED)
    (asserts! (> end-price u0) ERR-INVALID-PARAMETER)
    (map-set markets market-id
      (merge market {
        end-price: end-price,
        resolved: true,
      })
    )
    (ok true)
  )
)

;; Claim Prediction Winnings
(define-public (claim-winnings (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (prediction (unwrap!
        (map-get? user-predictions {
          market-id: market-id,
          user: tx-sender,
        })
        ERR-NOT-FOUND
      ))
    )
    (asserts! (get resolved market) ERR-MARKET-CLOSED)
    (asserts! (not (get claimed prediction)) ERR-ALREADY-CLAIMED)
    (let (
        (winning-prediction (if (> (get end-price market) (get start-price market))
          "up"
          "down"
        ))
        (total-stake (+ (get total-up-stake market) (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up")
          (get total-up-stake market)
          (get total-down-stake market)
        ))
      )
      (asserts! (is-eq (get prediction prediction) winning-prediction)
        ERR-INVALID-PREDICTION
      )
      (let (
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        ;; Transfer winnings to user
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) tx-sender)))
        ;; Transfer fees to contract owner
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) CONTRACT-OWNER)))
        ;; Mark as claimed
        (map-set user-predictions {
          market-id: market-id,
          user: tx-sender,
        }
          (merge prediction { claimed: true })
        )
        (ok payout)
      )
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get Market Information
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

;; Get User Prediction Details
(define-read-only (get-user-prediction
    (market-id uint)
    (user principal)
  )
  (map-get? user-predictions {
    market-id: market-id,
    user: user,
  })
)

;; Get Contract Balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Get Current Market Counter
(define-read-only (get-market-counter)
  (var-get market-counter)
)