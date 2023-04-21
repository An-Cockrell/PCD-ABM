;; extensions [vid]

globals [
  step
  time
  total-system-health
  total-system-damage
  total-IL-1b
  total-IL-18
  total-IL8
  total-PAMP
  total-DAMP
  total-GSDMD
  total-caspase-1
  total-caspase-4-5
  total-caspase-3-7
  total-caspase-8
  total-IL-1R
  total-IL-18R
  total-NFKB
  total-LPS
  total-TLR2
  total-TLR4
  total-FAS-R
  total-FAS-L
  total-tBID
  total-TNF
  total-TNFR1
  total-RIPK1
  total-RIPK3
  total-MLKL-P

  ;; the below listed 'globals' are used for knockout capabilities in the ABM
  IL-1b-global
  IL-18-global
  FAS-L-global
  TNF-global
  IL-1R-global
  IL-18R-global
  TLR4-global
  inflammasome-global
  caspase-1-global
  caspase-4-5-global
  caspase-3-7-global
  GSDMD-global
  NFKB-global
  FAS-R-global
  TNFR1-global
  tBID-global
  caspase-8-global
  RIPK1-global
  RIPK3-global
  MLKL-P-global
  TLR2-global
  stopMarker
  #-PyroptoticCells
  #-NecroptoticCells
]

breed [injs inj]

breed [immune-cells immune-cell] ;; generic immune cell at this time
breed [pyroptotic-immune-cells pyroptotic-immune-cell]
breed [tissue-cells tissue-cell]
breed [apoptotic-cells apoptotic-cell]
breed [pyroptotic-cells pyroptotic-cell]
breed [necroptotic-cells necroptotic-cell]

breed [IAVs IAV] ;; Set incubation time for IAVs ~ 24 hrs = 150 ticks
breed [salmonellas salmonella]
breed [EPECs EPEC]

; extracellular molecules
patches-own [
  DAMP
  PAMP
  IL-1b
  IL-18
  FAS-L
  TNF
  IL8 ; produced by ECs in response to IL1
  ROS
  chemokine ;; generic version of IL8 and MCP1/CCL2. Produced after NFkB activation or oxidative stress
  infection ;; infection remains a patch variable
  ec-viral-particles
]

; receptors and intracellular molecules
turtles-own [
  IL-1R
  IL-18R
  TLR2
  TLR4
  inflammasome
  caspase-1
  caspase-4-5
  caspase-3-7
  caspase-8
  caspase-9
  proto-IL-1b
  proto-IL-18
  GSDMD
  Intracellular-LPS
  NFKB
  FAS-R
  TNFR1
  tBID
  RIPK1
  RIPK3
  MLKL-P

  health ; now a turtle variable, health of tissue-cells measures total system health
  life ; this is how long the cells live. This decrements faster for apoptosis and pyroptosis, important for pyroptosis to stop producing cytokines

  ;; infection based variable
  ic-viral-particles ; for IAV infection
  ;; for salmonella
  intracellular? ; can have it be a binary true or false for salmonella
  invasion-counter ; let's say 2-8 hours to invade, so set at 12 + random 24
  incubation-counter ; let's say 5 hrs (30 steps) to 15 hrs (an additional 10 hrs = + random 60)
  ;; for EPEC
  virulence
  attached?
  replication-counter

]

to setup
  clear-all
  random-seed random-seed-counter

  set-baseline-totals ; sets all counter "total" variables used for graphing to zero (see definition below)

  ask turtles [
    set TLR2 0
    set TLR4 0
    set inflammasome 0
    set caspase-1 0
    set IL-1R 0
    set IL-18 0
    set NFKB 0
    set intracellular-LPS 0
    set caspase-4-5 0
    set caspase-3-7 0
    set caspase-8 0
    set caspase-9 0
    set FAS-R 0
    set tBID 0
    set TNFR1 0
    set RIPK1 0
    set RIPK3 0
    set MLKL-P 0 ; no MLKL needed since no upstream effector
    ;; virus variables
    set ic-viral-particles 0
  ]

  ask patches [
    set PAMP 0
    set DAMP 0
    set IL-1b 0
    set IL-18 0
    set FAS-L 0
    set TNF 0

    set ec-viral-particles 0

    sprout-tissue-cells 1 [
      set color pink
      set shape "square"
      set size 0.9
      set health 100 ; sets baseline health of tissue-cells
      set life 100
    ]
  ]

  create-immune-cells 100
   [set color green
    set shape "circle"
    set size 1
    repeat 5
      [jump random 100]
        set TLR2 0
    set TLR4 0
    set inflammasome 0
    set caspase-1 0
    set IL-1R 0
    set IL-18 0
    set NFKB 0
    set intracellular-LPS 0
    set caspase-4-5 0
    set caspase-3-7 0
    set caspase-8 0
    set caspase-9 0
    set FAS-R 0
    set tBID 0
    set TNFR1 0
    set RIPK1 0
    set RIPK3 0
    set MLKL-P 0 ; no MLKL needed since no upstream effector
  ]

  set-globals

  set total-system-health sum [health] of tissue-cells ;; should = 168100 for 41 x 41 grid
  set total-system-damage max list 0 (168100 - total-system-health)

  reset-ticks
  ;if vid:recorder-status = "recording" [ vid:record-view ]
end

to go
;; increment time
  tick ; 1 tick = 10 min
  set step step + 1
  if step = 6
  [set time time + 1 ; time = hours
    set step 0
  ]

  set-background-patches
  set-KOs

  ; for now, these values are completely made up ***
  ; diffuse only works for patches
  diffuse PAMP 0.1
  diffuse DAMP 0.1
  diffuse IL-1b 0.8
  diffuse IL-18 0.8
  diffuse FAS-L 0.4
  diffuse TNF 0.8
  diffuse IL8 0.8
  diffuse chemokine 0.8

  diffuse ec-viral-particles 0.99

;; Hide turtle code blocks

  ifelse hide-tissue-cells? = true
    [ask tissue-cells
      [ht]
    ]
    [ask tissue-cells
      [st]
    ]

  ifelse hide-leukocytes? = true
    [ask immune-cells
      [ht]
    ]
    [ask immune-cells
      [st]
  ]

  ask patches [
   IAV-spread
   ]

  ask tissue-cells [
    tissue-cell-function]

  ask pyroptotic-cells
    [if life <= 0
      [ask salmonellas-here
        [die]
       die]

     release-pyroptosis-cytokines
     cleave-proto-IL-1b
     cleave-proto-IL-18

     set life life - 1
    ]

  ask pyroptotic-immune-cells
   [if life <= 0
      [hatch 1
        [set breed immune-cells
         set color green
         set shape "circle"
         set size 0
         set TLR2 0
         set TLR4 0
         set inflammasome 0
         set caspase-1 0
         set IL-1R 0
         set IL-18 0
         set NFKB 0
         set intracellular-LPS 0
         set caspase-4-5 0
         set caspase-3-7 0
         set caspase-8 0
         set caspase-9 0
         set FAS-R 0
         set tBID 0
         set TNFR1 0
         set RIPK1 0
         set RIPK3 0
         set MLKL-P 0
         jump random 1000
        ]
        die
      ]

    cleave-proto-IL-1b
    cleave-proto-IL-18
    release-pyroptosis-cytokines
    ;; anti-TNF action
    ifelse anti-TNF-Rx = false
      [set TNF TNF + 1]
      [set TNF 0]

    set life life - 1
   ]

  ask necroptotic-cells
    [if life <= 0
      [ask salmonellas-here
        [die]
       die
      ]

     release-necroptosis-cytokines

     set life life - 1
    ]

  ask apoptotic-cells
   [if life <= 0
      [ask IAVs-here  ;; This removes any ic-viral particles present
        [die]
       ask salmonellas-here
        [die]
       set ic-viral-particles 0
      ]

    set life life - 1
  ]

