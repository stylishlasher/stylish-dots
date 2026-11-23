use stylish_fetches::{build_key, run, Config, ModelBuilder, Rgb};
fn main() {
    let cfg = Config::new("keyfetch", Rgb{r:255,g:200,b:40}, Rgb{r:190,g:195,b:205}, false);
    let mut b = ModelBuilder::new(); build_key(&mut b); run(cfg, b);
}
