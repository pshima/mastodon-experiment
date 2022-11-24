# Mastodon experiment

This is a repo for messing around with Mastodon.  There are a few goals on this:

* Learn how mastodon works and be able to install and operate a server.
* Build out some operational monitoring that could be used by other mastodon operators.
* Run it in AWS and show public cost consumption and scaling.  Maybe expand to other cheaper providers.
* Attempt to abstract some functionality to serverless.

This is all overkill for any of my needs and is meant as a fun experiment for learning only.

## Architecture
We're going to start with a very simple basic app setup on AWS.

Phase 1
Internet -> Round Robin DNS -> Mastodon EC2 Instance running all components, no autoscaling

Phase 2
Internet -> ALB -> Autoscaled Mastodon

Phase 3
Internet -> ALB -> Autoscaled App Mastodon -> AWS DB and Cache needs

Phase 4
Internet -> ALB -> Autoscaled App Mastodon -> AWS DB and Cache needs
                -> Lambda URL Paths

I barely know anything about Mastodon architecture or needs so may need to modify this.

Is EKS in here somewhere?  maybe.

## AWS Setup
We setup a brand new account and we'll skip using the default VPC and setup everything we need from scratch.