if immune-cells-on? = true
 [ask immune-cells [immune-cell-function]
  ]

  ;; These are the infection functions
  ask IAVs [IAV-function]
  ask salmonellas [salmonella-function]
  ask EPECs [EPEC-function]

  evaporate-patch-vars
  evaporate-turtle-vars


  update-counts
  update-total-system-health

  ; if vid:recorder-status = "recording" [ vid:record-view ]

  if graph = true
    [draw-graph]
end

to IAV-infect
  create-IAVs IAV-inoculum
  ask IAVs [
    set heading random 360
    repeat 5 [jump random 100]
    set ic-viral-particles random 50 ;; counter for number of intracellular viral particles present
  ]
end

to IAV-function
  if ic-viral-particles >= 150
   [set ec-viral-particles 150
    set PAMP PAMP + random 10
      ask tissue-cells-here [die]
    die
  ]
  set ic-viral-particles ic-viral-particles + 1
end

to IAV-spread
    if random ec-viral-particles > 10
      [if count tissue-cells-here > 0
        [sprout-IAVs 1
          [set ic-viral-particles random 20
          ]
         set ec-viral-particles 0
        ]
      ]
end

to salmonella-infect ;; injection via Type 3 Secretion System => replication starts 4-6 hours after internalization
  create-salmonellas salmonella-inoculum
  ask salmonellas [
    set heading random 360
    repeat 5 [jump random 100]
    set shape "star"
    set color white
    set intracellular? false
    set invasion-counter 12 + random 24 ;; this keeps track of how long it takes to internalize salmonella, 4-8 hours, counts down
    set incubation-counter 30 + random 60
  ]
end

to salmonella-function ;; salmonella engages via TLRs, need to represent invasion and intracellular LPS to Caspase 4/5
 if intracellular? = true
 [;; this represents obligate intracellular status between spread :CELLS DIE TOO FAST FOR SALMONELLA TO SPREAD
  ;  if count tissue-cells-here = 0
  ; [die]

  ;; this code block is replication and subsequent movement to adjacent patch
    if incubation-counter <= 0
    ;; resets all the baseline variables prior to hatch so child inherets
    [set intracellular? false
     set invasion-counter 12 + random 24
     set incubation-counter 30 + random 60
     hatch 1
          [set heading random 360
           fd 1
          ]
     set heading random 360
     fd 1
    ]
   ;; this is intracellular activation of pyroptosis. Dual paths via intracellular-LPS to C4/5 and inflammasome
   ask tissue-cells-here
      [set intracellular-LPS intracellular-LPS + 0.1
      ;; this is inhibtion of NFkB via blocking of TAK1
       set NFKB max list 0 NFKB - 0.075
      ;; this is inhibtion of Caspase-8
       set Caspase-8 max list 0 Caspase-8 - 0.075
      ]
   set incubation-counter incubation-counter - 1
  ]

if intracellular? = false
 [ifelse count tissue-cells-here = 0 ;; will move until finds live tissue cell to invade
    [fd 0.1
    ]
    [if invasion-counter <= 0
       [set intracellular? true
       ]
     ask tissue-cells-here
       [set TLR4 TLR4 + 0.1
       ]
     set invasion-counter invasion-counter - 1
    ]
 ]
end

to EPEC-infect
  create-EPECs EPEC-inoculum
  ask EPECs
    [set heading random 360
      repeat 5 [jump random 100]
      move-to patch-here
      set shape "pentagon"
      set size 1.1
      set color yellow
      set invasion-counter 10 + random 20
      set replication-counter 0
      set virulence 1 ;; assume virulence
      set attached? true
  ]
end


to EPEC-function
;; this code is for replication
if replication-counter >= 100
  [; kills tissue cell and releases DAMPS
;   ask tissue-cells-here
;    [die]
;   set DAMP DAMP + 10
   ; resets to baseline to pass onto child
   set replication-counter 0
   set invasion-counter 10 + random 20
   set virulence 1
   set attached? false
   hatch 1
    [set heading random 360
     fd 1
    ]
   fd 1
  ]

;; This code represents what happens after attached
if attached? = true
  [set replication-counter replication-counter + 1
   ask tissue-cells-here
   [set health max list 0 health - 1]
  ; this is T3SS effector protein effects to inhibit PCD pathways
    ask tissue-cells-here
      [; Inhibit NFkB
        set NFkB max list 0 NFkB - 0.075
       ; Inhibit Inflammasome
        set Inflammasome max list 0 Inflammasome - 0.4
      ]
  ]

  ;; this code reflects the attachment process

if attached? = false
 [ifelse count tissue-cells-here = 0 ;; will move until finds live tissue cell to invade
    [fd 1
    ]
    [if invasion-counter <= 0
       [set attached? true
        set color cyan
       ]
     set invasion-counter invasion-counter - 1
    ]
 ]
end

to tissue-cell-function
  control-PCDs

; Fourth Level Activation
  activate-MLKL-P ; responds to RIPK3, initiates Necroptosis

; Third Level Activation
  NFKB-function ; follows stimulate-NFKB, produces proto-IL-1, proto-IL18, adhesion molecules, and TNF in macrophages (but not tissue cells)
  activate-RIPK3 ; responds to RIPK1, TLR4, activates MLKL-P (to Necroptosis)
  cleave-GSDMD ; responds to Caspase-1, Caspase-8, Caspase-4/5, leads to leakage IL-1, IL-18, DAMPs (end state Pyroptosis)
  activate-tBID ; responds to Caspase-8, initiates Apopotosis
  cleave-caspase-3-7 ; responds to Caspase-1, Caspase-8, and caspase-9 initiates Apopotosis
  ;; ^need to decide how to incorporate this without favoring apoptosis (biology says apop is backup)

; Second Level Activation (dual 1st and 2nd level placed here)
  cleave-caspase-1 ; responds to IL-1r, IL-18r, inflammasome (2nd level), activates GSDMD, Caspase-3/7, iBID (Apoptosis)
  cleave-caspase-8 ; responds to FAS-R, Inflammasome, Caspase-1, inhibits RIPK1 (inhibits Necroptosis), activates tBID (Apopotosis), GSDMD, Caspase-3/7
  stimulate-NFKB ; responds to IL-1r, IL-18r, TLR2, TLR4, TNFR1, activates NFKB-function

; First Level Activation
  stimulate-inflammasome ; responds to TLR-2, TLR-4, ROS, activates Caspase-1, Caspase-8
  activate-RIPK1 ; responds to TNFr1, inhibited by Caspase-8, activates RIPK
  cleave-caspase-4-5 ; placed here because responds to intracellular LPS, there must be some way to internalize, activates GSDMD (to pyroptosis)
  cleave-caspase-9 ; this is the entry into intrinsic pathway for apoptosis, triggered by mitochondrial disruption, but here is triggered by Health < 75

; Cell Surface Receptors
  activate-TLR2 ; responds to PAMP/PDG (G+ Cocci), activates NFKB and Inflammasome (Pyroptosis)
  activate-TLR4 ; responds to extracellular LPS/PAMP and DAMPs, activates NFKb and Inflammasome (Pyroptosis) and RIPK3 (Necroptosis)
  activate-IL-1R ; responds to IL-1, activates Caspase-1
  activate-IL-18R ; responds to IL-18, activates Caspase-1
  activate-TNFR1 ; responds to TNF, activates RIPK-1 (Necroptosis)
  activate-FAS-R ; responds to FAS-L, activates Caspase-8

; Response to viral infection => induction of FAS-R to start protective apoptosis
  if count IAVs-here with [ic-viral-particles > 10] > 0 ;; this sets a threshold of detection if IAVs to initiate antiviral effects
    [set FAS-R FAS-R + 0.1
     set FAS-L FAS-L + 0.1]

    ;; this is for cells consumed by EPEC; don't know if it falls into a PCD so will leave open ended at this time
  if health <= 0
    [die]

;; conditional chemokine production, need to do this until can add anti inflammatory mediators
  if NFkB > 1
    [if count IAVs-here > 0 or count salmonellas-here > 0 or count EPECs-here > 0
    [set chemokine chemokine + 0.1]
  ]
