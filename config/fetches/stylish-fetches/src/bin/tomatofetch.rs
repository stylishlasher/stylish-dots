use stylish_fetches::{build_tomato, run, Config, ModelBuilder, Rgb};
fn main() {
    let cfg = Config::new("tomatofetch", Rgb{r:255,g:70,b:60}, Rgb{r:70,g:200,b:80}, true);
    let mut b = ModelBuilder::new(); build_tomato(&mut b); run(cfg, b);
}
