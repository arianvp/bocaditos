{ system ? builtins.currentSystem}: (import ./. { inherit system; }).shell