end

to activate-IL-1R
  if IL-1R-global = "active" [
      if IL-1b > 0
      [set IL-1R (IL-1R + 0.1)
      ]
    ]
end

to activate-IL-18R
  if IL-18R-global = "active"
    [
      if IL-18 > 0
        [set IL-18R (IL-18R + 0.1)
      ]
    ]
end

to activate-TNFR1
    if TNFR1-global = "active" [
      if TNF > 1
       [set TNFR1 (TNFR1 + 0.1)
       ]
    ]
end

to activate-TLR2
  if TLR2-global = "active" [
      if PAMP > 0.1
        [set TLR2 (TLR2 + 0.1)
      ]
    ]
end

to activate-TLR4
  if TLR4-global = "active"
      [if PAMP > 0.1 or DAMP > 0.1 or (count salmonellas-here >= 1) or (count EPECs-here >= 1)
        [set TLR4 (TLR4 + 0.1)
        ]
      ]
end

to stimulate-inflammasome
  if inflammasome-global = "active"
      [if TLR2 > 1 or TLR4 > 1 or ROS > 1 or intracellular-lps > 1
        [set inflammasome max list 0 (inflammasome + 0.5)
        if breed = immune-cells
          [set color cyan
          ]
        ]
      ]
end

to activate-FAS-R ;; FAS-R also updated in
  if FAS-R-global = "active"
  [if FAS-L > 1
    [set FAS-R (FAS-R + 0.1)
    ]
  ]
end

to activate-RIPK1 ;; if caspase-8 > 1, then reduce RIPK1 by 0.05
  if TNFR1 > 1
       [set RIPK1 (RIPK1 + 0.1)
       ]
  if Caspase-8 > 1
       [set RIPK1 RIPK1 - 0.05
  ]
end

to activate-RIPK3 ;; this is dual activation, same inhibtion by caspase-8 as with RIPK1
  if RIPK3-global = "active"
      [if RIPK1 > 1 or TLR4 > 1
        [set RIPK3 max list 0 (RIPK3 + 0.1)
        ]
      ]
  if caspase-8 > 1
      [set RIPK3 max list 0 RIPK3 - 0.05
      ]
end

to cleave-caspase-1
  if caspase-1-global = "active"
      [if inflammasome > 1
        [set caspase-1 (caspase-1 + 0.1) ; active inflammasome keeps activating more C1
        ]
      ]
end

to cleave-caspase-4-5
  if caspase-4-5-global = "active"
     [if intracellular-LPS > 1
        [set caspase-4-5 (caspase-4-5 + 0.1)
        ]
     ]
end

to cleave-caspase-3-7
  if caspase-3-7-global = "active"
      [if caspase-8 > 1 or caspase-1 > 1 or caspase-9 > 1
        [set caspase-3-7 (caspase-3-7 + 0.1)
        ]
      ]
end

to cleave-caspase-8
  if caspase-8-global = "active"
     [if caspase-1 > 1 or FAS-R > 1
       [set caspase-8 (caspase-8 + 0.1)
       ]
 ;      set RIPK1-global "inactive" ; active C8 inhibits RIPK1
     ]
end

to cleave-caspase-9
   if health < 75
    [set caspase-9 caspase-9 + 0.01
  ]
end

to cleave-GSDMD

;; Three entry points to GSDMD cleavage, use OR statements these conditions
;; Increments by +0.5
  if GSDMD-global = "active"
  [if (caspase-1 > 1) or (caspase-4-5 > 1) or (caspase-8 > 1)
    [set GSDMD GSDMD + 0.1
     if breed = immune-cells
      [set color yellow]
    ]
  ]
end

to activate-MLKL-P
  if MLKL-P-global = "active"
      [if RIPK3-global = "active"
        [if RIPK3 > 1
          [set MLKL-P (MLKL-P + 0.1)
          ]
        ]
      ]
end

;; BID --> tBID can be activated by C8 and C1
to activate-tBID
  if tBID-global = "active"
      [if caspase-8 > 1 or caspase-1 > 1
        [set tBID (tBID + 0.1)
        ]
      ]
end

to stimulate-NFKB
  if NFKB-global = "active"
     [ifelse IL-1R > 1 or IL-18R > 1 or TLR2 > 1 or TLR4 > 1 or TNFr1 > 1
      [set NFKB max list 0 NFKB + 0.1
       ]
       [set NFKB 0
        ]
  ]
end

to NFKB-function
 if NFKB > 1 [
      NFKB-products
    ]
end

to NFKB-products
;; protocytokines activated by NFkb
  if IL-1b-global = "active"
   [set proto-IL-1b proto-IL-1b + 0.1
   ]
  if IL-18-global = "active"
   [set proto-IL-18 proto-IL-18 + 0.1
  ]
;; chemokines (generic form of IL8 and MCP1/CCL2
;   set chemokine chemokine + 0.1

;  if breed = immune-cells
;    [set TNF TNF + 0.75
;      ]
;  ]

end

to wiggle
  rt random 45
  lt random 45
  ifelse count turtles-on patch-ahead 1 < 28[
          fd 0.1]
  [print(word "WIGGLE greater than 28 turtles" count turtles-on patch-ahead 1)]
end

to control-PCDs

    let pcd-pathway random 3

    if pcd-pathway = 0
    [if inflammasome-global = "active" [
      if inflammasome > random-float 3 [
        undergo-pyroptosis
        release-pyroptosis-cytokines
      ]
    ]
    ]

    if pcd-pathway = 1
    [if RIPK3-global = "active" [
      if RIPK3 > random-float 3 [
        undergo-necroptosis
        release-necroptosis-cytokines
      ]
    ]
    ]

    if pcd-pathway = 2
    [if caspase-8-global = "active" [
      if caspase-8 > random-float 3 [
        undergo-apoptosis
      ]
    ]

    if caspase-1-global = "active" [
      if caspase-1 > random-float 3 [
        undergo-apoptosis
      ]
    ]
  ]

end

to undergo-apoptosis
    if caspase-3-7 > 0 or tBID > 0
     [if breed = tissue-cells
       [set breed apoptotic-cells
        set color white
        set shape "square 2"
        st
        set life 100
       ]
    ]

end

to undergo-pyroptosis
    if GSDMD-global = "active" [
      if GSDMD > 0 [
        if breed = tissue-cells
         [set breed pyroptotic-cells
          set color gray
          set shape "square"
          st
          set #-PyroptoticCells #-PyroptoticCells + 1
          set Life 50
         ]

       if breed = immune-cells
        [set breed pyroptotic-immune-cells
         set color red
         set shape "circle"
         set size 2
         st
         set life 50
      ]
      ]
    ]
end

to release-pyroptosis-cytokines

      ifelse Anti-IL-1b-Rx = false
    [set IL-1b (IL-1b + 0.1)]
     [set Il-1b 0]
      set IL-18 (IL-18 + 0.1)

      set DAMP (DAMP + 0.15)
end

;; These two code blocks represent the cleavage and release of proto-Interleukins as active Interleukins
to cleave-proto-IL-1b
  if IL-1b-global = "active"
   [if GSDMD > 0
     [ifelse Anti-IL-1b-Rx = false
        [set IL-1b proto-IL-1b]
        [set IL-1b 0]
     ]
    ]
end

to cleave-proto-IL-18
  if IL-18-global = "active"
  [if GSDMD > 0
     [set IL-18 proto-IL-18
    ]
    ]
end

to undergo-necroptosis
  if MLKL-P > 0 [
    if MLKL-P-global = "active" [
      if MLKL-P > 0 [
        if breed = tissue-cells
          [set breed necroptotic-cells
           set color brown
           set shape "square"
           st
           set DAMP (DAMP + 0.15)
           set life 50
           set #-NecroptoticCells #-NecroptoticCells + 1
          ]
      ]
    ]
  ]
end

to release-necroptosis-cytokines
  set DAMP (DAMP + 0.05)
