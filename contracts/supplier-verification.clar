;; early-payment.clar
;; This contract manages discounted accelerated settlements

(define-data-var admin principal tx-sender)

;; Map to store early payment offers
(define-map early-payment-offers (tuple (invoice-id uint) (supplier principal) (buyer principal))
  {
    discount-percentage: uint, ;; Represented as basis points (e.g., 500 = 5%)
    offer-expiry: uint,        ;; Block height when offer expires
    is-active: bool
  }
)

;; Map to store completed early payments
(define-map early-payments (tuple (invoice-id uint) (supplier principal) (buyer principal))
  {
    original-amount: uint,
    paid-amount: uint,
    payment-date: uint
  }
)

;; Public function to create an early payment offer
(define-public (create-early-payment-offer
    (invoice-id uint)
    (supplier principal)
    (buyer principal)
    (discount-percentage uint)
    (offer-expiry uint))
  (begin
    (asserts! (is-eq tx-sender supplier) (err u1)) ;; Only supplier can create offer
    (asserts! (<= discount-percentage u10000) (err u2)) ;; Max 100% discount (10000 basis points)
    (ok (map-set early-payment-offers (tuple (invoice-id invoice-id) (supplier supplier) (buyer buyer))
      {
        discount-percentage: discount-percentage,
        offer-expiry: offer-expiry,
        is-active: true
      }
    ))
  )
)

;; Public function to accept an early payment offer
;; Note: In a real implementation, this would integrate with a token contract for actual payment
(define-public (accept-early-payment-offer
    (invoice-id uint)
    (supplier principal)
    (original-amount uint))
  (let (
      (offer-key (tuple (invoice-id invoice-id) (supplier supplier) (buyer tx-sender)))
      (offer (map-get? early-payment-offers offer-key))
    )
    (begin
      (asserts! (is-some offer) (err u1)) ;; Offer must exist
      (asserts! (get is-active (unwrap-panic offer)) (err u2)) ;; Offer must be active
      (asserts! (<= block-height (get offer-expiry (unwrap-panic offer))) (err u3)) ;; Offer must not be expired

      ;; Calculate discounted amount
      (let ((discount-amount (/ (* original-amount (get discount-percentage (unwrap-panic offer))) u10000))
            (paid-amount (- original-amount discount-amount)))

        ;; Record the payment
        (map-set early-payments offer-key
          {
            original-amount: original-amount,
            paid-amount: paid-amount,
            payment-date: block-height
          }
        )

        ;; Deactivate the offer
        (map-set early-payment-offers offer-key
          (merge (unwrap-panic offer) { is-active: false })
        )

        ;; Return the paid amount
        (ok paid-amount)
      )
    )
  )
)

;; Read-only function to get early payment offer details
(define-read-only (get-early-payment-offer (invoice-id uint) (supplier principal) (buyer principal))
  (map-get? early-payment-offers (tuple (invoice-id invoice-id) (supplier supplier) (buyer buyer)))
)

;; Read-only function to get early payment details
(define-read-only (get-early-payment (invoice-id uint) (supplier principal) (buyer principal))
  (map-get? early-payments (tuple (invoice-id invoice-id) (supplier supplier) (buyer buyer)))
)
