readme.txt

About
---
BugEvo is a simulation using Lua and LOVE2D wherein bugs learn to hunt bacteria.
It is based off of the idea proposed in A.K. Dewdney's "Simulated evolution"
article appearing in the "Computer recreations" column of the May 1989 issue of
Scientific American Magazine.

Bug data structures exist on a 2D plane with age, energy, and "DNA" attributes.
Their DNA, initially randomized and then handed down and slightly mutated in
their offspring, determine their tendencies to move in particular directions.
"Bacteria," on which the bugs feed, randomly appear throughout the plane as time
passes. Bugs must eat in order to survive, and so bugs with movement tendencies
that allow them to find sufficient food will survive and later be able to
reproduce, passing on their DNA to their offspring. Bugs with unfavorable
tendencies will starve and not be able to pass on their DNA, as the principle of
natural selection dictates.

One can observe in this simulation that the most fit bugs are those who adapted
to move in only a few directions, creating long gliding patterns. The simulation
code within bugevo.lua is easily modifiable - alter its variables to observe the
bugs discovering different strategies to survive in their new environment.

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
-test.lua: fast but text-only simulation

Use
---
To run the simulation with its LOVE2D graphical presentation, move to the
directory containing the repository folder and run the command:

love bugevo

Change "bugevo" to the name of the repository folder if it differs. A LOVE2D
window will launch. Press the spacebar to start a new simulation, and press Q at
any time to close the window. Also provided is a test script which runs more
quickly than the normal simulation, but only produces text output in the form of
information about a random bug within the population. To use the script, move
into the directory of the repository folder and run the command:

lua test.lua

A constant inside the script determines for how long the simulation will run,
set at 30,000 iterations by default. A constant inside the simulation determines
at what interval the population is sampled for a bug's attributes.
