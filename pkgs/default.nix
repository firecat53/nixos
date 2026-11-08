{ pkgs }:
{
  today = pkgs.callPackage ./today { };
  phanpy = pkgs.callPackage ./phanpy { };
  # Builder function: call with { title, groups } to produce a static site.
  dashboard = pkgs.callPackage ./dashboard { };
}
