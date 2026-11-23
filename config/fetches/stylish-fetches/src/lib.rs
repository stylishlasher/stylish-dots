//! Shared renderer and models for stylish 3D fetches.
//! UNSTABLE/BETA, kind of abandoned - but rewritten in Rust.

use std::env;
use std::f32::consts::PI;
use std::fs;
use std::io::{self, Write};
use std::process;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

#[derive(Clone, Copy, Debug, Default)]
pub struct Rgb { pub r: u8, pub g: u8, pub b: u8 }

#[derive(Clone, Copy, Debug)]
pub struct Pt { pub x: f32, pub y: f32, pub z: f32, pub nx: f32, pub ny: f32, pub nz: f32, pub m: u8 }

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RotateMode { Horizontal, Vertical, Random }

impl RotateMode {
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "h" | "horizontal" | "y" => Some(Self::Horizontal),
            "v" | "vertical" | "x" => Some(Self::Vertical),
            "r" | "random" => Some(Self::Random),
            _ => None,
        }
    }
}

pub struct Config {
    pub name: &'static str,
    pub color: Rgb,
    pub accent: Rgb,
    pub label_color: Rgb,
    pub label_set: bool,
    pub rainbow: bool,
    pub speed: f32,
    pub size: f32,
    pub height: i32,
    pub rotate: RotateMode,
    pub frames: usize,
    pub no_info: bool,
    pub no_color: bool,
    pub has_accent: bool,
}

impl Config {
    pub fn new(name: &'static str, default_color: Rgb, accent: Rgb, has_accent: bool) -> Self {
        Self {
            name, color: default_color, accent, label_color: default_color, label_set: false,
            rainbow: false, speed: 1.0, size: 1.0, height: 16, rotate: RotateMode::Horizontal,
            frames: 0, no_info: false, no_color: env::var_os("NO_COLOR").is_some(), has_accent,
        }
    }
}

fn hsv(h: f32, s: f32, v: f32) -> Rgb {
    let c = v * s;
    let hh = (h.rem_euclid(360.0)) / 60.0;
    let x = c * (1.0 - ((hh % 2.0) - 1.0).abs());
    let m = v - c;
    let (r, g, b) = match hh as i32 {
        0 => (c, x, 0.0), 1 => (x, c, 0.0), 2 => (0.0, c, x),
        3 => (0.0, x, c), 4 => (x, 0.0, c), _ => (c, 0.0, x),
    };
    Rgb { r: ((r+m)*255.0) as u8, g: ((g+m)*255.0) as u8, b: ((b+m)*255.0) as u8 }
}

fn parse_hex(s: &str) -> Option<Rgb> {
    let s = s.strip_prefix('#').unwrap_or(s);
    if s.len() != 6 || !s.chars().all(|c| c.is_ascii_hexdigit()) { return None; }
    let v = u32::from_str_radix(s, 16).ok()?;
    Some(Rgb { r: ((v>>16)&255) as u8, g: ((v>>8)&255) as u8, b: (v&255) as u8 })
}

pub fn parse_color(s: &str) -> Option<Rgb> {
    let named = [
        ("red",(255,60,60)),("green",(70,220,90)),("yellow",(255,220,60)),("blue",(70,120,255)),
        ("magenta",(230,70,220)),("cyan",(60,220,230)),("white",(235,235,235)),("orange",(255,140,30)),
        ("pink",(255,130,190)),("purple",(160,90,255)),("gold",(255,200,40)),("silver",(190,195,205)),
        ("teal",(30,190,170)),("lime",(160,255,60)),
    ];
    for (n,(r,g,b)) in named { if s.eq_ignore_ascii_case(n) { return Some(Rgb{r,g,b}); } }
    parse_hex(s)
}

fn truecolor() -> bool {
    match env::var("COLORTERM") {
        Ok(v) if v.contains("truecolor") || v.contains("24bit") => true,
        Ok(v) if v.is_empty() => false,
        Ok(_) => true,
        Err(_) => true,
    }
}

fn put_color(buf: &mut Vec<u8>, c: Rgb, tc: bool) {
    if tc { let _ = write!(buf, "\x1b[38;2;{};{};{}m", c.r, c.g, c.b); }
    else {
        let idx = 16 + 36*((c.r as i32*5+127)/255) + 6*((c.g as i32*5+127)/255) + ((c.b as i32*5+127)/255);
        let _ = write!(buf, "\x1b[38;5;{}m", idx);
    }
}

fn term_size() -> (i32,i32) {
    unsafe {
        let mut ws: libc::winsize = std::mem::zeroed();
        if libc::ioctl(1, libc::TIOCGWINSZ, &mut ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0 {
            return (ws.ws_row as i32, ws.ws_col as i32);
        }
    }
    (24, 80)
}

pub fn rand_u32() -> u32 {
    // simple xorshift seeded from time+pid
    static mut STATE: u32 = 0;
    unsafe {
        if STATE == 0 {
            let t = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.subsec_nanos()).unwrap_or(1);
            STATE = t ^ (process::id() as u32).wrapping_mul(2654435761);
            if STATE == 0 { STATE = 1; }
        }
        let mut x = STATE;
        x ^= x << 13; x ^= x >> 17; x ^= x << 5;
        STATE = x; x
    }
}

