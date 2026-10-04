{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    ollama-cuda
  ];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    environmentVariables = {
      OLLAMA_FLASH_ATTANTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
    port = 11434;
    host = "0.0.0.0";
    openFirewall = true;
  };

  services.open-webui = {
    enable = true;
    port = 3000;
    host = "0.0.0.0";
    openFirewall = true;
    environment = {
      OLLAMA_API_BASE_URL = "http://localhost:11434";
    };
  };
}
