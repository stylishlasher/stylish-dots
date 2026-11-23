use stylish_fetches::{build_stool, run, Config, ModelBuilder, Rgb};
fn main() {
    let cfg = Config::new("stoolfetch", Rgb{r:200,g:150,b:90}, Rgb{r:160,g:110,b:60}, true);
    let mut b = ModelBuilder::new(); build_stool(&mut b); run(cfg, b);
}