fn resolve_rotate(mode: RotateMode) -> (bool,bool) {
    match mode {
        RotateMode::Horizontal => (false, true),
        RotateMode::Vertical => (true, false),
        RotateMode::Random => match rand_u32() % 3 { 0 => (false,true), 1 => (true,false), _ => (true,true) },
    }
}

fn write_all(b: &[u8]) {
    use std::os::unix::io::AsRawFd;
    let fd = io::stdout().as_raw_fd();
    let mut off = 0;
    while off < b.len() {
        let n = unsafe { libc::write(fd, b[off..].as_ptr() as *const _, b.len()-off) };
        if n < 0 { let e = io::Error::last_os_error(); if e.kind()==io::ErrorKind::Interrupted { continue; } break; }
        if n == 0 { break; }
        off += n as usize;
    }
}

struct TermRaw { orig: libc::termios, ok: bool }
impl TermRaw {
    fn enter() -> Self {
        unsafe {
            let mut t: libc::termios = std::mem::zeroed();
            if libc::tcgetattr(0, &mut t) != 0 { return Self{orig:t, ok:false}; }
            let orig = t;
            t.c_lflag &= !(libc::ICANON | libc::ECHO);
            t.c_cc[libc::VMIN] = 0;
            t.c_cc[libc::VTIME] = 0;
            libc::tcsetattr(0, libc::TCSANOW, &t);
            Self{orig, ok:true}
        }
    }
    fn key_pressed(&self) -> bool {
        if !self.ok { return false; }
        let mut b = [0u8;1];
        unsafe { libc::read(0, b.as_mut_ptr() as *mut _, 1) > 0 }
    }
}
impl Drop for TermRaw {
    fn drop(&mut self) { if self.ok { unsafe { libc::tcsetattr(0, libc::TCSANOW, &self.orig); } } }
}

static mut STOP: bool = false;
extern "C" fn on_sig(_: libc::c_int) { unsafe { STOP = true; } }
fn install_sig() {
    unsafe {
        let mut sa: libc::sigaction = std::mem::zeroed();
        sa.sa_sigaction = on_sig as *const () as usize;
        libc::sigemptyset(&mut sa.sa_mask);
        sa.sa_flags = 0;
        libc::sigaction(libc::SIGINT, &sa, std::ptr::null_mut());
        libc::sigaction(libc::SIGTERM, &sa, std::ptr::null_mut());
    }
}

fn read_first(path: &str) -> Option<String> {
    fs::read_to_string(path).ok().and_then(|s| s.lines().next().map(|l| l.trim().to_string())).filter(|s| !s.is_empty())
}
fn os_name() -> Option<String> {
    let s = fs::read_to_string("/etc/os-release").ok()?;
    for l in s.lines() {
        if let Some(v)=l.strip_prefix("PRETTY_NAME=") {
            let v=v.trim().trim_matches('"').trim_matches('\'').to_string();
            if !v.is_empty() { return Some(v); }
        }
    }
    None
}
fn cpu_name() -> Option<String> {
    let s = fs::read_to_string("/proc/cpuinfo").ok()?;
    let mut model=None; let mut cores=0usize;
    for l in s.lines() {
        if model.is_none() && (l.starts_with("model name")||l.starts_with("Model name")) {
            if let Some((_,v))=l.split_once(':') { model=Some(v.trim().to_string()); }
        }
        if l.starts_with("processor") { cores+=1; }
    }
    let mut m=model?;
    for t in ["(R)","(TM)","(tm)"] { m=m.replace(t,""); }
    m = m.split_whitespace().collect::<Vec<_>>().join(" ");
    if cores>0 { m.push_str(&format!(" ({cores})")); }
    Some(m)
}
fn uptime_str() -> String {
    let up = fs::read_to_string("/proc/uptime").ok().and_then(|s| s.split_whitespace().next()?.parse::<f64>().ok()).unwrap_or(0.0);
    let s = up as i64; let d=s/86400; let h=(s%86400)/3600; let m=(s%3600)/60;
    if d>0 { format!("{d} day{}, {h} hour{}, {m} min{}", if d==1{""}else{"s"}, if h==1{""}else{"s"}, if m==1{""}else{"s"}) }
    else if h>0 { format!("{h} hour{}, {m} min{}", if h==1{""}else{"s"}, if m==1{""}else{"s"}) }
    else { format!("{m} min{}, {} sec", if m==1{""}else{"s"}, s%60) }
}
fn mem_str() -> Option<String> {
    let s = fs::read_to_string("/proc/meminfo").ok()?;
    let mut total=0f64; let mut avail=0f64;
    for l in s.lines() {
        if let Some(v)=l.strip_prefix("MemTotal:") { total=v.split_whitespace().next()?.parse().ok()?; }
        if let Some(v)=l.strip_prefix("MemAvailable:") { avail=v.split_whitespace().next()?.parse().ok()?; }
    }
    if total<=0.0 { return None; }
    let used=(total-avail)/1048576.0; let tot=total/1048576.0;
    Some(format!("{used:.2} / {tot:.2} GiB ({}%)", ((total-avail)*100.0/total) as i64))
}
fn disk_str() -> Option<String> {
    unsafe {
        let mut sv: libc::statvfs = std::mem::zeroed();
        let c = std::ffi::CString::new("/").ok()?;
        if libc::statvfs(c.as_ptr(), &mut sv) != 0 { return None; }
        let fr = sv.f_frsize as f64;
        let total = sv.f_blocks as f64 * fr / 1073741824.0;
        let used = (sv.f_blocks as f64 - sv.f_bfree as f64) * fr / 1073741824.0;
        let pct = if total>0.0 {(used*100.0/total) as i64} else {0};
        Some(format!("{used:.1} / {total:.1} GiB ({pct}%)"))
    }
}
fn host_name() -> String {
    let mut buf=[0u8;64];
    unsafe { if libc::gethostname(buf.as_mut_ptr() as *mut _, buf.len()) == 0 {
        let len = buf.iter().position(|&c| c==0).unwrap_or(buf.len());
        return String::from_utf8_lossy(&buf[..len]).to_string();
    }}
    "localhost".to_string()
}
fn user_name() -> String {
    env::var("USER").ok().filter(|s|!s.is_empty()).unwrap_or_else(|| unsafe {
        let pw = libc::getpwuid(libc::getuid());
        if pw.is_null() { "user".to_string() } else { std::ffi::CStr::from_ptr((*pw).pw_name).to_string_lossy().to_string() }
    })
}