end

to immune-cell-function
  ifelse chemokine > 0
   [;move-to patch-here  ;; go to patch center
          let p max-one-of neighbors [chemokine]  ;; or neighbors4
          if [chemokine + IL-1b] of p > (chemokine + IL-1b)
          [face p
           ifelse not any? immune-cells-on patch-ahead 1
            [set chemokine 0
             fd 0.1
    ;         set chemokine 0
            ]
            [set chemokine 0
            ]
      ]

   ]
  [wiggle
  ]
  ;; Kills extracellular salmonella
  ask salmonellas-here
   [if intracellular? = false
    [die]
   ]
  ;; kills EPECs, with some inhibition of phagocytosis, 25% efficacy
;  if count EPECs-here > 1
   if random 3 <= 2
    [ask EPECs-here
        [die]
;      ]
  ]

;; immune cell pyroptosis
  control-PCDs

; Fourth Level Activation
;  activate-MLKL-P ; responds to RIPK3, initiates Necroptosis

; Third Level Activation
  NFKB-function ; follows stimulate-NFKB, produces proto-IL-1, proto-IL18, adhesion molecules, and TNF in macrophages (but not tissue cells)
  activate-RIPK3 ; responds to RIPK1, TLR4, activates MLKL-P (to Necroptosis)
  cleave-GSDMD ; responds to Caspase-1, Caspase-8, Caspase-4/5, leads to leakage IL-1, IL-18, DAMPs (end state Pyroptosis)
  activate-tBID ; responds to Caspase-8, initiates Apopotosis
;  cleave-caspase-3-7 ; responds to Caspase-1, Caspase-8, initiates Apopotosis
;; ^need to decide how to incorporate this without favoring apoptosis (biology says apop is backup)

; Second Level Activation (dual 1st and 2nd level placed here)
  cleave-caspase-1 ; responds to IL-1r, IL-18r, inflammasome (2nd level), activates GSDMD, Caspase-3/7, iBID (Apoptosis)
  cleave-caspase-8 ; responds to FAS-R, Inflammasome, Caspase-1, inhibits RIPK1 (inhibits Necroptosis), activates tBID (Apopotosis), GSDMD, Caspase-3/7
  stimulate-NFKB ; responds to IL-1r, IL-18r, TLR2, TLR4, TNFR1, activates NFKB-function

; First Level Activation
  stimulate-inflammasome ; responds to TLR-2, TLR-4, ROS, activates Caspase-1, Caspase-8
  activate-RIPK1 ; responds to TNFr1, inhibited by Caspase-8, activates RIPK

; Cell Surface Receptors
  activate-TLR2 ; responds to PAMP/PDG (G+ Cocci), activates NFKB and Inflammasome (Pyroptosis)
  activate-TLR4 ; responds to extracellular LPS/PAMP and DAMPs, activates NFKb and Inflammasome (Pyroptosis) and RIPK3 (Necroptosis)
  activate-IL-1R ; responds to IL-1, activates Caspase-1
  activate-IL-18R ; responds to IL-18, activates Caspase-1
  activate-TNFR1 ; responds to TNF, activates RIPK-1 (Necroptosis)
end

;; the following procedures all correspond to GUI buttons, this is what introduces the "insult" into the system
to release-PAMP
  ask patches [
    if random initial-PAMP-insult = 1 ;; fractional PAMP release
    [set PAMP PAMP + random 10]
  ]
end

to release-DAMP
  ask patches [
    if random initial-DAMP-insult = 1 ;; fractional DAMP release
    [set DAMP DAMP + random 10]
  ]
end

to release-FAS-L
  ask patches [
    if random 4 = 1 ;; 25% release
    [set FAS-L FAS-L + random 4]
  ]
end

to release-TNF
  ask patches [
    if random 4 = 1 ;; 25% release
    [set TNF TNF + random 4]
  ]
end

to release-caspase-3-7
  ask turtles [
    if random 10 = 1
    [set caspase-3-7 caspase-3-7 + random 2]
  ]
end

to release-caspase-8
  ask turtles [
    if random 6 = 1
     [set caspase-8 caspase-8 + 10]
  ]
end
;; to here (see above)

;; Bookkeeping code blocks here
to update-total-system-health
  set total-system-health (sum [health] of tissue-cells)
  set total-system-damage max list 0 (168100 - total-system-health)
end

to set-baseline-totals
  set step 0
  set time 1
  set total-IL-1b 0
  set total-IL-18 0
  set total-PAMP 0
  set total-DAMP 0
  set total-GSDMD 0
  set total-caspase-1 0
  set total-IL-1R 0
  set total-IL-18R 0
  set total-NFKB 0
  set total-LPS 0
  set total-caspase-4-5 0
  set total-caspase-3-7 0
  set total-caspase-8 0
  set total-TLR2 0
  set total-TLR4 0
  set total-FAS-R 0
  set total-FAS-L 0
  set total-tBID 0
  set total-TNF 0
  set total-TNFR1 0
  set total-RIPK1 0
  set total-RIPK3 0
  set total-MLKL-P 0
  set stopMarker 100
end

to update-counts
  set total-IL-1b (sum [IL-1b] of patches)
  set total-IL-18 (sum [IL-18] of patches)
  set total-IL8 (sum [IL8] of patches)
  set total-PAMP (sum [PAMP] of patches)
  set total-DAMP (sum [DAMP] of patches)
  set total-FAS-L (sum [FAS-L] of patches)
  set total-GSDMD (sum [GSDMD] of turtles)
  set total-caspase-1 (sum [caspase-1] of turtles)
  set total-IL-1R (sum [IL-1R] of turtles)
  set total-IL-18R (sum [IL-18R] of turtles)
  set total-NFKB (sum [NFKB] of turtles)
  set total-LPS (sum [intracellular-LPS] of turtles)
  set total-caspase-4-5 (sum [caspase-4-5] of turtles)
  set total-caspase-3-7 (sum [caspase-3-7] of turtles)
  set total-caspase-8 (sum [caspase-8] of turtles)
  set total-TLR2 (sum [TLR2] of turtles)
  set total-TLR4 (sum [TLR4] of turtles)
  set total-FAS-R (sum [FAS-R] of turtles)
  set total-tBID (sum [tBID] of turtles)
  set total-TNF (sum [TNF] of patches)
  set total-TNFR1 (sum [TNFR1] of turtles)
  set total-RIPK1 (sum [RIPK1] of turtles)
  set total-RIPK3 (sum [RIPK3] of turtles)
  set total-MLKL-P (sum [MLKL-P] of turtles)
end

to set-background-patches
  ask patches [
  if background? = "IL-1b"
    [set pcolor scale-color red IL-1b 0 1]
  if background? = "IL-18"
    [set pcolor scale-color orange IL-18 0 5]
  if background? = "PAMP"
    [set pcolor scale-color magenta PAMP 0 10]
  if background? = "DAMP"
    [set pcolor scale-color magenta DAMP 0 5]
  if background? = "FAS-L"
    [set pcolor scale-color yellow FAS-L 0 1]
  if background? = "TNF"
    [set pcolor scale-color lime TNF 0 0.5]
  if background? = "IL8"
    [set pcolor scale-color yellow IL8 0 5]
  if background? = "ec-viral-particles"
    [set pcolor scale-color yellow ec-viral-particles 0 10]
  if background? = "chemokine"
    [set pcolor scale-color blue chemokine 0 0.2]
  ]
end

to set-globals
  set IL-1b-global "active"
  set IL-18-global "active"
  set FAS-L-global "active"
  set TNF-global "active"
  set IL-1R-global "active"
  set IL-18R-global "active"
  set TLR2-global "active"
  set TLR4-global "active"
  set inflammasome-global "active"
  set caspase-1-global "active"
  set caspase-4-5-global "active"
  set caspase-3-7-global "active"
  set caspase-8-global "active"
  set GSDMD-global "active"
  set NFKB-global "active"
  set FAS-R-global "active"
  set TNFR1-global "active"
  set tBID-global "active"
  set RIPK1-global "active"
  set RIPK3-global "active"
  set MLKL-P-global "active"
