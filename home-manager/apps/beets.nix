let
  music_library = "/mnt/media/music";
in
{
  programs.beets = {
    enable = true;
    settings = {
      directory = "${music_library}";
      library = "${music_library}/.beets/library.db";
      import = {
        copy = true;
        write = true;
        log = "${music_library}/.beets/log.txt";
      };
      paths = {
        "genre:kids" = "Kids/$albumartist/$album%aunique{}/$track $title";
        "genre:christmas" = "Christmas/$albumartist/$album%aunique{}/$track $title";
        "albumtype:soundtrack" = "Soundtracks/$album/$track $title";
        "singleton" = "Singles/$artist/$title";
      };
      plugins = "embedart fetchart lastgenre musicbrainz";
      lastgenre.count = 3;
    };
  };
}