fn info_lines() -> (String, Vec<(String,String)>) {
    let mut fields = Vec::new();
    let title = format!("{}@{}", user_name(), host_name());
    if let Some(v)=os_name() { fields.push(("OS".into(), v)); }
    if let Some(v)=read_first("/sys/class/dmi/id/product_name") { fields.push(("Host".into(), v)); }
    if let Some(v)=read_first("/proc/sys/kernel/osrelease") { fields.push(("Kernel".into(), v)); }
    fields.push(("Uptime".into(), uptime_str()));
    if let Ok(sh)=env::var("SHELL") { fields.push(("Shell".into(), sh.rsplit('/').next().unwrap_or(&sh).to_string())); }
    if let Some(t)=env::var("TERM_PROGRAM").ok().or_else(|| env::var("TERM").ok()) { fields.push(("Terminal".into(), t)); }
    if let Some(v)=cpu_name() { fields.push(("CPU".into(), v)); }
    if let Some(v)=mem_str() { fields.push(("Memory".into(), v)); }
    if let Some(v)=disk_str() { fields.push(("Disk".into(), v)); }
    (title, fields)
}

fn trunc_cp(s: &str, maxcp: usize) -> String {
    let mut out=String::new();
    for (i,c) in s.chars().enumerate() { if i>=maxcp { break; } out.push(c); }
    out
}

