const buildTarget* {.strdefine: "buildTarget".}: string = "arm_cm"

when buildTarget == "arm_cm":
  include port_arm_cm
