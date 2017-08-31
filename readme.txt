readme.txt

About
---
BugEvo is a simulation using Lua and LOVE2D wherein bugs learn to hunt bacteria.
It is based off of the idea proposed in A.K. Dewdney's "Simulated evolution"
article appearing in the "Computer recreations" column of the May 1989 issue of
Scientific American Magazine. One can observe the bugs evolve to move across the
virtual petri dish in a way that nets them the most bacteria, while natural
selection removes bugs with inefficient movement patterns through starvation. In
this implementation, one can expect the bugs to evolve from "jittery" movement
patterns to long, gliding patterns.

License
---
The contents of this repository are made available under the MIT License.

Requirements
---
The project was developed using Lua 5.3.4 and LOVE2D 0.8.0.

Contents
---
-.gitattributes
-bugevo.lua
-license.txt
-main.lua
-readme.txt
-test.lua

Use
---
To run the simulation with its LOVE2D graphical presentation, move to the
directory containing the repository folder and run the command:

love bugevo

Change "bugevo" to the name of the repository folder if it differs. Also
provided is a test script which runs more quickly than the normal simulation,
but only produces text output in the terminal. To use the script, move into the
directory of the repository folder and run the command:

lua test.lua

A constant inside the script determines for how long the simulation will run,
set at 30,000 iterations by default.