end

to set-KOs
  if knockout? = "IL-1b"
  [set IL-1b-global  "inactive"]
  if knockout? = "IL-18"
  [set IL-18-global "inactive"]
  if knockout? = "FAS-L"
  [set FAS-L-global "inactive"]
  if knockout? = "TNF"
  [set TNF-global "inactive"]
  if knockout? = "IL-1R"
  [set IL-1R-global "inactive"]
  if knockout? = "IL-18R"
  [set IL-18R-global "inactive"]
  if knockout? = "TLR4"
  [set TLR4-global "inactive"]
  if knockout? = "inflammasome"
  [set inflammasome-global "inactive"]
  if knockout? = "caspase-1"
  [set caspase-1-global "inactive"]
  if knockout? = "caspase-4-5"
  [set caspase-4-5-global "inactive"]
  if knockout? = "caspase-3-7"
  [set caspase-3-7-global "inactive"]
  if knockout? = "GSDMD"
  [set GSDMD-global "inactive"]
  if knockout? = "NFKB"
  [set NFKB-global "inactive"]
  if knockout? = "FAS-R"
  [set FAS-R-global "inactive"]
  if knockout? = "TNFR1"
  [set TNFR1-global "inactive"]
  if knockout? = "tBID"
  [set tBID-global "inactive"]
  if knockout? = "Caspase-8"
  [set caspase-8-global "inactive"]
  if knockout? = "TLR2"
  [set TLR2-global "inactive"]
  if knockout? = "RIPK1"
  [set RIPK1-global "inactive"]
  if knockout? = "RIPK3"
  [set RIPK3-global "inactive"]
  if knockout? = "MLKL-P"
  [set MLKL-P-global "inactive"]
end

to evaporate-patch-vars
  ask patches [
    set PAMP PAMP * 0.8
    if PAMP < 0.01
      [set PAMP 0]

    set DAMP DAMP * 0.8
    if DAMP < 0.01
      [set DAMP 0]

    set IL-1b IL-1b * 0.8
    if IL-1b < 0.01
      [set IL-1b 0]

    set IL-18 IL-18 * 0.8
    if IL-18 < 0.01
      [set IL-18 0]

    set FAS-L FAS-L * 0.9
    if FAS-L < 0.01
      [set FAS-L 0]

    set TNF TNF * 0.8
    if TNF < 0.01
      [set TNF 0]

    set IL8 IL8 * 0.8
    if IL8 < 0.01
      [set IL8 0]

    if ec-viral-particles <= 10
      [set ec-viral-particles 0]

    set chemokine chemokine * 0.8
    if chemokine < 0.01
      [set chemokine 0]

  ]
end

to evaporate-turtle-vars
  ask turtles [
    set inflammasome inflammasome * 0.99
    if inflammasome < 0.01
      [set inflammasome 0]

    set GSDMD GSDMD * 0.99
    if GSDMD < 0.01
      [set GSDMD 0]

    set caspase-1 caspase-1 * 0.99
    if caspase-1 < 0.01
      [set caspase-1 0]

    set ROS ROS * 0.999
    if ROS < 0.01
      [set ROS 0]

    set NFKB NFKB * 0.95
    if NFKB < 0.01
      [set NFKB 0]

    set caspase-4-5 caspase-4-5 * 0.93
    if caspase-4-5 < 0.01
      [set caspase-4-5 0]

    set TLR2 TLR2 * 0.99
    if TLR2 < 0.01
      [set TLR2 0]

    set TLR4 TLR4 * 0.99
    if TLR4 < 0.01
      [set TLR4 0]

    set caspase-3-7 caspase-3-7 * 0.99
    if caspase-3-7 < 0.01
      [set caspase-3-7 0]

    set caspase-8 caspase-8 * 0.99
    if caspase-8 < 0.01
      [set caspase-8 0]

    set caspase-9 caspase-9 * 0.99
    if caspase-9 < 0.01
      [set caspase-9 0]

    set FAS-R FAS-R * 0.9999
    if FAS-R < 0.01
      [set FAS-R 0]

    set tBID tBID * 0.99
    if tBID < 0.01
      [set tBID 0]

    set TNFR1 TNFR1 * 0.99
    if TNFR1 < 0.01
      [set TNFR1 0]

    set RIPK1 RIPK1 * 0.97
    if RIPK1 < 0.01
      [set RIPK1 0]

    set RIPK3 RIPK3 * 0.99
    if RIPK3 < 0.01
      [set RIPK3 0]

    set MLKL-P MLKL-P * 0.99
    if MLKL-P < 0.01
      [set MLKL-P 0]

  ]
end

to draw-graph
  set-current-plot "cytokines"
  set-current-plot-pen "IL-1b"
  plot total-IL-1b
  set-current-plot-pen "IL-18"
  plot total-IL-18
  set-current-plot-pen "PAMP"
  plot total-PAMP
  set-current-plot-pen "DAMP"
  plot total-DAMP
  set-current-plot-pen "FAS-L"
  plot total-FAS-L
  set-current-plot-pen "TNF"
  plot total-TNF

  set-current-plot "cells"
  set-current-plot-pen "tcs"
  plot count tissue-cells
  set-current-plot-pen "immune cells"
  plot count immune-cells

  set-current-plot "PCD Mechanism"
  set-current-plot-pen "apoptosis"
  plot count apoptotic-cells
  set-current-plot-pen "pyroptosis"
  plot count pyroptotic-cells
  set-current-plot-pen "necroptosis"
  plot count necroptotic-cells

  set-current-plot "health"
  set-current-plot-pen "system health"
  plot total-system-health

  set-current-plot "intracellular molecules"
  set-current-plot-pen "GSDMD"
  plot total-GSDMD
  set-current-plot-pen "Caspase 1"
  plot total-caspase-1
  set-current-plot-pen "Caspase 4/5"
  plot total-caspase-4-5
  set-current-plot-pen "Caspase 3/7"
  plot total-caspase-3-7
  set-current-plot-pen "Caspase 8"
  plot total-caspase-8
  set-current-plot-pen "NFKB"
  plot total-NFKB
  set-current-plot-pen "LPS"
  plot total-LPS
  set-current-plot-pen "tBID"
  plot total-tBID
  set-current-plot-pen "RIPK1"
  plot total-RIPK1
  set-current-plot-pen "RIPK3"
  plot total-RIPK3
  set-current-plot-pen "MLKL-P"
  plot total-MLKL-P

  set-current-plot "receptors"
  set-current-plot-pen "TLR2"
  plot total-TLR2
  set-current-plot-pen "TLR4"
  plot total-TLR4
  set-current-plot-pen "IL-1R"
  plot total-IL-1R
  set-current-plot-pen "IL-18R"
  plot total-IL-18R
  set-current-plot-pen "FAS-R"
  plot total-FAS-R
  set-current-plot-pen "TNFR1"
  plot total-TNFR1

end

;to start-recorder
;  carefully [ vid:start-recorder ] [ user-message error-message ]
;end

;to reset-recorder
;  let message (word
;    "If you reset the recorder, the current recording will be lost."
;    "Are you sure you want to reset the recorder?")
;  if vid:recorder-status = "inactive" or user-yes-or-no? message [
;    vid:reset-recorder
;  ]
;end

;to save-recording
; if vid:recorder-status = "inactive" [
;    user-message "The recorder is inactive. There is nothing to save."
;    stop
;  ]
;  ; prompt user for movie location
;  user-message (word
;    "Choose a name for your movie file (the "
;    ".mp4 extension will be automatically added).")
;  let path user-new-file
;  if not is-string? path [ stop ]  ; stop if user canceled
;  ; export the movie
;  carefully [
;    vid:save-recording path
;    user-message (word "Exported movie to " path ".")
;  ] [
;    user-message error-message
;  ]
;end

;;

