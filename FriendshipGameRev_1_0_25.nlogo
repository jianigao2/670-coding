;;
;; Friendship games 
;;
;; Based on PJ Lamberson "Friendship Games" presented at the
;;   26th Annual Conference of the Eastern Economics Association
;;   in New York, NY.
;;
;; Copyright (c) 2011 David S. Dixon
;;
globals [
  percent-playing-x ;; the number of turtles playing x
  number-of-links   ;; the total number of edges in the net
  changing?         ;; true at the end of a cycle in which at least one turtle changed
  clustering        ;; the clustering coefficient
  total-connections ;; the number of connections
  connectedness     ;; the degree
  number-of-ties    ;; the order for a turtle
  running?
  
  substitute?       ;; if true, use the substitute strategy, otherwise complement
  threshold         ;; the threshold for deciding strategy
 
  initial-distribution ;; the initial distribution of  
  distribution-start ;; starting value for intitial distribution
  distribution-end   ;; ending value for intitial distribution
  distribution-step  ;; step size for initial distribution
  number-of-steps    ;; number of steps for initial distribution

  visit-all?         ;; if true, cycle through all turtles before starting again
  
  turtle-list       ;; the list of turtles for cycling through all
  turtle-counter    ;; the current turtle when cycling through all
  
  r-squared         ;; r-squared of the degree distribution
  
  y-max             ;; maximum y for a histogram
  
  number            ;; the number of turtles

  network-type      ;; set from the network topology slider  
]

;;
;; local to each link
;;
links-own [
  agreeing?   ;; set to true if the nodes at both ends play the same strategy
]

