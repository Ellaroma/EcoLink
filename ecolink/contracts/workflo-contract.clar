;; Environmental Conservation Network Contract
;; A system for environmentalists to track initiatives, share research, and build coalitions

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CONSERVATIONIST-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENDORSED (err u102))
(define-constant ERR-INVALID-PRIVACY-LEVEL (err u103))
(define-constant ERR-PUBLICATION-NOT-FOUND (err u104))

;; Privacy levels
(define-constant PRIVACY-PUBLIC u0)
(define-constant PRIVACY-CONSERVATION-NETWORK u1)
(define-constant PRIVACY-PRIVATE u2)

;; Data structures
(define-map conservationist-profiles
  principal
  {
    conservationist-name: (string-ascii 50),
    bio: (string-ascii 500),
    focus-areas: (string-ascii 200),
    privacy-level: uint,
    joined-at: uint,
    is-verified: bool
  })

(define-map environmental-projects
  { conservationist: principal, project-id: uint }
  {
    project-name: (string-ascii 100),
    ecosystem-type: (string-ascii 100),
    start-date: uint,
    target-completion: (optional uint),
    project-description: (string-ascii 500),
    privacy-level: uint
  })

(define-map research-publications
  { conservationist: principal, publication-id: uint }
  {
    research-title: (string-ascii 100),
    journal-name: (string-ascii 100),
    publication-date: uint,
    doi-number: (optional uint),
    research-url: (string-ascii 200),
    privacy-level: uint,
    is-verified: bool
  })

(define-map impact-endorsements
  { endorser: principal, endorsee: principal, impact-area: (string-ascii 50) }
  {
    impact-statement: (string-ascii 200),
    timestamp: uint,
    is-public: bool
  })

(define-map conservation-connections
  { conservationist1: principal, conservationist2: principal }
  {
    status: (string-ascii 20), ;; "pending", "accepted", "blocked"
    initiated-by: principal,
    timestamp: uint
  })

