#version 420

// original https://www.shadertoy.com/view/wstXD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Want to learn to make things glow, AO of color on objects
// and that stuff - but I dont know how.. 
// work in progress as I check other shaders and try to
// figure that out.... more to come

// work in progress - playing with shapes and other 2d elements
// projected on SDFs.
// Goal is to make the cyan lines glow or look electric.

#define MAX_STEPS     100
#define MAX_DIST      100.
#define MIN_DIST      .001
#define EPSILON          .0001

#define PI 3.1415926535897

vec3 rotateX(vec3 x, float an) {
    float c = cos(an); float s = sin(an);
    return vec3(x.x, x.y * c - x.z * s, x.z * c + x.y * s);
}

vec3 rotateY(vec3 x, float an) {
    float c = cos(an); float s = sin(an);
    return vec3(x.x * c - x.z * s, x.y, x.z * c + x.x * s);
}

vec3 rotateZ(vec3 x, float an) {
    float c = cos(an); float s = sin(an);
    return vec3(x.x * c - x.y * s, x.y * c + x.x * s, x.z);
}

// handy mouse*resolution.xy pos function - take in a vec3 like ro
// simple pan and tilt and return that vec3
vec3 get_mouse(vec3 ro) {
    float x = -.2;
    float y = .0;
    float z = 0.0;
    //vec3 mouse = vec3(x,y,z);
    ro = rotateZ(ro, z);   
    ro = rotateX(ro, x);
    ro = rotateY(ro, y);

    return ro;
}

// IQ - Triangle/Box/Twist
// https://www.shadertoy.com/view/Xl2yDW
float triangle2(vec2 p, float s){
    p.y +=.2;
    p *= s;
    float k = sqrt(3.0);
    p.x = abs(p.x) - 1.;
    p.y = p.y + 1./k;
    if( p.x+k*p.y>0.0 ) p=vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
 }
  
float sdBox(vec3 p,vec3 s) {
    p = abs(p) - s;
    return max(max(p.x,p.y),p.z);
}

vec3 twist( in vec3 p ){
    const float k = 0.05; 
    float c = cos(k*p.z);
    float s = sin(k*p.z);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}

float map(vec3 pos) {
    // set up size for repetition
    float size = 20.;
    float rep_half = size/2.;
    // get center vec and some movement
    vec3 center = vec3(0.,0., 0.- abs(time * 5.));
    vec3 pp = pos-center;
    vec3 pi = vec3(
        floor((pp + rep_half)/size)
    );

    pp.y -= 3.5 *sin(pp.x*.2+time*1.25);
    
    // make vec and ids 
    vec3 tt = pos-center;
    vec3 ti = vec3(
        floor((tt + rep_half)/size)
    );
    tt = twist(tt);
  
    vec3 rr = pos-center;
    vec3 ri = vec3(
        floor((rr + rep_half)/size)
    );
    rr = twist(rr);
    float twv= 2.5 + 2.5 *sin(pp.z*.3+time*1.5);
    rr.y -= length(twv);
    
    pp =  vec3(
      pp.x,
      pp.y,
      mod(pp.z+rep_half,size) - rep_half
    );
    rr =  vec3(
      rr.x,
      rr.y,
      mod(rr.z+rep_half,size) - rep_half
      );
    tt =  vec3(
      tt.x,
      tt.y,
      mod(tt.z+rep_half,size) - rep_half
      );

    float len = 11.;
    float tx =  1.5;

    //framework
    float d1 = sdBox(abs(tt)-vec3(10.,10.,0.), vec3(tx,tx,len) );
    float d2 = sdBox(abs(tt)-vec3(10.,0.,10.), vec3(tx,len,tx) );
    d1 = min(d1,d2);
    
      //wavey road
    float d3 = sdBox(abs(rr)-vec3(0.,10.,0.), vec3(4.,.5,11.));
    d1 = min(d1,d3);
    float res = d1;
  
    //wavey horizon
    d2 = sdBox(abs(pp)-vec3(0.,25.,10.), vec3(350.,1.,4.) );
    d3 = sdBox(abs(pp)-vec3(0.,30.,0.), vec3(350.,1.,11.) );
    d2 = min(d3,d2);

    if(d2<res) res = d2;

    return res;
}
  
vec2 trans_ray( in vec3 ro, in vec3 rd ) {
    float depth = 0.;
    float d2 = 0.;
    float bdepth = 0.;
    float hit = 0.;
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 p = ro + depth * rd;
        float dist = map(p);
        if(dist<0.01 && hit == 0.) {
            // getting the regular depth - but
            // letting the marcher continue for
            // transparent effect
          bdepth = d2;
          hit = 1.;
        }
        dist = max(abs(dist), MIN_DIST);
        d2+= abs(dist*.8);
        depth += abs(dist*.4);
    }
    return vec2(depth,bdepth);
}
  
mat3 get_camera(vec3 ro, vec3 ta, float rotation) {
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(rotation), cos(rotation),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv, in float isVr ) {
    vec3 color = vec3(0.);
    vec3 col = vec3(0.);
    float shade = 0.;
    
    vec2 dist = trans_ray(ro, rd);
    if(dist.x>0.001) {
        shade = (dist.x*.005); 
        col = vec3(.8) * smoothstep(.1,1.,shade); 
        col = pow(col, vec3(0.4545));
    }
      
    vec2 pv = uv;
    pv.y -= 0.0;
    vec2 xd = rd.xy;
    xd.y -= .25;
    float triLine = 0.;
    float triOver = 0.;
    // make triangles and project on stuff
    // should be lazers or glow or something
    for(int i=0;i<17;i++) {
        //float tri2 = triangle2(pv.xy,float(i)*dist.x*.0125);
        float dsub = dist.x*0.125;
        float dwth = 200./17.;
        float ptime = float(i)*dwth;
        float tri2 = triangle2(pv.xy,ptime-dsub+fract(time*.25)*dwth);
        triLine += 1.0 - smoothstep(0.03,0.3,abs(tri2*2.));
        
        float tri3 = triangle2(pv.xy,ptime+fract(time*.15)*dwth);
        triOver += 1.0 - smoothstep(0.03,0.3,abs(tri3*2.));
    }
    
    color = col * vec3(1.,.5-uv.y,.5-rd.y);
    if(isVr<.5){
        color += triLine *.25-triOver;
    }
    // playing with overlays/triangles etc.. 
    // I want to make these glow - dont know how yet.. 
    // so just placeholder on sdf surface.
    // color -= ((triLine * -vec3(1.,2.92,1.9) )*.135);
    
    return color;
}

void main(void) {
    
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;

    vec3 ro = get_mouse(vec3(0.0,0.0,-7.));
    vec3 ta = vec3(0.0,0.0,0.);
    mat3 cameraMatrix = get_camera(ro, ta, 0. );
    vec3 rd = cameraMatrix * normalize( vec3(uv.xy, .85) );

    vec3 color = render(ro, rd, uv, 0.);
    glFragColor = vec4(color,1.0);
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 fragRayOri, in vec3 fragRayDir ) {

      vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy ) / resolution.y;
    vec3 ro = fragRayOri + vec3(0.0,0.0,-7.);
    vec3 rd = fragRayDir;
    
    vec3 color = render(ro, rd, uv, 1.);
      glFragColor = vec4(color, 1.0);
}