pub struct ModelBuilder { pub pts: Vec<Pt>, cur_mat: u8 }
impl ModelBuilder {
    pub fn new() -> Self { Self { pts: Vec::with_capacity(20000), cur_mat: 0 } }
    pub fn set_mat(&mut self, m: u8) { self.cur_mat = m; }
    pub fn add(&mut self, x:f32,y:f32,z:f32,nx:f32,ny:f32,nz:f32) {
        self.pts.push(Pt{x,y,z,nx,ny,nz,m:self.cur_mat});
    }
    fn v_cross(a:[f32;3],b:[f32;3])->[f32;3]{[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]}
    fn v_norm(v:&mut [f32;3])->f32{let l=(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]).sqrt(); if l>1e-12{v[0]/=l;v[1]/=l;v[2]/=l;} l}
    pub fn add_torus_xy(&mut self, cx:f32, cy:f32, r_major:f32, r_minor:f32) {
        let step=0.03f32;
        let nu=((2.0*PI*(r_major+r_minor))/step).ceil() as i32;
        let mut nv=((2.0*PI*r_minor)/step).ceil() as i32; if nv<6{nv=6;}
        for i in 0..nu { for j in 0..nv {
            let u=2.0*PI*i as f32/nu as f32; let v=2.0*PI*j as f32/nv as f32;
            let (cu,su,cv,sv)=(u.cos(),u.sin(),v.cos(),v.sin());
            self.add(cx+(r_major+r_minor*cv)*cu, cy+(r_major+r_minor*cv)*su, r_minor*sv, cv*cu, cv*su, sv);
        }}
    }
    pub fn add_torus_x(&mut self, cx:f32, r_major:f32, r_minor:f32) {
        let step=0.03f32;
        let nu=((2.0*PI*(r_major+r_minor))/step).ceil() as i32;
        let mut nv=((2.0*PI*r_minor)/step).ceil() as i32; if nv<6{nv=6;}
        for i in 0..nu { for j in 0..nv {
            let u=2.0*PI*i as f32/nu as f32; let v=2.0*PI*j as f32/nv as f32;
            let (cu,su,cv,sv)=(u.cos(),u.sin(),v.cos(),v.sin());
            self.add(cx+r_minor*sv, (r_major+r_minor*cv)*cu, (r_major+r_minor*cv)*su, sv, cv*cu, cv*su);
        }}
    }
    pub fn add_cyl_x(&mut self, x0:f32,x1:f32,rho:f32) {
        let step=0.03f32;
        let nt=((2.0*PI*rho)/step).ceil().max(8.0) as i32;
        let nx=((x1-x0).abs()/step).ceil() as i32 + 1;
        for i in 0..nx { let x=x0+(x1-x0)*i as f32/(nx-1).max(1) as f32;
            for j in 0..nt { let t=2.0*PI*j as f32/nt as f32; self.add(x, rho*t.cos(), rho*t.sin(), 0.0, t.cos(), t.sin()); }
        }
    }
    pub fn add_disc_x(&mut self, x:f32, rho:f32, dir:f32) {
        let step=0.03f32; let mut rad=0.0f32;
        while rad <= rho + 1e-6 {
            let n = if rad<1e-4 {1} else {((2.0*PI*rad)/step).ceil() as i32};
            for j in 0..n { let t=2.0*PI*j as f32/n.max(1) as f32; self.add(x, rad*t.cos(), rad*t.sin(), dir,0.0,0.0); }
            rad += step;
        }
    }
    pub fn add_box(&mut self, x0:f32,x1:f32,y0:f32,y1:f32,z0:f32,z1:f32) {
        let step=0.03f32;
        let nx=((x1-x0).abs()/step).ceil() as i32 + 1;
        let ny=((y1-y0).abs()/step).ceil() as i32 + 1;
        let nz=((z1-z0).abs()/step).ceil() as i32 + 1;
        for i in 0..nx { let x=x0+(x1-x0)*i as f32/(nx-1).max(1) as f32;
            for j in 0..ny { let y=y0+(y1-y0)*j as f32/(ny-1).max(1) as f32; self.add(x,y,z0,0.0,0.0,-1.0); self.add(x,y,z1,0.0,0.0,1.0); }
        }
        for i in 0..nx { let x=x0+(x1-x0)*i as f32/(nx-1).max(1) as f32;
            for k in 0..nz { let z=z0+(z1-z0)*k as f32/(nz-1).max(1) as f32; self.add(x,y0,z,0.0,-1.0,0.0); self.add(x,y1,z,0.0,1.0,0.0); }
        }
        for j in 0..ny { let y=y0+(y1-y0)*j as f32/(ny-1).max(1) as f32;
            for k in 0..nz { let z=z0+(z1-z0)*k as f32/(nz-1).max(1) as f32; self.add(x0,y,z,-1.0,0.0,0.0); self.add(x1,y,z,1.0,0.0,0.0); }
        }
    }
    pub fn add_frustum(&mut self, a:[f32;3], b:[f32;3], r0:f32, r1:f32, caps:bool) {
        let step=0.03f32;
        let d=[b[0]-a[0],b[1]-a[1],b[2]-a[2]]; let mut u=d; let l=Self::v_norm(&mut u);
        let mut refv=[0.0,1.0,0.0]; if u[1].abs()>0.9 { refv=[1.0,0.0,0.0]; }
        let mut t=Self::v_cross(u,refv); Self::v_norm(&mut t);
        let mut w=Self::v_cross(u,t); Self::v_norm(&mut w);
        let rm=r0.max(r1);
        let nl=((l/step).ceil() as i32 + 1).max(2); let nt=((2.0*PI*rm/step).ceil() as i32).max(8);
        for i in 0..nl { let s=i as f32/(nl-1) as f32; let r=r0+(r1-r0)*s;
            for j in 0..nt { let ang=2.0*PI*j as f32/nt as f32; let (ca,sa)=(ang.cos(),ang.sin());
                let rad=[t[0]*ca+w[0]*sa,t[1]*ca+w[1]*sa,t[2]*ca+w[2]*sa];
                let mut n=[rad[0]*l+u[0]*(r0-r1), rad[1]*l+u[1]*(r0-r1), rad[2]*l+u[2]*(r0-r1)];
                Self::v_norm(&mut n);
                self.add(a[0]+d[0]*s+rad[0]*r,a[1]+d[1]*s+rad[1]*r,a[2]+d[2]*s+rad[2]*r,n[0],n[1],n[2]);
            }
        }
        if caps {
            for e in 0..2 {
                let rr=if e==1{r1}else{r0}; let sg=if e==1{1.0}else{-1.0};
                let p=if e==1{b}else{a};
                let mut radv=0.0f32;
                while radv <= rr+1e-6 {
                    let npt = if radv<1e-4 {1} else {((2.0*PI*radv)/step).ceil() as i32};
                    for j in 0..npt { let ang=2.0*PI*j as f32/npt.max(1) as f32; let (ca,sa)=(ang.cos(),ang.sin());
                        self.add(p[0]+(t[0]*ca+w[0]*sa)*radv,p[1]+(t[1]*ca+w[1]*sa)*radv,p[2]+(t[2]*ca+w[2]*sa)*radv, u[0]*sg,u[1]*sg,u[2]*sg);
                    }
                    radv+=step;
                }
            }
        }
    }
    pub fn add_surface<F>(&mut self, f:F, nu:i32,nv:i32,u0:f32,u1:f32,v0:f32,v1:f32, periodic_u:bool, hint:[f32;3], outward:bool)
    where F: Fn(f32,f32)->[f32;3] {
        let eu=(u1-u0)*1e-3; let ev=(v1-v0)*1e-3;
        for i in 0..nu {
            let u = u0 + (u1-u0)*i as f32 / if periodic_u {nu as f32} else {(nu-1).max(1) as f32};
            for j in 0..nv {
                let v = v0 + (v1-v0)*j as f32 / (nv-1).max(1) as f32;
                let p=f(u,v); let a=f(u+eu,v); let b=f(u-eu,v); let c=f(u,v+ev); let d=f(u,v-ev);
                let pu=[a[0]-b[0],a[1]-b[1],a[2]-b[2]]; let pv=[c[0]-d[0],c[1]-d[1],c[2]-d[2]];
                let mut n=Self::v_cross(pu,pv);
                if Self::v_norm(&mut n) < 1e-9 { continue; }
                let dot = if outward { n[0]*(p[0]-hint[0])+n[1]*(p[1]-hint[1])+n[2]*(p[2]-hint[2]) }
                          else { n[0]*hint[0]+n[1]*hint[1]+n[2]*hint[2] };
                if dot < 0.0 { n[0]=-n[0]; n[1]=-n[1]; n[2]=-n[2]; }
                self.add(p[0],p[1],p[2],n[0],n[1],n[2]);
            }
        }
    }
    pub fn add_extruded<F>(&mut self, inside:F, x0:f32,x1:f32,y0:f32,y1:f32, th:f32)
    where F: Fn(f32,f32)->u8 {
        let step=0.03f32;
        let nx=((x1-x0)/step).ceil() as i32 + 1;
        let ny=((y1-y0)/step).ceil() as i32 + 1;
        let nz=((th/step).ceil() as i32).max(2);
        for iy in 0..ny { let y=y0+(y1-y0)*iy as f32/(ny-1).max(1) as f32;
            for ix in 0..nx { let x=x0+(x1-x0)*ix as f32/(nx-1).max(1) as f32;
                let m = inside(x,y);
                if m==0 { continue; }
                let save=self.cur_mat; self.cur_mat=m-1;
                self.add(x,y,th/2.0,0.0,0.0,1.0);
                self.add(x,y,-th/2.0,0.0,0.0,-1.0);
                if inside(x+step,y)==0 || inside(x-step,y)==0 || inside(x,y+step)==0 || inside(x,y-step)==0 {
                    let mut gx=0.0f32; let mut gy=0.0f32;
                    for oy in -2..=2 { for ox in -2..=2 {
                        if inside(x+ox as f32*step, y+oy as f32*step)==0 { gx+=ox as f32; gy+=oy as f32; }
                    }}
                    let gl=(gx*gx+gy*gy).sqrt();
                    if gl>1e-6 {
                        for k in 0..nz { let z=-th/2.0 + th*k as f32/(nz-1).max(1) as f32; self.add(x,y,z,gx/gl,gy/gl,0.0); }
                    }
                }
                self.cur_mat=save;
            }
        }
    }
    pub fn normalize(&mut self) {
        if self.pts.is_empty() { return; }
        let mut mn=[1e9f32;3]; let mut mx=[-1e9f32;3];
        for p in &self.pts {
            let v=[p.x,p.y,p.z];
            for k in 0..3 { if v[k]<mn[k]{mn[k]=v[k];} if v[k]>mx[k]{mx[k]=v[k];} }
        }
        let c=[(mn[0]+mx[0])/2.0,(mn[1]+mx[1])/2.0,(mn[2]+mx[2])/2.0];
        let mut rmax=0.0f32;
        for p in &mut self.pts { p.x-=c[0]; p.y-=c[1]; p.z-=c[2]; let d=(p.x*p.x+p.y*p.y+p.z*p.z).sqrt(); if d>rmax{rmax=d;} }
        if rmax>0.0 { for p in &mut self.pts { p.x/=rmax; p.y/=rmax; p.z/=rmax; } }
    }
}