;; PRIOR CODE, not currently in use but saving (why? who knows.)

; to release-LPS
;   ask turtles [
;     if random 4 = 1 ;; 25% LPS release
;     [set LPS LPS + random 4]
;  ]
; end

;to pyroptotic-cell-die
;  ask turtles [
;    if GSDMD > 6 [
;      die
;      set dead-cells (dead-cells + 1)
;    ]
;  ]
;end

; to EC-function
;  if IL-1R > 1
;  [set IL8 IL8 + 5
;  ]
; end

;to PMN-function
;  ifelse IL8 > 0
;  [uphill IL8]
;  [wiggle]

;  set infection max list 0 (infection - 50)
;end

;; DANGER ZONE BELOW
@#$#@#$#@
GRAPHICS-WINDOW
151
56
569
475
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
51
10
106
43
setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
89
43
144
76
go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
2
446
150
479
random-seed-counter
random-seed-counter
0
100
9.0
1
1
NIL
HORIZONTAL

MONITOR
254
476
347
521
# immune cells
count immune-cells
2
1
11

MONITOR
429
610
491
655
IL-1b
sum ([IL-1b] of patches)
2
1
11

MONITOR
170
476
254
521
# tissue cells
count tissue-cells
2
1
11

MONITOR
169
610
253
655
# pyroptosis
count pyroptotic-cells
2
1
11

MONITOR
252
610
328
655
# apoptosis
count apoptotic-cells
2
1
11

BUTTON
143
835
216
870
add PAMPs
release-PAMP
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

MONITOR
170
520
243
565
PAMP
sum ([PAMP] of patches)
2
1
11

MONITOR
308
520
413
565
Inflammasome
sum ([inflammasome] of (tissue-cells))
2
1
11

MONITOR
200
10
267
55
Time
Time
2
1
11

MONITOR
151
10
201
55
Step
Step
2
1
11

SWITCH
0
308
146
341
Graph
Graph
0
1
-1000

PLOT
865
443
1149
626
Cytokines
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"PAMP" 1.0 0 -5825686 true "" ""
"DAMP" 1.0 0 -5825686 true "" ""
"IL-1b" 1.0 0 -2674135 true "" ""
"IL-18" 1.0 0 -955883 true "" ""
"FAS-L" 1.0 0 -1184463 true "" ""
"TNF" 1.0 0 -13840069 true "" ""

PLOT
582
12
858
162
Cells
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"tcs" 1.0 0 -6459832 true "" ""
"immune cells" 1.0 0 -2674135 true "" ""

CHOOSER
11
391
140
436
background?
background?
"none" "IL-1b" "IL-18" "PAMP" "DAMP" "FAS-L" "TNF" "IL8" "ec-viral-particles" "chemokine"
7

PLOT
582
160
858
317
PCD Mechanism
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"apoptosis" 1.0 0 -16777216 true "" ""
"pyroptosis" 1.0 0 -7500403 true "" ""
"necroptosis" 1.0 0 -6459832 true "" ""

PLOT
865
220
1148
444
Intracellular Molecules
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"GSDMD" 1.0 0 -7500403 true "" ""
"Caspase 1" 1.0 0 -987046 true "" ""
"Caspase 4/5" 1.0 0 -1184463 true "" ""
"Caspase 3/7" 1.0 0 -1184463 true "" ""
"Caspase 8" 1.0 0 -1184463 true "" ""
"NFKB" 1.0 0 -13840069 true "" ""
"LPS" 1.0 0 -8431303 true "" ""
"tBID" 1.0 0 -16777216 true "" ""
"RIPK1" 1.0 0 -13345367 true "" ""
"RIPK3" 1.0 0 -13345367 true "" ""
"MLKL-P" 1.0 0 -5825686 true "" ""

BUTTON
8
43
89
76
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
490
610
553
655
IL-18
(sum [IL-18] of patches)
2
1
11

PLOT
864
12
1147
221
Receptors
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"IL-1R" 1.0 0 -2674135 true "" ""
"IL-18R" 1.0 0 -955883 true "" ""
"FAS-R" 1.0 0 -1184463 true "" ""
"TLR2" 1.0 0 -16777216 true "" ""
"TLR4" 1.0 0 -16777216 true "" ""
"TNFR1" 1.0 0 -13840069 true "" ""

BUTTON
358
760
479
793
NIL
start-recorder
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

BUTTON
356
802
480
836
NIL
reset-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
353
845
479
890
NIL
vid:recorder-status
17
1
11

BUTTON
355
897
479
930
NIL
save-recording
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

BUTTON
524
922
612
955
release C3/7
release-caspase-3-7
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
234
870
329
903
add FAS-L
release-FAS-L
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
240
832
328
865
release C8
release-caspase-8
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
0
243
146
276
hide-leukocytes?
hide-leukocytes?
1
1
-1000

BUTTON
247
908
329
941
add TNF
release-TNF
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
327
610
414
655
# necroptosis
count necroptotic-cells
2
1
11

MONITOR
420
522
487
567
TNF
(sum [TNF] of patches)
2
1
11

CHOOSER
11
347
140
392
knockout?
knockout?
"none" "inflammasome" "caspase-1" "GSDMD" "caspase-4-5" "caspase-3-7" "caspase-8" "NFKB" "RIPK1" "RIPK3" "MLKL-P" "tBID" "IL-1b" "IL-18" "FAS-L" "TNF" "IL-1R" "IL-18R" "TLR2" "TLR4" "FAS-R" "TNFR1"
0

MONITOR
242
520
309
565
DAMP
(sum [DAMP] of patches)
2
1
11

PLOT
582
316
858
486
Health
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"System health" 1.0 0 -13840069 true "" ""

MONITOR
322
10
440
55
Total system health
Total-System-Health
2
1
11

MONITOR
440
10
569
55
Total system damage
Total-System-Damage
2
1
11

SLIDER
76
896
225
929
initial-DAMP-insult
initial-DAMP-insult
0
25
7.0
1
1
NIL
HORIZONTAL

SLIDER
73
866
223
899
initial-PAMP-insult
initial-PAMP-insult
0
25
25.0
1
1
NIL
HORIZONTAL

MONITOR
170
565
241
610
Caspase 1
sum [caspase-1] of turtles
2
1
11

SLIDER
0
522
158
555
IAV-inoculum
IAV-inoculum
0
300
300.0
1
1
NIL
HORIZONTAL

MONITOR
183
769
258
814
IAV turtles
count IAVs
2
1
11

MONITOR
647
518
697
563
EC IAV
sum [ec-viral-particles] of patches
17
1
11

SWITCH
0
276
146
309
hide-tissue-cells?
hide-tissue-cells?
1
1
-1000

BUTTON
73
835
138
868
Add DAMP
release-DAMP
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
512
827
633
872
NIL
#-PyroptoticCells
17
1
11

MONITOR
515
874
646
919
NIL
#-NecroptoticCells
17
1
11

BUTTON
52
107
107
140
IAV
IAV-infect
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
588
518
646
563
IC IAV
sum [ic-viral-particles] of IAVs
17
1
11

SLIDER
0
554
158
587
salmonella-inoculum
salmonella-inoculum
0
300
50.0
1
1
NIL
HORIZONTAL

BUTTON
77
75
132
108
SE
salmonella-infect
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
588
564
674
609
EC Salmonella
count salmonellas with [intracellular? = false]
17
1
11

MONITOR
674
564
757
609
IC Salmonella
count salmonellas with [intracellular? = true]
17
1
11

SWITCH
0
146
146
179
Immune-cells-on?
Immune-cells-on?
0
1
-1000

SLIDER
0
490
158
523
EPEC-inoculum
EPEC-inoculum
0
300
150.0
1
1
NIL
HORIZONTAL

BUTTON
19
75
79
108
EPEC
EPEC-infect
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
588
609
645
654
EPECs
count EPECs
2
1
11

MONITOR
374
476
478
521
Total chemokine
sum [chemokine] of patches
2
1
11

