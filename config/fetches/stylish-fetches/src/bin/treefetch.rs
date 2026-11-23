use stylish_fetches::{build_tree, run, Config, ModelBuilder, Rgb};
fn main() {
    let cfg = Config::new("treefetch", Rgb{r:70,g:220,b:90}, Rgb{r:150,g:90,b:40}, true);
    let mut b = ModelBuilder::new(); build_tree(&mut b); run(cfg, b);
}