pub fn build_key(b: &mut ModelBuilder) {
    b.set_mat(0);
    b.add_torus_xy(-1.55, 0.0, 0.62, 0.17);
    b.add_cyl_x(-0.80, 1.95, 0.12);
    b.add_disc_x(1.95, 0.12, 1.0);
    b.add_cyl_x(-0.55, -0.38, 0.20);
    b.add_disc_x(-0.55, 0.20, -1.0);
    b.add_disc_x(-0.38, 0.20, 1.0);
    b.add_box(1.28,1.44,-0.55,-0.08,-0.08,0.08);
    b.add_box(1.54,1.70,-0.38,-0.08,-0.08,0.08);
    b.add_box(1.80,1.95,-0.62,-0.08,-0.08,0.08);
    b.normalize();
}

pub fn build_tree(b: &mut ModelBuilder) {
    b.set_mat(0);
    b.add_extruded(|x,y| {
        let t=[[1.00f32,0.38f32,0.46f32],[0.66,-0.08,0.68],[0.30,-0.56,0.90]];
        let hx=x; let hy=y-0.80;
        if hx*hx+hy*hy < 0.075*0.075 { return 0; }
        for tri in t {
            if y <= tri[0] && y >= tri[1] && x.abs() <= tri[2]*(tri[0]-y)/(tri[0]-tri[1]) { return 1; }
        }
        if x.abs() <= 0.13 && y >= -0.86 && y < -0.50 { return 2; }
        0
    }, -0.95,0.95,-0.88,1.02,0.07);
    b.set_mat(1);
    b.add_torus_xy(0.0,1.00,0.20,0.022);
    b.normalize();
}

