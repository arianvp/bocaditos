#!/bin/sh
nix shell -f env.nix ${@:+--command "$@"}