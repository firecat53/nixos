{
  pkgs,
  ...
}:{
  # Normal user
  users.users.paul = {
    isNormalUser = true;
    uid = 1001;
    # initial password: paulmonti
    initialHashedPassword = "$6$Ph0uPDTYrW990CKh$YlLe69811HhVF0Wnv9nkv2do3ZhjUTollyeiKKMttR1XoG/fxNLQI1.vHQihnUMxnIpExYhWw43EGbcAY08l./";
  };
  environment.systemPackages = with pkgs; [
    google-chrome
  ];
}