pub fn build_stool(b: &mut ModelBuilder) {
    b.set_mat(0);
    b.add_box(-0.58,0.58,0.00,0.13,-0.58,0.58);
    b.set_mat(1);
    let sx=[1.0,1.0,-1.0,-1.0]; let sz=[1.0,-1.0,-1.0,1.0];
    let mut top=[[0f32;3];4]; let mut low=[[0f32;3];4]; let mut mid=[[0f32;3];4];
    for i in 0..4 {
        top[i]=[0.42*sx[i],0.02,0.42*sz[i]];
        low[i]=[0.52*sx[i],-0.98,0.52*sz[i]];
        b.add_frustum(top[i],low[i],0.08,0.055,true);
        let s=0.58f32;
        for k in 0..3 { mid[i][k]=top[i][k]+(low[i][k]-top[i][k])*s; }
    }
    for i in 0..4 { let j=(i+1)%4; b.add_frustum(mid[i],mid[j],0.04,0.04,true); }
    b.normalize();
}

pub fn build_skeleton(b: &mut ModelBuilder) {
    b.set_mat(0);
    let cx=-1.52f32; let d=0.27f32;
    for k in 0..3 {
        let a = PI/2.0 + k as f32 * 2.0*PI/3.0;
        b.add_torus_xy(cx + d*a.cos(), d*a.sin(), 0.235, 0.062);
    }
    b.add_cyl_x(-0.96,1.88,0.085);
    b.add_disc_x(1.88,0.085,1.0);
    b.add_torus_x(-0.78,0.115,0.048);
    b.add_torus_x(-0.60,0.095,0.042);
    b.add_torus_x(-0.42,0.115,0.048);
    b.add_cyl_x(-0.30,-0.12,0.150);
    b.add_disc_x(-0.30,0.150,-1.0);
    b.add_disc_x(-0.12,0.150,1.0);
    b.add_torus_x(-0.02,0.105,0.04);
    b.add_extruded(|x,y| {
        if x < 1.10 || x > 1.86 || y > -0.04 || y < -0.62 { return 0; }
        if x>1.28 && x<1.40 && y < -0.28 { return 0; }
        if x>1.52 && x<1.61 && y < -0.44 { return 0; }
        if x>1.72 && x<1.80 && y < -0.34 { return 0; }
        let hx=x-1.20; let hy=y+0.20;
        if hx*hx+hy*hy < 0.045*0.045 { return 0; }
        2
    }, 1.04,1.90,-0.66,0.0,0.07);
    b.normalize();
}

pub fn build_tomato(b: &mut ModelBuilder) {
    fn tomato(th:f32, ph:f32)->[f32;3]{
        let (sp,cp)=(ph.sin(),ph.cos());
        let r=1.0 + 0.035*(5.0*th).cos()*sp*sp;
        let x=r*sp*th.cos(); let z=r*sp*th.sin();
        let mut y=0.82*cp;
        let w=ph/0.5; let bb=(PI-ph)/0.4;
        y -= 0.25*(-w*w).exp();
        y += 0.07*(-bb*bb).exp();
        [x,y,z]
    }
    b.set_mat(0);
    b.add_surface(tomato, 210,96,0.0,2.0*PI,0.015,PI-0.015,true,[0.0,0.0,0.0],true);
    b.set_mat(1);
    for k in 0..5 {
        let alpha = 2.0*PI*k as f32/5.0 + 0.3;
        for &dy in &[0.012f32, -0.012f32] {
            let hint = if dy>0.0 {[0.0,1.0,0.0]} else {[0.0,-1.0,0.0]};
            b.add_surface(|s,_q| {
                let sc=s.clamp(0.0,1.0);
                let c=tomato(alpha, 0.04 + 0.62*sc);
                let ww=0.105*(PI*sc.powf(0.75)).sin();
                [c[0]-alpha.sin()*_q*ww, c[1]+0.03+0.12*sc*sc+dy, c[2]+alpha.cos()*_q*ww]
            }, 34,14,0.0,1.0,-1.0,1.0,false,hint,false);
        }
    }
    let pole = tomato(0.0,0.02);
    b.add_frustum([0.0,pole[1]-0.04,0.0],[0.05,pole[1]+0.27,0.0],0.075,0.05,true);
    b.normalize();
}

fn usage(cfg: &Config) {
    let rot = "horizontal|vertical|random";
    let mut s = format!("usage: {} [options]\n\n", cfg.name);
    s.push_str(&format!("  -c, --color <c>        color name or #rrggbb (default depends on fetch)\n"));
    if cfg.has_accent { s.push_str("  -a, --accent <c>       accent/secondary color\n"); }
    s.push_str("  -t, --label-color <c>  info label color\n");
    s.push_str("  -r, --rainbow          cycle hue over time\n");
    s.push_str("  -s, --speed <f>        rotation speed multiplier (default 1.0)\n");
    s.push_str("      --size <f>         model scale (default 1.0)\n");
    s.push_str("      --height <n>       render height in rows (default 16)\n");
    s.push_str(&format!("      --rotate <m>       rotation mode: {rot} (default horizontal)\n"));
    s.push_str("      --spin <m>         alias for --rotate\n");
    s.push_str("      --frames <n>       stop after n frames\n");
    s.push_str("  -n, --no-info          hide system info\n");
    s.push_str("      --no-color         disable colors\n");
    s.push_str("  -h, --help             show help\n");
    print!("{s}");
}

