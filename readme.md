# Overview

The contents here aim to simulate encounters of animals under varied survey designs using clustered point detectors of a fixed sampling effort. The simulated data will be analyzed using spatial capture-recapture and occupancy modeling. 

The output from the analyses will be compared to obtain the most effective designs for occupancy analysis, SCR analysis, and potentially both. 

# Files contained

## SCRdesignSIM.R

This file is the original script provided by Andy trialing the basic idea for the simulation.

## SimWorkflow.pptx

This powerpoint file contains a workflow for organizing and executing the simulations. Topics left to resolve are:

* How to store the output data?
* Exactly what design considerations are we varying apart from cluster spacing, and traps per cluster? (*i.e.* are we varying population settings? Of what kind?)

## build.cluster.R

Function included to build clustered traps in only square configurations.

## build.cluster.alt.R

Function included to build clustered traps in sub-square configurations.

## functionsSQL.R

Functions contained to execute SQL transactions to update tasks to be completed.

## intlikRcpp.cpp

C++ implementation of SCR likelihood calculation

## nullSCR testscript.R

Test for application of analytical tools to multiple simulated sampling scenarios.

## simSCR.R

Function to simulate SCR and occupancy data. 

## test.R

Temporary file to run some functions with parameters

## testSQL.R

Temporary file to test the automatic assignment of tasks.