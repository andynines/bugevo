readme.txt

About
---
BugEvo is a simulation using Lua and LOVE2D wherein bugs learn to hunt bacteria.
It is based off of the idea proposed in A.K. Dewdney's "Simulated evolution"
article appearing in the "Computer recreations" column of the May 1989 issue of
Scientific American Magazine. One can observe the bugs evolve to move across the
virtual petri dish in a way that nets them the most bacteria, while natural
selection removes bugs within inefficient movement patterns through starvation.
In this implementation, one can expect the bugs to evolve from "jittery"
movement patterns to long, gliding patterns.

License
---
The contents of this repository are made available under the MIT License.

Requirements
---
The program was developed using Lua 5.3.4 with LOVE2D 0.8.0.

Development
---
BugEvo is still undergoing changes to maximize the speed of the simulation. In
addition, the optimal simulation constants to yield clear results of "evolution"
having taken place have yet to be found.

Use
---
LOVE2d programs like BugEvo can be run in one of two ways:
-From a current directory containing the repository folder, pass the command
'love bugevo' changing the name of the folder as necessary.
-Using BugEvo's .love file (will be added in a future commit)
Press the spacebar to begin a new simulation. Press Q at any time to quit.