pub fn parse_args(cfg: &mut Config) {
    let mut args = env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "-h"|"--help" => { usage(cfg); process::exit(0); }
            "-n"|"--no-info" => cfg.no_info = true,
            "-N"|"--no-color" => cfg.no_color = true,
            "-r"|"--rainbow" => cfg.rainbow = true,
            "-c"|"--color" => { let v=args.next().unwrap_or_else(||{eprintln!("missing value for {a}"); process::exit(1)}); cfg.color=parse_color(&v).unwrap_or_else(||{eprintln!("bad color: {v}"); process::exit(1)}); if !cfg.label_set { cfg.label_color=cfg.color; } }
            "-a"|"--accent" => { if !cfg.has_accent { eprintln!("unknown option: {a}"); process::exit(1); } let v=args.next().unwrap_or_else(||{eprintln!("missing value for {a}"); process::exit(1)}); cfg.accent=parse_color(&v).unwrap_or_else(||{eprintln!("bad color: {v}"); process::exit(1)}); }
            "-t"|"--label-color" => { let v=args.next().unwrap_or_else(||{eprintln!("missing value for {a}"); process::exit(1)}); cfg.label_color=parse_color(&v).unwrap_or_else(||{eprintln!("bad color: {v}"); process::exit(1)}); cfg.label_set=true; }
            "-s"|"--speed" => { let v=args.next().unwrap_or_default(); cfg.speed=v.parse().unwrap_or(1.0); }
            "--size" => { let v=args.next().unwrap_or_default(); cfg.size=v.parse().unwrap_or(1.0); }
            "--height" => { let v=args.next().unwrap_or_default(); cfg.height=v.parse().unwrap_or(16); }
            "--frames" => { let v=args.next().unwrap_or_default(); cfg.frames=v.parse().unwrap_or(0); }
            "--rotate"|"--spin"|"-S" => { let v=args.next().unwrap_or_default(); cfg.rotate=RotateMode::parse(&v).unwrap_or_else(||{eprintln!("bad rotate mode: {v} (use horizontal|vertical|random)"); process::exit(1)}); }
            _ => { eprintln!("unknown option: {a}"); usage(cfg); process::exit(1); }
        }
    }
}

fn clampi(v:i32, lo:i32, hi:i32)->i32{ v.max(lo).min(hi) }