;; Counters for unique IDs
(define-data-var project-id-counter uint u0)
(define-data-var publication-id-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Conservationist profile management functions
(define-public (create-conservationist-profile (conservationist-name (string-ascii 50)) (bio (string-ascii 500)) (focus-areas (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (ok (map-set conservationist-profiles tx-sender {
      conservationist-name: conservationist-name,
      bio: bio,
      focus-areas: focus-areas,
      privacy-level: privacy-level,
      joined-at: block-height,
      is-verified: false
    }))))

(define-public (update-conservationist-profile (conservationist-name (string-ascii 50)) (bio (string-ascii 500)) (focus-areas (string-ascii 200)) (privacy-level uint))
  (begin
    (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
    (asserts! (is-some (map-get? conservationist-profiles tx-sender)) ERR-CONSERVATIONIST-NOT-FOUND)
    (ok (map-set conservationist-profiles tx-sender {
      conservationist-name: conservationist-name,
      bio: bio,
      focus-areas: focus-areas,
      privacy-level: privacy-level,
      joined-at: (default-to block-height (get joined-at (map-get? conservationist-profiles tx-sender))),
      is-verified: (default-to false (get is-verified (map-get? conservationist-profiles tx-sender)))
    }))))

;; Environmental project functions
(define-public (add-environmental-project (project-name (string-ascii 100)) (ecosystem-type (string-ascii 100)) (start-date uint) (target-completion (optional uint)) (project-description (string-ascii 500)) (privacy-level uint))
  (let ((project-id (+ (var-get project-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? conservationist-profiles tx-sender)) ERR-CONSERVATIONIST-NOT-FOUND)
      (var-set project-id-counter project-id)
      (ok (map-set environmental-projects { conservationist: tx-sender, project-id: project-id } {
        project-name: project-name,
        ecosystem-type: ecosystem-type,
        start-date: start-date,
        target-completion: target-completion,
        project-description: project-description,
        privacy-level: privacy-level
      })))))

;; Research publication functions
(define-public (add-research-publication (research-title (string-ascii 100)) (journal-name (string-ascii 100)) (publication-date uint) (doi-number (optional uint)) (research-url (string-ascii 200)) (privacy-level uint))
  (let ((publication-id (+ (var-get publication-id-counter) u1)))
    (begin
      (asserts! (<= privacy-level PRIVACY-PRIVATE) ERR-INVALID-PRIVACY-LEVEL)
      (asserts! (is-some (map-get? conservationist-profiles tx-sender)) ERR-CONSERVATIONIST-NOT-FOUND)
      (var-set publication-id-counter publication-id)
      (ok (map-set research-publications { conservationist: tx-sender, publication-id: publication-id } {
        research-title: research-title,
        journal-name: journal-name,
        publication-date: publication-date,
        doi-number: doi-number,
        research-url: research-url,
        privacy-level: privacy-level,
        is-verified: false
      })))))

(define-public (verify-research-publication (conservationist principal) (publication-id uint))
  (let ((publication (map-get? research-publications { conservationist: conservationist, publication-id: publication-id })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some publication) ERR-PUBLICATION-NOT-FOUND)
      (ok (map-set research-publications { conservationist: conservationist, publication-id: publication-id }
        (merge (unwrap-panic publication) { is-verified: true }))))))

;; Impact endorsement functions
(define-public (endorse-environmental-impact (endorsee principal) (impact-area (string-ascii 50)) (impact-statement (string-ascii 200)) (is-public bool))
  (begin
    (asserts! (is-some (map-get? conservationist-profiles tx-sender)) ERR-CONSERVATIONIST-NOT-FOUND)
    (asserts! (is-some (map-get? conservationist-profiles endorsee)) ERR-CONSERVATIONIST-NOT-FOUND)
    (asserts! (is-none (map-get? impact-endorsements { endorser: tx-sender, endorsee: endorsee, impact-area: impact-area })) ERR-ALREADY-ENDORSED)
    (ok (map-set impact-endorsements { endorser: tx-sender, endorsee: endorsee, impact-area: impact-area } {
      impact-statement: impact-statement,
      timestamp: block-height,
      is-public: is-public
    }))))

;; Conservation connection functions
(define-public (send-conservation-coalition-invite (to-conservationist principal))
  (begin
    (asserts! (is-some (map-get? conservationist-profiles tx-sender)) ERR-CONSERVATIONIST-NOT-FOUND)
    (asserts! (is-some (map-get? conservationist-profiles to-conservationist)) ERR-CONSERVATIONIST-NOT-FOUND)
    (ok (map-set conservation-connections { conservationist1: tx-sender, conservationist2: to-conservationist } {
      status: "pending",
      initiated-by: tx-sender,
      timestamp: block-height
    }))))

(define-public (accept-conservation-coalition-invite (from-conservationist principal))
  (let ((connection (map-get? conservation-connections { conservationist1: from-conservationist, conservationist2: tx-sender })))
    (begin
      (asserts! (is-some connection) ERR-CONSERVATIONIST-NOT-FOUND)
      (asserts! (is-eq (get status (unwrap-panic connection)) "pending") ERR-NOT-AUTHORIZED)
      (ok (map-set conservation-connections { conservationist1: from-conservationist, conservationist2: tx-sender }
        (merge (unwrap-panic connection) { status: "accepted" }))))))

;; Read-only functions with privacy controls
(define-read-only (get-conservationist-profile (conservationist principal))
  (let ((profile (map-get? conservationist-profiles conservationist)))
    (if (is-some profile)
      (let ((profile-data (unwrap-panic profile)))
        (if (or (is-eq (get privacy-level profile-data) PRIVACY-PUBLIC)
                (is-eq conservationist tx-sender)
                (is-conservation-connected conservationist tx-sender))
          profile
          none))
      none)))

(define-read-only (get-environmental-project (conservationist principal) (project-id uint))
  (let ((project (map-get? environmental-projects { conservationist: conservationist, project-id: project-id })))
    (if (is-some project)
      (let ((project-data (unwrap-panic project)))
        (if (can-view-conservation-data conservationist (get privacy-level project-data))
          project
          none))
      none)))

(define-read-only (get-research-publication (conservationist principal) (publication-id uint))
  (let ((publication (map-get? research-publications { conservationist: conservationist, publication-id: publication-id })))
    (if (is-some publication)
      (let ((publication-data (unwrap-panic publication)))
        (if (can-view-conservation-data conservationist (get privacy-level publication-data))
          publication
          none))
      none)))

(define-read-only (get-impact-endorsement (endorser principal) (endorsee principal) (impact-area (string-ascii 50)))
  (let ((endorsement (map-get? impact-endorsements { endorser: endorser, endorsee: endorsee, impact-area: impact-area })))
    (if (is-some endorsement)
      (let ((endorsement-data (unwrap-panic endorsement)))
        (if (or (get is-public endorsement-data)
                (is-eq endorsee tx-sender)
                (is-conservation-connected endorsee tx-sender))
          endorsement
          none))
      none)))

;; Helper functions
(define-read-only (is-conservation-connected (conservationist1 principal) (conservationist2 principal))
  (or (is-eq (get status (default-to { status: "none", initiated-by: conservationist1, timestamp: u0 } 
                          (map-get? conservation-connections { conservationist1: conservationist1, conservationist2: conservationist2 }))) "accepted")
      (is-eq (get status (default-to { status: "none", initiated-by: conservationist2, timestamp: u0 } 
                          (map-get? conservation-connections { conservationist1: conservationist2, conservationist2: conservationist1 }))) "accepted")))

(define-read-only (can-view-conservation-data (data-owner principal) (privacy-level uint))
  (or (is-eq privacy-level PRIVACY-PUBLIC)
      (is-eq data-owner tx-sender)
      (and (is-eq privacy-level PRIVACY-CONSERVATION-NETWORK) (is-conservation-connected data-owner tx-sender))))

;; Admin functions
(define-public (verify-conservationist-profile (conservationist principal))
  (let ((profile (map-get? conservationist-profiles conservationist)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
      (asserts! (is-some profile) ERR-CONSERVATIONIST-NOT-FOUND)
      (ok (map-set conservationist-profiles conservationist
        (merge (unwrap-panic profile) { is-verified: true }))))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))