{ pkgs }:
{
  today = pkgs.callPackage ./today { };
  # Builder function: call with { title, groups } to produce a static site.
  dashboard = pkgs.callPackage ./dashboard { };
}
