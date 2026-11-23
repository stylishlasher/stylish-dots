use stylish_fetches::{build_skeleton, run, Config, ModelBuilder, Rgb};
fn main() {
    let cfg = Config::new("skeletonfetch", Rgb{r:255,g:200,b:40}, Rgb{r:190,g:195,b:205}, true);
    let mut b = ModelBuilder::new(); build_skeleton(&mut b); run(cfg, b);
}
