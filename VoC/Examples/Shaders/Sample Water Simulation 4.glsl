#version 420

//////////////////////////////////
//                //
//          VRG corp              //
//                //
//        Le kubikoto,        //
//       Le kubikoto,        //
//        Le kubikoto,    //
//           ....        //
//   A les plus gros biscotos   //
//                   //
//////////////////////////////// *

// Anyone knows how to compute a normal from a "heightmap" ? (tried some stuff)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D backbuffer;

float snoise( vec2 v );

float getHeight(vec2 uv){
    return texture2D(backbuffer, uv).a;    
}
void setHeight(float h){
    glFragColor.a = h;    
}

vec3 nrm(vec2 p) {
    vec3 q = vec3(1./resolution.x, 1./resolution.y, 0.)*10.;
    float dx = max(texture2D(backbuffer, p + q.xz).a, texture2D(backbuffer, p - q.xz).a);
    float dy = max(texture2D(backbuffer, p + q.zy).a, texture2D(backbuffer, p + q.zy).a);
    float dz = texture2D(backbuffer, p).a;
    return normalize(vec3(dx, dy, dz));
}

float computeHeight(vec2 uv, float cHeight, float k){
    vec2 off = 1./resolution.xy;
    float height = cHeight*(1.-k*1.);
    k/=8.;
    height+= texture2D(backbuffer, uv + vec2(-off.x, -off.y)).a*k;
    height+= texture2D(backbuffer, uv + vec2(-off.x, 0.)).a*k;
    height+= texture2D(backbuffer, uv + vec2(-off.x, off.y)).a*k;
    
    height+= texture2D(backbuffer, uv + vec2(0., -off.y)).a*k;
    height+= texture2D(backbuffer, uv + vec2(0., off.y)).a*k;
    
    height+= texture2D(backbuffer, uv + vec2(off.x, off.y)).a*k;
    height+= texture2D(backbuffer, uv + vec2(off.x, 0.)).a*k;
    height+= texture2D(backbuffer, uv + vec2(off.x, off.y)).a*k;
    
        
        
    return height;
}
float computeHeightAlt(vec2 uv, float cHeight, float k){
    vec2 off = 1./resolution.xy;
    k = (1.-k*1.);
    float height = cHeight*k;
    height= max(height, texture2D(backbuffer, uv + vec2(-off.x, -off.y)).a*k);
    height= max(height, texture2D(backbuffer, uv + vec2(-off.x, 0.)).a*k);
    height= max(height, texture2D(backbuffer, uv + vec2(-off.x, off.y)).a*k);
    
    height= max(height, texture2D(backbuffer, uv + vec2(0., -off.y)).a*k);
    height= max(height, texture2D(backbuffer, uv + vec2(0., off.y)).a*k);
    
    height= max(height, texture2D(backbuffer, uv + vec2(off.x, off.y)).a*k);
    height= max(height, texture2D(backbuffer, uv + vec2(off.x, 0.)).a*k);
    height= max(height, texture2D(backbuffer, uv + vec2(off.x, off.y)).a*k);
    height+=((mix(snoise(uv*10.)+snoise(uv*5.), snoise(uv*10.+vec2(36.))+snoise(uv*5.+vec2(36.)),cos(time*1.)*.5+.5)*0.1)-.05)*smoothstep(0.1, 1., height);
        
        
    return height;
}
vec3 getBackground(vec2 p){
    return vec3(step(.5, mod(p.x*10., 1.))*step(.5, mod(p.y*10., 1.))+step(.5, mod(p.x*10.+.5, 1.))*step(.5, mod(p.y*10.+.5, 1.)));
}
void main( void ) {

    vec2 p = gl_FragCoord.xy/resolution.xy;
    float height = getHeight(p);
    vec3 normal = nrm(p);
    float angle = dot(vec3(0., 1., 0.), -normal)*.5+.5;
    vec3 color = vec3(dot(vec3(0., 1., 0.), normal)*.5+.5);
    color = mix(vec3(.0, .75, 1.), vec3(1., 1., 1.0), angle*2.);
    height = max(height, step(distance(mouse, p), 0.1));
    height = computeHeightAlt(p, height, .05);
    
    color = mix(color, getBackground(p+normal.xy*10./resolution.xy), .25);
    
    glFragColor = vec4(color, 0.);
    setHeight(height);

}

vec3 mod289( vec3 x ) 
{
    return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0;
}

vec2 mod289( vec2 x ) 
{
    return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0;
}

vec3 permute( vec3 x ) 
{
    return mod289( ( ( x * 34.0 ) + 1.0 ) * x );
}

float snoise( vec2 v )
{ 
    const vec4 C = vec4( 0.211324865405187,  // (3.0-sqrt(3.0))/6.0  ; for skewing simplex origin to cartesian space???
               0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)        ; for skewing input coord's to "simplex space"???
              -0.577350269189626,  // -1.0 + 2.0 * C.x           ; offset for finding simplex corners in cartesian space???
               0.024390243902439); // 1.0 / 41.0
    
    // First corner
    vec2 i  = floor( v + dot( v, C.yy ) ); 
    vec2 x0 = v - i + dot( i, C.xx ); 
    
    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    
    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
    
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    
    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
    
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}
