;; supplier-verification.clar
;; This contract validates legitimate vendors in the supply chain

(define-data-var admin principal tx-sender)

;; Map to store verified suppliers
(define-map verified-suppliers principal
  {
    company-name: (string-utf8 100),
    verification-date: uint,
    is-active: bool
  }
)

;; Public function to verify a supplier (only admin can call)
(define-public (verify-supplier (supplier principal) (company-name (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can verify
    (ok (map-set verified-suppliers supplier
      {
        company-name: company-name,
        verification-date: block-height,
        is-active: true
      }
    ))
  )
)

;; Public function to revoke supplier verification
(define-public (revoke-supplier (supplier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can revoke
    (asserts! (is-some (map-get? verified-suppliers supplier)) (err u2)) ;; Supplier must exist
    (ok (map-set verified-suppliers supplier
      (merge (unwrap-panic (map-get? verified-suppliers supplier)) { is-active: false })
    ))
  )
)

;; Read-only function to check if a supplier is verified
(define-read-only (is-verified-supplier (supplier principal))
  (match (map-get? verified-suppliers supplier)
    supplier-data (get is-active supplier-data)
    false
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only current admin can transfer
    (ok (var-set admin new-admin))
  )
)
