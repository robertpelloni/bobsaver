#version 420

// Author: rigel, 
// https://www.shadertoy.com/user/rigel
// licence: https://creativecommons.org/licenses/by/4.0/
// reference design: https://patterninislamicart.com/drawings-diagrams-analyses/5/geometric-patterns-borders/gpb033

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdfRect(vec2 uv, vec2 s) { vec2 auv = abs(uv); return max(auv.x-s.x,auv.y-s.y); }

vec2 toPolar(vec2 uv) { return vec2(length(uv),atan(uv.y,uv.x)); }
vec2 toCarte(vec2 z) { return z.x*vec2(cos(z.y),sin(z.y)); }

float stroke(float d, float i) { return abs(smoothstep(.0,.02,abs(d))-i); }
float fill(float d) { return smoothstep(.0,.05,d); }

vec2 uvRotate(vec2 uv, float a) { return uv * mat2(cos(a),sin(a),-sin(a),cos(a)); }

float sdfMap(vec2 uv) {
   float r1 = sdfRect(uvRotate(uv,radians(30.)),vec2(.1,.5));
   float r2 = sdfRect(uvRotate(uv,radians(-30.)),vec2(.1,.5));
   return max(fill(r1)*stroke(r2,1.),stroke(r1,1.));
}

vec3 scene(vec2 uv) {
    
    uv = uvRotate(uv,radians(sin(time)*20.0));
    vec2 z = toPolar(uv*6.);
    
    z = vec2(z.x,mod(z.y,radians(60.))-radians(30.));
    uv = toCarte(z);    
    uv -= vec2(2.,.0);

    z = toPolar(uv);
    z = vec2(z.x,mod(z.y,radians(120.))-radians(60.));
    uv = toCarte(z);    
    uv -= vec2(1.,.0);
    
    z = toPolar(uv);
    
    z = vec2(z.x,mod(z.y,radians(120.))-radians(60.));
    uv = toCarte(z);
    
    uv -= vec2(.5,.0);
    uv = vec2(sign(uv.y)*uv.x,abs(uv.y));
    uv -= vec2(0.,.3);
    
    return vec3(sdfMap(uv));
}

//https://www.shadertoy.com/view/llSyDh
vec4 lattice6(vec2 uv) {
    const vec2 s = vec2(1, 1.7320508);
    
    vec4 hC = floor(vec4(uv, uv - vec2(.5, 1))/s.xyxy) + .5;
    
    vec4 h = vec4(uv - hC.xy*s, uv - (hC.zw + .5)*s);
    
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + 9.43);
}

void main( void ) {
    vec2 uv = ( gl_FragCoord.xy - resolution.xy*.5)/ resolution.y ;
    glFragColor = vec4( scene(lattice6(uv).xy), 1.0 );
}
