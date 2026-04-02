#version 420

// original https://www.shadertoy.com/view/NddGzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)    mat2( cos(a+vec4(0,11,33,0)) )             // rotation                  
vec3 M;

#define TAU 6.283185

void main(void) { //WARNING - variables void (out vec4 O, vec2 U) {     need changing to glFragColor and gl_FragCoord.xy
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;

    float t=9.,l,a,A,s,z=0.,S,H,h,l2,r=25.,r2=20.33; //, Z=0.;
    vec2  P,d;
    vec3  R = vec3(resolution.xy,1.0),
          D = normalize(vec3( U+U, -3.5*R.y ) - R ),         // ray direction
          p = 90./R, q;                                      // marching point along ray 
       // M =  mouse*resolution.xy.xyz/R -.5;
          M = vec3(8,4,0)/1e2*cos(time+vec3(0,11,0));
     
    for ( O-=O ; O.x < 1.5 && t > .01 ; O+=.01 )
        t=9., q = p,
        q.yz *= rot( .5+6.*M.y),                             // rotations
        q.xz *= rot( 2.-6.*M.x),
        q.zy *= H = sign(h=q.y),           q.y -= r/2.,      // top-down symmetry
        q.xz *= S = sign(q.x +sign(q.z)) , q.x -= TAU*3.5,   // left-right symmetry
        l = length(q.xz), a = atan(q.z,q.x),
        s = min( TAU*3.5, l - a),                            // spiral coord ( truncated )
        l = round(s/TAU)*TAU + a,                            // l reset at tube center
        l = max(0.,r-l),
        q.y += r2 - sqrt(max(0.,r2*r2-l*l)),                 // spiral sinking
        t = min(t, length(vec2( mod(s+TAU/2.,TAU)-TAU/2.,q.y)) - 1.), // SDF
        p += .25*t*D; // , Z+=t;                             // step forward = dist to obj          

 // O = vec4(1.6-Z/200.); return;                    // for Depth buffer
    a = max (0., round(s/TAU)*TAU + a );
    a = S*H*a*a/2.-20.*time -H;                             // curvilinear coordinate
  //O = max(1.5-3.*O,0.);
    O = O.x > 1.5 ? vec4(0.) : 4.*exp(-3.*O/2.);             // luminance (depth + pseudo-shading )
                           // vec4(exp(-(Z-300.)/200.));
    O *= (.6+.4*sin(a)) *vec4(.5+.5*h/r2,.5-.5*h/r2,0,0);    // color
      // (.6+.4*clamp(sin(a)/fwidth(a),-1.,1.))
 // O *= .5+.5* vec4(cos(a),sin(a),min(2.,4.*h/r),1);
    
    glFragColor = O;
}
