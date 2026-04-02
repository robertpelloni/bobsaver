#version 420

// original https://www.shadertoy.com/view/7sKyWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// philip.bertani@gmail.com

#define oct 5   //number of fbm octaves
#define pi  3.14159265

float random(vec3 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec3(12., 90., -.180)))* 1e5 );
}

float torus(vec3 p, vec2 axis) {
    vec2 q = vec2( length(p.xy) - axis.x, p.y);
    return length(q) - axis.y;
}

float all_sdfs(vec3 p, vec3 ro) {

        vec3 pp =  mod(p-1.,2.)-1.;
        //float dist = length(pp) - 1.1;
        float dist = torus(pp, vec2( 1.3, .2) );
        float dist2 = length(p-ro) - 1.1; 
        dist = max( dist, -dist2 ); 
        return dist;

}

//gradient (normal vector)
vec3 gradient(vec3 p, vec3 ro) {

    vec2 dpn = vec2(1.,-1.);
    vec2 dp  = .1 * dpn; 

    vec3 df = dpn.xxx * all_sdfs(p+dp.xxx, ro) +
              dpn.yyx * all_sdfs(p+dp.yyx, ro ) +
              dpn.xyy * all_sdfs(p+dp.xyy, ro)  +
              dpn.yxy * all_sdfs(p+dp.yxy, ro) ;

    return normalize(df); 

}

//this is taken from Visions of Chaos shader "Sample Noise 2D 4.glsl"
//and mangled to use a vec3
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    float a = random(i + vec3(1.,1.,1.));
    float b = random(i + vec3(1.,-1.,-1.));
    float c = random(i + vec3(-1.,1.,1.));
    float d = random(i + vec3(-1.,1.,-1.));
    vec2 u = f.xz; 
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;
}

float fbm3d(vec3 p) {
    float v = 0.;
    float a = .5;
  
    for (int i=0; i<oct; i++) {
        v += a * noise(p);
        p = p * 4.;
        a *= .8;  //changed from the usual .5
    }
    return v;
}

mat3 rxz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(cc,0.,-ss,
                0.,1.,0.,
                ss,0.,cc);                
}
mat3 ryz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(1.,0.,0.,
                0.,cc,-ss,
                0.,ss,cc);
}   

vec3 get_color(vec3 p) {

    vec3 q;
    q.x = fbm3d(p);
    q.y = fbm3d(p.xzy);
    q.z = fbm3d(p.zyx);

    //float f = fbm3d(p + q);
    
    return q;
}

vec3 ct(vec3 p, vec3 rd)  {

    vec3 cc = vec3(0.);

    float stepsize = .006;
    float totdist = stepsize;
    
    for (int i=0; i<18; i++) {
       vec3 cx = get_color(p);
       p += stepsize*rd;
       float fi = float(i);
       cc += exp(-totdist*totdist)* cx;
       totdist += stepsize;
       //rd = ryz(.12)*rd;   
    }
    
    return cc;

}

vec3 march(vec3 ro, vec3 rd) {

    float dist = 1., totdist=0.;
    float eps = .001;
    vec3 p=ro;
    for (int i=0; i<12; i++ ) {

        dist  = all_sdfs(p,ro);
        totdist += dist;
        p += dist*rd;
        if (dist < eps) {
            vec3 nn = gradient(p, ro);
            float dd = max(0.,dot( -rd, nn));
            return exp(-totdist*totdist/5.)*ct(p,rd)/11. - dd*vec3(0.,.1,0.);
            break;
        }
        eps *= (1.+dist*80.);
    }
    return vec3(0.);
}

void main(void)
{

    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 mm = (2.*mouse*resolution.xy.xy-resolution.xy)/resolution.y;

    vec3 rd = normalize( vec3(uv, 1.3) );  
    vec3 ro = vec3(0.,0.,0.);
    
    float delta = 2.*pi/40.;
    mat3 rot = rxz(-mm.x*delta+time/5.) * ryz(-mm.y*delta);

    rd = rot*rd;
    ro += rot[2]*time/3.;
    
    vec3 cc = march(ro, rd);
        
    cc = pow( cc , vec3(1.5+max(0.,1.*sin(time/3.))));    //play with this

    glFragColor = vec4(cc,1.0);
    
    
}