;;
;; local to each turtle
;;
turtles-own [
  payoff-x    ;; the payoff for playing strategy x
  payoff-y    ;; the payoff for playing strategy y
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup button
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  set running? false
  set changing? true
  set number number-of-turtles       ;; save gui setting
  set network-type network-topology  ;; save gui setting
  
  initialize-network   ;; initialize the turtles
  initialize-turtles   ;; initialize starting strategies
  
  do-timeseries-plots     ;; start the plot
  link-to-friends         ;; create the links based on user-selected topology
  update-layout           ;; update the graphic representation
  update-network-globals  ;; update the global variables
  do-network-plots        ;; plot the histogram
  
  set threshold round (peer-pressure * number-of-friends)
  
  ifelse turtle-chooser = "Cycle-through-all-randomly" 
    [
      set visit-all? true
      set turtle-list [who] of turtles 
      set turtle-counter 0
    ]
    [set visit-all? false]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Go button
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  set number-of-turtles number       ;; restore gui setting
  set network-topology network-type  ;; restor gui setting

  if strategic-model = "Strategic-complement" [set substitute? false]
  if strategic-model = "Strategic-substitute" [set substitute? true]
  ifelse running? 
  [
    ifelse ticks > cutoff-time and initial-distribution >= distribution-end
    [
      set running? false
      stop
    ]
    [
      run-this-one
    ]
  ]
  [run-new-one]
 
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start a new series of runs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to run-new-one
  reset-timeseries-plots
  if strategic-model = "Strategic-complement" 
  [
    set distribution-start 0.1
    set distribution-end 0.5
    set number-of-steps 9
  ]
  if strategic-model = "Strategic-substitute"
  [
    set distribution-start 0.1
    set distribution-end 0.9
    set number-of-steps 9
  ]
  set distribution-step (distribution-end - distribution-start) / (number-of-steps - 1)
  
  set initial-distribution distribution-start
  initialize-turtles
  set running? true
  run-this-one
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; run the current series of runs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to run-this-one
  if ticks > cutoff-time
  [
    set initial-distribution initial-distribution + distribution-step
    initialize-turtles
    reset-ticks
    set-current-plot "Percent Playing X"
    plot-pen-up
    plotxy 0 100 * initial-distribution
    plot-pen-down
  ]
  if running?
  [
      set changing? false
      change-a-turtle
      update-variables
      tick
      do-timeseries-plots
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize the network
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to initialize-network
  set number-of-ties 0
  
  set-default-shape turtles "circle"

  if network-type != "preferential-attachment-network" [crt number]
  layout-circle turtles max-pxcor - 1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize the turtles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to initialize-turtles
  if any? turtles
  [
    ask turtles [ set color red ]
    ;; turn some of the turtles green
    ask n-of (number * (1 - initial-distribution)) turtles
      [ set color green ]
    update-variables
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Layout the network 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-layout
  if network-type != "preferential-attachment-network"
  [
    repeat 100 [
      layout
      display
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Layout the network
;; Copyright 2005 Uri Wilensky. All rights reserved.
;; The full copyright notice is in the Information tab.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright 2005 Uri Wilensky. All rights reserved.
;; The full copyright notice is in the Information tab.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report limit-magnitude [offset limit]
  if offset > limit [ report limit ]
  if offset < (- limit) [ report (- limit) ]
  report offset
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form the network based on 
;;    1) mean degree
;;    2) specified topology
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to link-to-friends
  sum-up-connectedness     ;; get the mean degree
  pick-network-type    ;; form the network based on user choice
  update-variables         ;; update the network-specific variables
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form the network based on user-
;;   specified topology
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to pick-network-type
  if network-type = "regular-random-network" [R-link-turtles]
  if network-type = "Gilbert-random-network" [G-link-turtles]
  if network-type = "Erdos-Renyi-random-network" [E-link-turtles]
  if network-type = "preferential-attachment-network" [PA-link-turtles]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form a regular random network - each 
;;   node has exactly number-of-friends 
;;   links.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to R-link-turtles
  ask turtles
    [ link-turtle-friends]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; utility for regular random network - 
;;   make the links for a single turtle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to link-turtle-friends
  ;; loop until this turtle has the right number of links, but
  ;;   break out if the number of loops exceeds a limit
  let counter 0 ;; counter to prevent infinite looping
  while [(count my-links) < number-of-friends and 10 * number-of-friends > counter]
  [
    set counter counter + 1
    let other-guy one-of other turtles with [count link-neighbors < number-of-friends]
    ;; this might be an already-linked turtle, which won't create a new link
    if nobody != other-guy [create-link-with other-guy]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form an Erdos-Renyi random graph - 
;;   each configuratoin of the same 
;;   degree is equally probable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to E-link-turtles
  let pLink number-of-friends / number ;; the link probability
  let degree 0
  while [degree < number-of-friends]
  [
    let fromTurtle one-of turtles
    ask fromTurtle
    [
      let toTurtle one-of other turtles
      if not link-neighbor? toTurtle
      [
         create-link-with toTurtle
         sum-up-connectedness
         set degree connectedness
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form a Gilbert random graph - each 
;;   edge is equally probable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to G-link-turtles
  let pLink number-of-friends / number ;; the link probability
  ask turtles 
  [
    ;; get links only with turtles greater than this one
    ;;   that way we only check each unique pair once
    let this-turtle who
    let next-turtle other turtles with [who > this-turtle]
    if next-turtle != nobody
    [
      ask next-turtle
      [
        if random-float 1 < pLink
        [
          create-link-with myself
        ]
      ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Form a preferential attachment random 
;;   graph - more popular nodes are more 
;;   popular because they're more popular
;; From Uri Weleski's Preferential 
;;   Attachment model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to PA-link-turtles
  crt 2
  ask turtle 0 [ create-link-with turtle 1]

  
  let mean-degree 0
  while [number > count turtles]
  [
    make-node find-partner
    layout
    sum-up-connectedness
    set mean-degree connectedness
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The next two methods are from the 
;;   Preferential Attachment model
;;   in the NetLogo Demo Library
;;
;; - Wilensky, U. (2005). NetLogo Preferential Attachment model. 
;;   http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment. 
;;   Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;; - Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. 
;;   Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; used for creating a new node
to make-node [old-node]
  crt 1
  [
    set color red
    if old-node != nobody
      [ create-link-with old-node [ set color green ]
        ;; position the new node near its partner
        move-to old-node
        fd 8
      ]
  ]
end

;; This code is borrowed from Lottery Example (in the Code Examples
;; section of the Models Library).
;; The idea behind the code is a bit tricky to understand.
;; Basically we take the sum of the degrees (number of connections)
;; of the turtles, and that's how many "tickets" we have in our lottery.
;; Then we pick a random "ticket" (a random number).  Then we step
;; through the turtles to figure out which node holds the winning ticket.
to-report find-partner
  let total random-float sum [count link-neighbors] of turtles
  let partner nobody
  ask turtles
  [
    let nc count link-neighbors
    ;; if there's no winner yet...
    if partner = nobody
    [
      ifelse nc > total
        [ set partner self ]
        [ set total total - nc ]
    ]
  ]
  report partner
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make a random turtle decide its 
;;   opinion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to change-a-turtle
  ifelse visit-all?
  [
    ;; cycle through all turtles randomly
    if turtle-counter = number
    [
      set turtle-list [who] of turtles
      set turtle-counter 0
    ]
    let next-turtle item turtle-counter turtle-list
    ask turtle next-turtle [ decide-new-opinion ]
    set turtle-counter turtle-counter + 1
  ]
  [
    ;; select any turtle at random
    ask one-of turtles [ decide-new-opinion ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make this turtle decide its 
;;   opinion based on the pay-offs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to decide-new-opinion
  ifelse substitute?
    [decide-new-substitute]
    [decide-new-complement]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make this turtle decide its 
;;   opinion given strategic complement
;;   pay-offs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to decide-new-complement
  let kx count link-neighbors with [color = red]
  ifelse kx >= threshold 
  [ play-x ]
  [ play-y ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make this turtle decide its 
;;   opinion given strategic complement
;;   pay-offs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to decide-new-substitute
  let kx count link-neighbors with [color = red]
  ifelse kx <= threshold 
  [ play-x ]
  [ play-y ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This turtle decides to play x
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to play-x
  ifelse color = red
  [ set changing? false]
  [
    ;; switches to x
    set color red
    set changing? true
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This turtle decides to play y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to play-y
  ifelse color = green
  [ set changing? false]
  [
    ;; switches to y
    set color green
    set changing? true
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update all the variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-variables
  update-links
  update-globals
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update the link variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-links
  ask links[
    set agreeing? ([color] of end1 = [color] of end2)
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update the global variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-globals
  let count-playing-x count turtles with [color = red]
  set percent-playing-x count-playing-x / number * 100
end
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update the network variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-network-globals
  set number-of-links count links
  sum-up-connectedness
  if 0 < number-of-links [sum-up-clustering]
end
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compute mean degree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to sum-up-connectedness
  if 0 < count turtles
  [
    set connectedness mean [count link-neighbors] of turtles 
  ]
end  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compute clustering coefficient
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to sum-up-clustering
  let number-of-twofold-links 0
  let number-of-closed-links 0
  ask links 
  [
    let this-end end1
    ask end2
    [
      ask link-neighbors
      [
        set number-of-twofold-links number-of-twofold-links + 1
        if member? this-end link-neighbors [set number-of-closed-links number-of-closed-links + 1]
      ]
    ]
  ]
  set clustering number-of-closed-links / number-of-twofold-links  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the timeseries plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to do-timeseries-plots
  set-current-plot "Percent Playing X"
  plot percent-playing-x
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reset the timeseries plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to reset-timeseries-plots
  set-current-plot "Percent Playing X"
  clear-plot
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plot a histogram of node degree, 
;;   overlaying a line plot of a binomial
;;   distribution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to do-network-plots
  set-current-plot "Degree Histogram"
  clear-plot

  ;; first, the histobram
  let max-range 1 + max [count link-neighbors] of turtles
  set-plot-x-range 0 max-range
  histogram [count link-neighbors] of turtles
  
  draw-distribution max-range
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the distribution curve
;;   depending on the kind of
;;   distribution used.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to draw-distribution[max-range]
  if network-type = "regular-random-network" [draw-regular max-range]
  if network-type = "Gilbert-random-network" [draw-binomial max-range]
  if network-type = "Erdos-Renyi-random-network" [draw-binomial max-range]
  if network-type = "preferential-attachment-network" [draw-powerlaw max-range]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the regular distribution 
;;   curve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to draw-regular[max-range]
  create-temporary-plot-pen "regular"
  plot-pen-up
  set-plot-pen-mode 0
  plotxy 0 0
  set-plot-pen-color red
  plot-pen-down
  let sse 0
  let sst 0
  foreach n-values max-range [?]
  [
    let k ?  
    let y 0
    if-else k = number-of-friends
    [
      ;; draw the expected distribution just inside the actual
      set y number * 0.99
      plotxy k + 0.05 0
      plotxy k + 0.05 y
      plotxy k + 0.95 y
      plotxy k + 0.95 0
    ]
    [
      set y 0
      plotxy k + 0.5 y
    ]
    let y-count count turtles with [k = count link-neighbors]
    set sse sse + (y - y-count) ^ 2
    set sst sst + y ^ 2
  ]
  set r-squared 1 - sse / sst
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the binomial distribution 
;;   curve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to draw-binomial[max-range]
  create-temporary-plot-pen "binomial"
  plot-pen-up
  set-plot-pen-mode 0
  plotxy 0 0
  set-plot-pen-color red
  plot-pen-down
  let p number-of-friends / number
  let sse 0
  let sst 0
  foreach n-values max-range [?]
  [
    let k ?  
    let y number * (choose number k) * p ^ k * (1 - p) ^ (number - k)
    plotxy k + 0.5 y
    let y-count count turtles with [k = count link-neighbors]
    set sse sse + (y - y-count) ^ 2
    set sst sst + y ^ 2
  ]
  set r-squared 0
  if sse < sst 
  [
    set r-squared 1 - sse / sst
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the power law distribution 
;;   curve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to draw-powerlaw[max-range]
  let gamma 2
  let normalizer number * 6 / pi ^ 2 ;; for gamma = 2
;;  let gamma 2.62 ;; from regression
;;  let normalizer number * 0.770 ;; for gamma = 2.62
;;  let gamma 1.93 ;; from regression
;;  let normalizer number * 0.583 ;; for gamma = 2.62
  set y-max round 1 + normalizer / 4
;;  set-plot-y-range 0 y-max 
  set-plot-y-range 0 number * 0.16
  create-temporary-plot-pen "powerlaw"
  plot-pen-up
  set-plot-pen-mode 0
  set-plot-pen-color red
  let p number-of-friends / number
  let sse 0
  let sst 0
  foreach n-values max-range [?]
  [
    let k ? + 1 
    let y normalizer * k  ^ (- gamma)
;;    if y < y-max [plotxy k - 0.5 y]
    plotxy k - 0.5 y
    plot-pen-down
    let y-count count turtles with [k = count link-neighbors]
    set sse sse + (y - y-count) ^ 2
    set sst sst + y ^ 2
  ]
  set r-squared 0
  if sse < sst 
  [
    set r-squared 1 - sse / sst
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Use the product formula to compute 
;;    n choose k
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report choose [n k]
  let choices 1   ;; default value in most cases is one
  if (k > 0)
  [ 
    ifelse (n <= 0)
    [ set choices 0 ]  ;; if n is zero and k isn't zero, value is zero
    [
      let diff n - k   ;; this is constant for the summation
      if (diff > 0)    ;; n choose n is zero
      [
        ;; get the product of k terms
        foreach n-values k [?]
        [
          ;; compute the product of all k terms
          set choices choices * (diff / (? + 1) + 1)
        ]
      ]
    ]
  ]
;;  type n type " " type k type " " print choices
  report choices
end 
@#$#@#$#@
GRAPHICS-WINDOW
524
10
891
398
25
25
7.0
1
10
1
1
1
0
0
0
1
-25
25
-25
25
1
1
1
ticks

MONITOR
91
357
168
402
% playing x
percent-playing-x
1
1
11

PLOT
195
248
480
396
Percent Playing X
time
%
0.0
5.0
0.0
100.0
true
false
PENS
"percent" 1.0 0 -2674135 true

SLIDER
13
13
222
46
number-of-turtles
number-of-turtles
0
2000
1000
100
1
NIL
HORIZONTAL

BUTTON
230
13
310
46
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
89
319
169
352
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
13
52
222
85
number-of-friends
number-of-friends
0
100
10
1
1
NIL
HORIZONTAL

MONITOR
228
149
318
194
# of Links
number-of-links
17
1
11

CHOOSER
13
139
222
184
strategic-model
strategic-model
"Strategic-complement" "Strategic-substitute"
1

MONITOR
230
51
308
96
clustering
clustering
6
1
11

MONITOR
229
100
309
145
degree
connectedness
1
1
11

PLOT
322
67
519
217
Degree Histogram
degree
count
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 1 -16777216 true

CHOOSER
13
189
223
234
network-topology
network-topology
"regular-random-network" "Erdos-Renyi-random-network" "Gilbert-random-network" "preferential-attachment-network"
0

CHOOSER
13
89
222
134
turtle-chooser
turtle-chooser
"Cycle-through-all-randomly" "Choose-randomly"
1

MONITOR
382
18
463
63
R Squared
r-squared
4
1
11

SLIDER
72
245
183
278
cutoff-time
cutoff-time
1000
10000
4000
1000
1
NIL
HORIZONTAL

SLIDER
72
281
183
314
peer-pressure
peer-pressure
0
1
0.4
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
FriendshipGame Rev. 1.0

WHAT IS IT?
-----------
This is a friendship game model. A friendship game is a kind of network game: a game theory model on a network. A game starts with a model of a network of turtles. Each turtle considers as its friends every other turtle that is linked directly on the network. Each turtle decides what strategy to play, x or y, based on the choices made by its friends. How the friends influence the choice depends on whether the game is one of strategic substitutes or strategic complements.

A strategic substitute is something that, if one of its friends is already doing it, a turtle has no reason to also do it. For example, if a turtle gets a pickup truck, all its friends can borrow it, so they have no need to buy one, too.

A strategic complement is something that, if a majority of its friends are doing it, a turtle will also do it. For example, if the majority of a turtles friends are using NetLogo, then the turtle has an incentive to also use NetLogo.

This project is based on friendhip game models introduced by PJ Lamberson in a presentation in the Agent-based Computation Economics sessions  of the Eastern Economics Association conference in February 2011.

HOW TO USE IT
-------------
In most cases you'll want to set the speed slider all the way to the FASTER end.

Choose the NUMBER of turtles. The smaller the number, the less time it takes to build the network, but the less interesting the outcome.

Choose the NUMBER-OF-FRIENDS for each turtle. This is the mean degree of each turtle, which means the average number of friends a turtle will have. Depending on the network topology, that actual number for any given turtle may differ considerably from this. NOTE: the perferential attachment network topology always yields a NUMBER-OF-FRIENDS of about two. In this case, NUMBER-OF-FRIENDS is only used in the payoff calculation. See the STRATEGIES section for information about this. 

Set the TURTLE-CHOOSER to "Choose randomly" to let a single turtle, chosen at random, decide whether to play X or Y at each tick. "Cycle through all randomly" shows what happens if every turtle gets one chance to decide strategy before cycling through all the turtles again.

Use the STRATEGIC-MODEL to set whether turtles play a strategic substitute or a strategic complement. See the STRATEGIES section for more about this.

Set NETWORK-TOPOLOGY to one of topologies described in NETWORK TOPOLOGIES section.

Click the SETUP button. This will create the network, which may take a long time, depending on topology, NUMBER of turtles, and NUMBER-OF-FRIENDS. When it's done, the graph will be updated with a representation of the network, but this will not be very informative, usually. Also, when SETUP is done, the network monitors will be updated. See the section on NETWORK MONITORS for information about these.

Set the CUTOFF-TIME to the tick at which you want to stop each simulation.

Set the PEER-PRESSURE. This is the fraction of a turtle's friends that will influence the turtle. See the STRATEGIES section for information on this parameter.

Click the GO button to start the simulations. The % PLAYING X will start at different levels, and will change over time based on the STRATEGIC-MODEL. See the THINGS TO NOTICE section. You can click the GO button again at any time to suspend the simulation. While the  simulation is running, the runtime monitors will be updated. See the section on RUNTIME MONITORS for information about these.

NETWORK TOPOLOGIES
------------------
These are the topologies currently implemented:

"regular-random-network" - A regular network is one in which each turtle has exactly the same number of friends, NUMBER-OF-FRIENDS.

"Erdos-Renyi-random-network" - This is kind of Bernoulli random network, in which each turtle has a different number of friends. The number of friends (the degree) of each turtle comes from a binomial distribution with a mean of NUMBER-OF-FRIENDS. This project constructs an Erdos-Renyi random network by adding connections between random pairs of turtles until the mean degree is equal to NUMBER-OF-FRIENDS.

"Gilbert-random-network" - This is another kind of Bernoulli random network. This project constructs a Gilbert random network by looping over all possible pairs of turtles and creates a connection between them with probability p = NUMBER-OF-FRIENDS / NUMBER.

"preferential-attachment-network" - This is a network model from the Perferential Attachment model in the NetLogo Models Library. The network is constructed by creating new turtles and connecting them to other turtles, with a preference for turtles that have more connections. This results in a power-law (scale-free) distribution with an exponent of about -2.

STRATEGIES
----------
In game theory, a player's choices are called strategies. In this project, the turtles (players) have strategies based on the strategies being played by their friends on the network. In each case a turtle has the choice between playing strategy X and strategy Y.
How the turtle makes the decision based on strategy type.

"Strategic-substitute" - A strategic substitute is something that, if one of its friends 
is doing it, a turtle has no reason to also do it. For example, if a turtle gets a pickup truck, all its friends can borrow it, so they have no need to buy one, too. A turtle will
play strategy X only if fewer than a threshold number of friends are playing it. Otherwise, the turtle plays strategy Y. The threshold is PEER-PRESSURE * NUMBER-OF-FRIENDS.

"Strategic-complement" - A strategic complement is something that, if a majority of its 
friends are doing it, a turtle will also do it. For example, if the majority of a turtles friends are using NetLogo, then the turtle has an incentive to also use NetLogo. A turtle will play strategy X only if more than a threshold number of friends are playing it. Otherwise, the turtle plays strategy Y.  The threshold is PEER-PRESSURE * NUMBER-OF-FRIENDS.

NETWORK MONITORS
----------------
These are monitors on the network topology:

CLUSTERING - this is the clustering coefficient (Newman, 2010). This is the probability that any two of a turtles friends are also friends with each other.

DEGREE - this is the current average (mean) degree for all the turtles. When SETUP is clicked, this will start at zero and increase until it's approximately the same as NUMBER-OF-FRIENDS. 

NUMBER OF LINKS - this is the total number of links between turtles.

DEGREE HISTOGRAM - this is a histogram of turtle degrees. The number of turtles with the given degree is shown as a bar, and the theoretical distribution is shown as a red line.

R SQUARED - this is the R-Squared metric for the degree histogram. This is the closeness of fit between the bars and the red line.

RUNTIME MONITORS
----------------
These are monitors on the simulation:

% PLAYING X - The percent of total turtles currently playing strategy X. Turtles playing X are shown red, while those playing Y are shown green.

PERCENT PLAYING X timeseries plot shows the results of the simulations so far, for each starting percentage.

THINGS TO NOTICE
----------------
When you execute SETUP, DEGREE will increase. The NUMBER OF LINKES will also increase. CLUSTERING will increase, but not by much. 

When SETUP is done (the button is no longer dark), DEGREE should be very close to NUMBER-OF-FRIENDS. NUMBER OF LINKS will be in the neighborhood of 0.5 * NUMBER * NUMBER-OF-FRIENDS. 

When you execute GO, % PLAYING X will start at a low value and the PERCENT PLAYING X timeseries graph will track it as it changes. When TICKS is equal to the CUTOFF-TIME, a new graph will start at a new % PLAYING X value. For a strategic substitute, the starting values of % PLAYING X range from 10% to 90% in steps of 10%. For a strategic complement, the starting values of % PLAYING X range from 10% to 50% in steps of 5%.

For a strategic substitute, all starting values will converge to about the same value (equilibrium) within about 1000 ticks.

For a strategic complement, lower starting values will converge to zero (lower equilibrium), and higher starting values will converge to 100% (upper equilibrium), some taking a more than 4000 ticks. 

For a strategic substitute, the equilibrium value is different for different network topoligies.

For a strategic complement, the dividing line between starting values that go to the upper equilibrium versus the lower equilibrium is different for different network topoligies.

THINGS TO TRY
-------------
See how changing the network topology changes the outcomes.

See how reducing the NUMBER of turtles affects the outcome. (You can try increasing it, but building the network can take a long time!)

See how changing the NUMBER-OF-FRIENDS affects the outcome. (Here, again, increasing can increase the time by quite a lot.)

See what happens when you change the TURTLE-CHOOSER.

EXTENDING THE MODEL
-------------------
These turtles are all the same and they're all rational. A next step would be to add behaviors based on a variety of payoffs, or on non-rational behavior, or on global knowledge. For example:

What if some turtles won't change their minds no matter what their friends are doing? 

What if some turtles change their minds all the time, even if all their friends come to an equilibrium?

What if some turtles are really good at guessing the equilibrium and go there sooner?

What if some turtles are contrarians, doing the opposite of whatever the majority of turtles are doing?

CREDITS AND REFERENCES
----------------------

Lamberson, P.J., http://andromeda.rutgers.edu/~jmbarr/EEA2011/lamberson.pdf

Newman, M. E. J., Networks: An Introduction, Oxford: Oxford University Press, 2010.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (2005). NetLogo Preferential Attachment model. http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

HOW TO CITE
-----------
If you mention this model in an academic publication, we ask that you include the following citations.

For the model itself:
- Dixon, David S. (2011).  Friendship Games.

For the NetLogo software:
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

COPYRIGHT NOTICE
----------------
Copyright 2011 David S. Dixon. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) these copyright notices are included.
b) this model will not be redistributed for profit without permission from David S. Dixon. Contact David S. Dixon for appropriate licenses for redistribution for profit.
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
