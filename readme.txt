readme.txt

About
---
BugEvo is a simulation using Lua and LOVE2D wherein bugs learn to hunt bacteria;
its idea was proposed by A.K. Dewdney in Scientific American Magazine.

Bug data structures exist on a 2D plane with age, energy, and "DNA" attributes.
Their DNA, initially randomized and then handed down and slightly mutated in
their offspring, determine their tendencies to move in particular directions.
"Bacteria," on which the bugs feed, randomly appear throughout the plane as time
passes. Bugs must eat in order to survive, and so bugs with movement tendencies
that allow them to find sufficient food will survive and later be able to
reproduce, passing on their DNA to their offspring. Bugs with unfavorable
tendencies will starve and not be able to pass on their DNA, as the principle of
natural selection dictates.

One can observe in this simulation that successful populations generally evolve
to move across the screen in a single direction as a herd! 

License
---
The contents of this repository are made available under the MIT License.

Requirements
---
The project was developed using Lua 5.3.4 and LOVE2D 0.8.0.

Contents
---
-.gitattributes
-bugevo.lua: the simulation code
-license.txt: a copy of the MIT License
-main.lua: graphical representation of the simulation using LOVE2D
-readme.txt: this readme
-test.lua: text-only simulation

Use
---
To run the simulation with its LOVE2D graphical presentation, move to the
directory containing the repository folder and run the command:

love bugevo

Change "bugevo" to the name of the repository folder if it differs. A LOVE2D
window will launch. Press the spacebar to start a new simulation, and press Q at
any time to close the window. Also provided is a test script which periodically
reports information on a random bug within a simulation's population. To use
this script, move into the the repository folder directory and run the command:

lua test.lua