MONITOR
240
565
312
610
Caspase 8
sum [caspase-8] of tissue-cells
2
1
11

MONITOR
312
565
393
610
Caspase 9
sum [caspase-9] of tissue-cells
2
1
11

SWITCH
0
178
146
211
Anti-TNF-Rx
Anti-TNF-Rx
0
1
-1000

SWITCH
0
210
146
243
Anti-IL-1b-Rx
Anti-IL-1b-Rx
0
1
-1000

@#$#@#$#@
Notes 3/23/23

Added Anti-cytokine therapies
Two switches: Anti-TNF-Rx and Anti-IL-1b-Rx
If to "True" then:
IL-1b to 0 in cleave-proto-IL-1b and release-pyroptosis-cytokines
TNF to 0 in pyroptotic-cell-function


Modification to effects of EPECs

Added intrinsic pathway for apoptosis
Rationale: Consumption of nutrients would trigger apoptosis in tissue cells, no invasive burst death, therefore added caspase-9. This would normally be induced by a host of mechanisms related to mitochondrial leakage, but for simplicity here tied to Health variable, start generating caspase-9 (standard update + 0.1 and evap as other caspases) with Health < 75.

Added impared phagocytosis from EPECs
Now set to 75% chance of phagocytosis, seen in Immune-cell-function

Added Caspase-8 inhibtion of RIPK1 and RIPK3
Added conditionals in activate-RIPK1 and activate-RIPK3 where if caspase-8 > 1 then decreases RIPK1/3 by 0.05. Similar to how EPECs and salmonella suppress PCD pathways

Notes 3-22-23

FIXED/Hacked Chemokines:
Artificial fix pending addition of anti-inflammatory mediators
Now only tissue-cells that produce chemokine are those with NFkB > 1 AND have a pathogen on their patch (either IAV, EPEC or Salmonella). 

Add Infection with Enteropathic E coli (EPEC)
Extracellular, forms clusters (so clustered insult)
Injects inhibitors of various PCD pathways via T3SS
1. Inhibits signaling from TLR2, TLR4, TNFR1 and IL-1r
2. Inhibits translocation and binding of NFkB 
3. Inhibits Caspase 1 from both Inflammasome/NLRP3 and Caspase 8

EPEC virulence regulated by environmental cues, "stringent response"
Baseline infection will assume stringent response

Two step process:
Adhesion: will use invasion-counter even though no invasion

Injection: This is engagement with host cell, injection of signaling inhibitors and consumption of cell. This is where the randomness is introduced... Let's say ~ 6 hours

Way EPECs kill: They consume host cells, need to think how this is manifest either reduction of health or life...Will choose health, since using life as counter for PCD deaths
Feeding: reduction of health on host cell, increase of health on EPEC, when reaches a threshold then EPEC divides (Replication-counter = 50, kills tissue-cell when replicates)

EPECs effect on PCD in EPEC-function:
Inhibit NFkB: set NFkB - 0.075 (3/4 increment of positive signaling in stimulate-NFkB)
Inhibit Inflammasome: set Inflammasome - 0.4 (4/5 increment of positive signaling in stimulate-Inflammasome)

Ref:
Lee JB, Kim SK, Yoon JW. Pathophysiology of enteropathogenic Escherichia coli during a host infection. J Vet Sci. 2022 Mar;23(2):e28. doi: 10.4142/jvs.21160. Epub 2022 Jan 27. PMID: 35187883; PMCID: PMC8977535.

Clarke SC, Haigh RD, Freestone PP, Williams PH. Virulence of enteropathogenic Escherichia coli, a global pathogen. Clin Microbiol Rev. 2003 Jul;16(3):365-78. doi: 10.1128/CMR.16.3.365-378.2003. PMID: 12857773; PMCID: PMC164217.

Immune cells:
Kill one EPEC on same patch.


ALSO:
Added Salmonella inhibition of PCD pathways (T3SS proteins) in Salmonella-function
Inhibit NFkB (blocks TAK1): set NKFkB - 0.075 (3/4 increment of positive signaling in stimulate-NFkB)
Inhibit Caspase 8: set Caspase-8 - 0.075 (3/4 increment of positive signaling in cleave-Caspase-8)


Notes 3-21-23

Add Immune Cells: generic at this point, try and aggregate innate immune cell functions to limit complexity

Add chemokine for immune cells: generic form of IL-8 and MCP1/CCL2 => produced by activation of NFkB: this is actually a problem because can't effectively shut off NFkB so chemokine is persistently generated, reaches a steady state despite the immune cells setting to 0 when going uphill. This will have to be fixed later, but for moment okay

Immune cells do all the PCDs the tissue cells do, mainly to get to pyroptosis.
TNF only made during pyroptotic phase, not just with NFkB stimulation. Same problem as with chemokine; can't effectively shut off wo antiinflammatory cytokines

Simulate Salmonella: Obligate intracellular pathogen, I think can use most of the same processes as IAV, exception is intracellular LPS signalling to maybe get upstream to pyroptosis/GSDMD. Note that host defense strategy for controlling salmonella involves inducing PCD and shedding (enterocytes).
Mechanisms:
activate Caspase 4/5 via intracellular LPS (flagellin) => primary pathway
activate Inflammasome (NLRP3) via intracellular LPS (flagellin) => secondary
activate TLR4 (extracellular as a PAMP)

Invasion time: 4-8 hours before internalize
Incuabtion time: reported to be 24-72 hours, we will set at 20 hours post internalization (120 steps)

Reference:
Qiao Li, "Mechanisms for the Invasion and Dissemination of Salmonella", Canadian Journal of Infectious Diseases and Medical Microbiology, vol. 2022, Article ID 2655801, 12 pages, 2022. https://doi.org/10.1155/2022/2655801

This is what is implemented:
invasion-counter ; let's say 2-8 hours to invade, so set at 12 + random 24
incubation-counter ; let's say 5 hrs (30 steps) to 15 hrs (an additional 10 hrs = + random 60)

When cells die, intracellular salmonella dies as well (in PCD terminal functions)
For EC salmonella, if no viable tissue cell, then move 0.1 until one is present


Notes 3-19/20-23

Viral Infection: This is partitioned over a set of different functions

IAVs: These are turtles that are essentially markers of tissue cell infection and counters for amount of intracellular viral particles
IAV-infect: Button, Turtle Function
Initialization: ic-viral-particles random 50

IAV-Function: Turtle function called in Go for IAVs
IAV incubation time ~ 24 hrs = 150 ticks; this means that at ic-viral-particles = 150 the tissue cell dies, the ic-viral-particles convert to ec-viral-particles and the IAV dies

IAV-spread: Patch function called by patches in Go
ec-viral-particles Diffuse at 0.99 => gives about 18.5 to Moore Neighborhood
If random ec-viral-particles > 10, then sprouts an IAV if live tissue-cell present, sets ec-viral-particles to 0, sets ic-viral-particles to random 20, then incubates
ec-viral-particles also "evaporate", if <= 10 then set to 0

IAV induces FASr (and production of FASl) 
In tissue-cell-fuction:
if tissue cell infected (IAV here with > 10 IC-viral particles), then starts updating FAS-R by 0.1 and producing FAS-L at + 0.1
FAS-L diffusion changed to 0.4 to simulate locality, and evaporation changed to 0.9
Apoptotic-cell life set to 100, decrements by 1. With IAV starting ic-viral-particles at random 50, this gives some overlap so you have breakthrough viral cell lysis

Effect is that able to control viral infection, minimal pyroptosis (since pathway is non-inflammogenic)

Citations:(
Takizawa, Takenori, Kayoko Ohashi, and Yoshinobu Nakanishi. "Possible involvement of double-stranded RNA-activated protein kinase in cell death by influenza virus infection." Journal of virology 70, no. 11 (1996): 8128-8132.

Wada, Naoya, Miho Matsumura, Yoshiki Ohba, Nobuyuki Kobayashi, Takenori Takizawa, and Yoshinobu Nakanishi. "Transcription stimulation of the Fas-encoding gene by nuclear factor for interleukin-6 expression upon influenza virus infection." Journal of Biological Chemistry 270, no. 30 (1995): 18007-18012.)

