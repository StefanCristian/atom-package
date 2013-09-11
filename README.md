atom-package 1.0
================

Atom packages built by Gentoo Portage or others tool.

What I define a atom package:

A GNU/Linux installed package that has a full satisfied set of libraries put into a single directory.
For example you build a program with libraries and files from all other dependencies of the program, but those deps
usually don't have the right development libraries or files for the current developed program ( or even if they have the
right files but too many unneeded ones ), what do you do?

You take the right libraries you need from that dependency package, put them in the same directory as your program, and 
compile or configure your program in order to use them from where you have put them. The GNU/Linux packages will be more 
complete and installation will occur smoother. And also reconfiguration will be easier.

The main idea is to have all the needed files put into a single package, including the needed files from other deps
or auxiliary deps.

That's that, off to work now and make the Free Software Humanity pride!
