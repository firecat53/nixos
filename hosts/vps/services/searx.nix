{
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.unstable.searxng
  ];
  services.searx = {
    enable = true;
    package = pkgs.unstable.searxng;
    settings = {
      server = {
        port = 8888;
        bind_address = "127.0.0.1";
        secret_key = "64ZapANvagul";
        image_proxy = true;
        method = "POST";
      };
      search = {
        autocomplete = "";
      };
      ui = {
        default_locale = "en";
      };
      engines = [
        # Disable because captcha/blocked or returning nothing.
        {
          name = "duckduckgo";
          disabled = true;
        }
        {
          name = "startpage";
          disabled = true;
        }
        {
          name = "startpage images";
          disabled = true;
        }
        {
          name = "brave";
          disabled = true;
        }
        {
          name = "brave.images";
          disabled = true;
        }
        # Disable image search returns with line icons and vendor logos.
        {
          name = "lucide";
          disabled = true;
        }
        {
          name = "devicons";
          disabled = true;
        }
        # 403s every thumbnail, server-side too.
        {
          name = "artic";
          disabled = true;
        }
        {
          name = "wikidata";
          disabled = true;
        }
        {
          name = "wttr.in";
          disabled = true;
        }
        # Mainstream coverage in addition to google cse
        {
          name = "bing";
          disabled = false;
        }
        {
          name = "duckduckgo web";
          disabled = false;
        }
        # Indie/personal-site index; genuinely different results to the above.
        {
          name = "searchmysite";
          disabled = false;
        }
        # 50% ReadTimeout, and its API 403s when queried directly.
        {
          name = "pinterest";
          disabled = true;
        }
        # Other search engine options
        {
          name = "google images";
          disabled = false;
        }
        {
          name = "mojeek images";
          disabled = false;
        }
        {
          name = "mwmbl";
          disabled = false;
        }
        {
          name = "nixos wiki";
          disabled = false;
        }
        {
          name = "duckduckgo weather";
          disabled = false;
        }
        {
          name = "openmeteo";
          disabled = false;
        }
        {
          name = "goodreads";
          disabled = false;
        }
        {
          name = "imdb";
          disabled = false;
        }
        {
          name = "tmdb";
          disabled = false;
        }
      ];
    };
  };
}
