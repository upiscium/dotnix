{ ... }: {
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(meta, esc)";
          # capslock = "esc";
          muhenkan = "leftalt";
        };
        # control = {
        #   h = "backspace";
        #   j = "enter";
        # };
      };
    };
  };
}
