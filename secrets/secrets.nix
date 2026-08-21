let
  P52 = "age153tc5aan357ft4ad0f6xkd4ytzrcm954efawq66q3xc4vj7fn5wse47f5w";
  itx = "age1vfegnh9nufga7yg9qtvuwenattaj9kz5lvx57g0xtfynln9tscdswch8pw";
in
{
  "github-token.age".publicKeys = [ P52 itx ];
  "donetick-token.age".publicKeys = [ P52 itx ];
  "cf-access-client-secret.age".publicKeys = [ P52 itx ];
}


#nix run github:ryantm/agenix -- -e donetick-token.age
