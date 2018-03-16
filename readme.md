# Overview

The contents here aim to simulate encounters of animals under varied survey designs using clustered point detectors of a fixed sampling effort. The simulated data will be analyzed using spatial capture-recapture (with the R package `oSCR`), and occupancy modeling (R package `unmarked`). 

The output from the analyses will be compared to obtain the most effective designs for occupancy analysis, SCR analysis, and potentially both. 

# Files contained

## functions.R

This file will contain all of the custom functions to create a specified design, simulate data, to fetch and push tasks to be done / completed, and perform the analysis on simulated data.

## SCRdesignSIM.R

This file is the original script provided by Andy trialing the basic idea for the simulation.

## SimWorkflow.pptx

This powerpoint file contains a workflow for organizing and executing the simulations. Topics left to resolve are:

* How to store the output data?
* Exactly what design considerations are we varying apart from cluster spacing, and traps per cluster? (*i.e.* are we varying population settings? Of what kind?)

## test.R

Temporary file to run some functions with parameters

## trial.txt

A temporary file for people to practice pulling/pushing data from/to Github.