pub fn run(mut cfg: Config, mut builder: ModelBuilder) {
    parse_args(&mut cfg);
    builder.normalize();
    let pts = builder.pts;
    if pts.is_empty() { eprintln!("no model points"); process::exit(1); }

    let (mut rows, mut cols) = term_size();
    let mut h = cfg.height.max(6);
    if h > rows - 2 { h = (rows-2).max(6); }
    let mut w = (2*h).min(cols).max(10);
    let mut avail = (cols - w - 3).clamp(0, 200);
    let want_info = !cfg.no_info;
    let tc = truecolor() && !cfg.no_color;

    let (spin_x, spin_y) = resolve_rotate(cfg.rotate);
    let title = format!("{}@{}", user_name(), host_name());
    let mut fields = info_lines().1;
    let mut last_info = Instant::now();

    install_sig();
    let raw = TermRaw::enter();
    write_all(b"\x1b[?25l");
    struct Guard;
    impl Drop for Guard { fn drop(&mut self) { write_all(b"\x1b[0m\x1b[?25h\n"); } }
    let _guard = Guard;

    let mut zb = vec![1e9f32; (h*w) as usize];
    let mut dif = vec![0f32; (h*w) as usize];
    let mut spc = vec![0f32; (h*w) as usize];
    let mut mat = vec![0u8; (h*w) as usize];
    let ramp: Vec<char> = " .,-~:;=!*#$@".chars().collect();
    let nr = ramp.len() as i32;
    let mut frame: usize = 0;
    let t0 = Instant::now();

    while !unsafe{STOP} {
        if raw.key_pressed() { break; }
        if cfg.frames>0 && frame>=cfg.frames { break; }
        if last_info.elapsed().as_millis() >= 1000 { fields = info_lines().1; last_info = Instant::now(); }
        let (nr_rows, nr_cols) = term_size();
        if nr_rows!=rows || nr_cols!=cols {
            rows=nr_rows; cols=nr_cols;
            h = cfg.height.max(6); if h>rows-2 { h=(rows-2).max(6);} w=(2*h).min(cols).max(10); avail=(cols-w-3).clamp(0,200);
            zb.resize((h*w) as usize, 1e9f32); dif.resize((h*w) as usize, 0.0); spc.resize((h*w) as usize, 0.0); mat.resize((h*w) as usize, 0);
        }
        for i in 0..(h*w) as usize { zb[i]=1e9; dif[i]=0.0; spc[i]=0.0; mat[i]=0; }

        let t = t0.elapsed().as_secs_f32() * cfg.speed;
        let (ax, ay) = (if spin_x {0.45 + t*0.73} else {0.35}, if spin_y {t} else {0.0});
        let (sx,cx,sy,cy)=(ax.sin(),ax.cos(),ay.sin(),ay.cos());
        let dcam = 4.0f32;
        let kc = 0.48 * h as f32 * (dcam-1.0) * cfg.size * 1.3;
        let l = { let mut v=[-0.45f32,0.65f32,-0.75f32]; let ln=(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]).sqrt(); for x in &mut v { *x/=ln;} v };
        let mut hv=[l[0],l[1],l[2]-1.0]; let hn=(hv[0]*hv[0]+hv[1]*hv[1]+hv[2]*hv[2]).sqrt(); for x in &mut hv { *x/=hn; }
        let body_col = if cfg.rainbow { hsv(t*60.0,0.85,1.0) } else { cfg.color };
        let label_col = if cfg.rainbow && !cfg.label_set { body_col } else { cfg.label_color };

        for q in &pts {
            let nx1=q.nx*cy + q.nz*sy; let nz1 = -q.nx*sy + q.nz*cy;
            let ny2=q.ny*cx - nz1*sx; let nz2=q.ny*sx + nz1*cx;
            if nz2 > 0.05 { continue; }
            let x1=q.x*cy + q.z*sy; let z1 = -q.x*sy + q.z*cy;
            let y2=q.y*cx - z1*sx; let z2=q.y*sx + z1*cx;
            let depth = dcam + z2;
            let ix = ((w as f32/2.0) + 2.0*kc*x1/depth).floor() as i32;
            let iy = ((h as f32/2.0) - kc*y2/depth).floor() as i32;
            if ix<0||ix>=w||iy<0||iy>=h { continue; }
            let ci = (iy*w+ix) as usize;
            if depth >= zb[ci] { continue; }
            zb[ci]=depth;
            let d = nx1*l[0]+ny2*l[1]+nz2*l[2];
            let s = nx1*hv[0]+ny2*hv[1]+nz2*hv[2];
            dif[ci] = if d>0.0 {d} else {0.0};
            spc[ci] = if d>0.0 && s>0.0 { s.powf(28.0) } else {0.0};
            mat[ci] = q.m;
        }

        let maxlab = fields.iter().map(|(k,_)| k.chars().count()).max().unwrap_or(0);
        let info_lines_count = if want_info { 2 + fields.len() as i32 } else { 0 };
        let off = if info_lines_count < h { (h-info_lines_count)/2 } else { 0 };

        let mut out: Vec<u8> = Vec::with_capacity((h*w*20) as usize);
        if frame>0 { let _ = write!(out, "\x1b[{}A\r", h); }
        for r in 0..h {
            let mut last = Rgb{r:255,g:255,b:255}; let mut has_last=false;
            for c in 0..w {
                let i=(r*w+c) as usize;
                if zb[i] >= 1e8 {
                    out.push(b' ');
                } else {
                    let sh = 0.16 + 0.84*dif[i]; let spv=spc[i];
                    let lum = sh*0.85 + spv*0.45;
                    let idx = clampi(1 + (lum*(nr-2) as f32) as i32, 1, nr-1) as usize;
                    let base = if mat[i]==1 { cfg.accent } else { body_col };
                    if !cfg.no_color {
                        let col = Rgb {
                            r: clampi((base.r as f32*sh + 255.0*spv*0.7) as i32,0,255) as u8,
                            g: clampi((base.g as f32*sh + 255.0*spv*0.7) as i32,0,255) as u8,
                            b: clampi((base.b as f32*sh + 255.0*spv*0.7) as i32,0,255) as u8,
                        };
                        if !has_last || col.r!=last.r||col.g!=last.g||col.b!=last.b { put_color(&mut out, col, tc); last=col; has_last=true; }
                    }
                    let mut buf=[0u8;4]; let ch=ramp[idx].encode_utf8(&mut buf); out.extend_from_slice(ch.as_bytes());
                }
            }
            if !cfg.no_color { out.extend_from_slice(b"\x1b[0m"); }
            if want_info && avail >= 12 {
                let li = r-off;
                if li == 0 {
                    out.extend_from_slice(b"   ");
                    if !cfg.no_color { out.extend_from_slice(b"\x1b[1m"); put_color(&mut out, label_col, tc); }
                    let tstr = trunc_cp(&title, avail as usize);
                    out.extend_from_slice(tstr.as_bytes());
                    if !cfg.no_color { out.extend_from_slice(b"\x1b[0m"); }
                } else if li == 1 {
                    out.extend_from_slice(b"   ");
                    if !cfg.no_color { out.extend_from_slice(b"\x1b[2m"); }
                    let n = (title.chars().count() as i32).min(avail).max(0) as usize;
                    for _ in 0..n { out.extend_from_slice("─".as_bytes()); }
                    if !cfg.no_color { out.extend_from_slice(b"\x1b[0m"); }
                } else if li >= 2 {
                    let idxf = (li-2) as usize;
                    if idxf < fields.len() {
                        let (k,v)=&fields[idxf];
                        out.extend_from_slice(b"   ");
                        if !cfg.no_color { out.extend_from_slice(b"\x1b[1m"); put_color(&mut out, label_col, tc); }
                        let kfmt = format!("{:<width$}", k, width=maxlab);
                        out.extend_from_slice(kfmt.as_bytes());
                        if !cfg.no_color { out.extend_from_slice(b"\x1b[0m"); }
                        out.push(b' ');
                        let rem = (avail as usize).saturating_sub(maxlab+1);
                        out.extend_from_slice(trunc_cp(v, rem).as_bytes());
                        if !cfg.no_color { out.extend_from_slice(b"\x1b[0m"); }
                    }
                }
            }
            out.extend_from_slice(b"\x1b[K\n");
        }
        write_all(&out);
        frame += 1;
        std::thread::sleep(std::time::Duration::from_millis(33));
    }
}