ECs commented out; we will focus just on Tissue-Cells for the moment.

Release-DAMP/PAMP increased to random 10; random 5 not enough to initate PCDs

Dual responses (different from 0 to other) all changed, increment + 0.1

GSDMD-cleavage => Combined 3 Caspase pathways into OR statement, increment +0.1

PCD pathways ordered and annotated in tissue-cell-function code block. Written in reverse order

Need to figure out how to block RIPK1 with Caspase-8. Not really a problem at the moment since necroptosis is the least common PCD. Likely necroptosis requires immune cells as a source of TNF...

Added Life Turtle variable, distinct from Health is this is related to lifespan of individual cell. Apoptosis, Pyroptosis and Necroptosis decrease Life from 100 to 50, which then decrements by 1 until 0 at which point they die. This is important because it places a time limit on how long Pyroptotic cells produce IL1 and IL18, and attentuates the ongoing inflammation. This ability to have cells die separate from overall system Health status is important in being able to simiulate infection

Note new monitors that keep track of all pyroptotic cells and necroptotic cells (#-pyroptoticcells and #-necroptoticcells); we need this because "count" is insufficient as these cells die off. No need to do this for apopotic cells because they are not inflammogentic 



Notes: 1-21-23

Changed DAMP Load, random new Initial-DAMP-Insult
Tipping transtion zones seen in Initial DAMP Insult Parameter Sweep between 5 and 20 (higher numbers less insult). Transition from almost all die at ~ 8

Changed PAMP Load, random new Initial-PAMP-Insult
Tipping transition zones seen in Initial PAMP Insult Parameter Sweep between 5 and 20 
(higher number less insult). Transition from almost all die at ~8

Changed Infection insult:
Infection increases by spreadging beyond carrying capacity of patch (=100)
Can spread by amount in InfectSpreadIncrement, cycles by InfectionCycleSpreadIncrement
Currently cannot eradicate infection

KO experiments:
Inflammasome KO => block pyroptosis => Pretty big survival effect on DAMP
RIPK3 KO => block necroptosis => maybe some survival effect on DAMP
Caspase-1 KO => block NFkB => decent survival effect on DAMP



Diffusion Rates
  diffuse PAMP 0.4
  diffuse DAMP 0.4
  diffuse IL-1b 0.6
  diffuse IL-18 0.6
  diffuse FAS-L 0.6
  diffuse TNF 0.6

Evaporation Rates
  set PAMP PAMP * 0.8
  set DAMP DAMP * 0.8
  set IL-1b IL-1b * 0.8
  set IL-18 IL-18 * 0.8
  set FAS-L FAS-L * 0.99999
  set TNF TNF * 0.8





## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Replicates PAMP 1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
release-PAMP</setup>
    <go>go</go>
    <timeLimit steps="85"/>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="1000"/>
  </experiment>
  <experiment name="Replicates DAMP 1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="25"/>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="19"/>
    <enumeratedValueSet variable="background?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-ecs?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Graph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-leukocytes?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="injuryStep">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Replicates PAMP 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
release-PAMP</setup>
    <go>go</go>
    <timeLimit steps="25"/>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="499"/>
    <enumeratedValueSet variable="background?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-ecs?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Graph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-leukocytes?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="injuryStep">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="one pcd only" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
release-PAMP</setup>
    <go>go</go>
    <timeLimit steps="125"/>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum ([IL-1b] of patches)</metric>
    <metric>sum ([IL-18] of patches)</metric>
    <metric>sum ([PAMP] of patches)</metric>
    <metric>sum ([DAMP] of patches)</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="19"/>
  </experiment>
  <experiment name="Initial PAMP Insult Sweep" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup
release-PAMP</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum [PAMP] of patches</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="10"/>
    <steppedValueSet variable="initial-PAMP-insult" first="5" step="1" last="20"/>
  </experiment>
  <experiment name="Initial DAMP Insult Sweep" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup
release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum [DAMP] of patches</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="10"/>
    <steppedValueSet variable="Initial-DAMP-Insult" first="5" step="1" last="20"/>
  </experiment>
  <experiment name="DAMP Inflammasome KO Sweep" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup
release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum [DAMP] of patches</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="10"/>
    <steppedValueSet variable="initial-DAMP-insult" first="5" step="1" last="20"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;inflammasome&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DAMP RIPK3 KO Sweep" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup
release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum [DAMP] of patches</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="10"/>
    <steppedValueSet variable="Initial-DAMP-Insult" first="5" step="1" last="20"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;RIPK3&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DAMP caspase-1 KO Sweep" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup
release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>Total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>sum [DAMP] of patches</metric>
    <metric>sum [caspase-1] of turtles</metric>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="10"/>
    <steppedValueSet variable="initial-DAMP-insult" first="5" step="1" last="20"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;caspase-1&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="IAV infection" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <exitCondition>count (turtle-set ecs tissue-cells) &lt; 600</exitCondition>
    <metric>total-system-damage</metric>
    <metric>count apoptotic-cells</metric>
    <metric>count pyroptotic-cells</metric>
    <metric>count necroptotic-cells</metric>
    <metric>count (turtle-set ecs tissue-cells)</metric>
    <metric>count IAVs</metric>
    <metric>sum [ec-viral-particles] of patches</metric>
    <metric>sum [ic-viral-particles] of turtles</metric>
    <steppedValueSet variable="IAV-inoculum" first="1" step="10" last="100"/>
    <steppedValueSet variable="random-seed-counter" first="1" step="1" last="10"/>
  </experiment>
  <experiment name="GA1 DAMP Sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
Release-DAMP</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <enumeratedValueSet variable="initial-DAMP-insult">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA1 PAMP Sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
Release-PAMP</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <enumeratedValueSet variable="initial-PAMP-insult">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA1 IAV Sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA4 Salmonella Sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA4 Salmonella Sweep 150-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA4 EPEC Sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA4 EPEC Sweep 150-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 IAV Sweep 10 -300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300 Inflammasome KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;inflammasome&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300 RIPK3 KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;RIPK3&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300 GSDMD KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;GSDMD&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300 Inflammasome KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;inflammasome&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300 RIPK3 KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;RIPK3&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 IAV Sweep 10 -300 Inflammasome KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;inflammasome&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 IAV Sweep 10 -300 RIPK3 KO" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;RIPK3&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300 Anti-IL-1b" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="Anti-IL-1b-Rx">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 Salmonella Sweep 10-300 Anti-TNF" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
salmonella-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count salmonellas with [intracellular? = true]</metric>
    <metric>count salmonellas with [intracellular? = false]</metric>
    <enumeratedValueSet variable="salmonella-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="Anti-TNF-Rx">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300 Anti-IL-1b" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="Anti-IL-1b-Rx">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anti-TNF-Rx">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 EPEC Sweep 10-300 Anti-TNF" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
EPEC-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>count EPECs</metric>
    <enumeratedValueSet variable="EPEC-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="10" step="1" last="19"/>
    <enumeratedValueSet variable="Anti-IL-1b-Rx">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anti-TNF-Rx">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 IAV Sweep 10 -300 Anti-TNF" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="Anti-TNF-Rx">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anti-IL-1b-Rx">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GA5 IAV Sweep 10 -300 Anti-IL-1b" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
IAV-infect</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>Total-System-Health</metric>
    <metric>Total-System-Damage</metric>
    <metric>#-PyroptoticCells</metric>
    <metric>#-NecroptoticCells</metric>
    <metric>Count apoptotic-cells</metric>
    <metric>Count IAVs</metric>
    <metric>Sum [ec-viral-particles] of patches</metric>
    <enumeratedValueSet variable="IAV-inoculum">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="random-seed-counter" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="Anti-TNF-Rx">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anti-IL-1b-Rx">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="knockout?">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
