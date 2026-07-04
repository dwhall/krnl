## Copyright 2026 Dean Hall See LICENSE for details
##

import proj, signal

type
  ## Events are the fundamental and primary communication between Actrs.
  ## Events are posted from one Actr to a child Actr,
  ## or published so that every Actr might receive the Event.
  ## EventValue is a project-defined datatype.
  Event* = object
    sig*: Signal
    val*: EventValue
