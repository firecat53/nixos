{
  home.file.".config/swayimg/config" = {
    text = ''
      [list]
      all=yes

      [keys]
      c = exec wl-copy < "%"
      C = exec wl-copy "%"
      j = next_file
      k = prev_file
      H = first_file
      L = last_file
    '';
  };
}
