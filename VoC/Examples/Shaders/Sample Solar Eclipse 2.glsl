#version 420

// original https://www.shadertoy.com/view/ls2fzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Rigel
// First shader and total noob :) all the knowledge to make this 
// shader came from this one by iq...
// https://www.shadertoy.com/view/lsfGRr

// returns a random number
float hash(vec2 p) {
  return fract(sin(dot(p,vec2(12.9898,78.2333)))*43758.5453123);
}

// return a noise value in a 2D space
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash( i + vec2(0.0,0.0) ),
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ),
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// returns a fractal noise in a 2D space
float fbm ( vec2 p ) {
    // rotation matrix to spin the noise space and remove axial bias
    mat2 m = mat2(0.8,0.6,-0.6,0.8);

    float f = 0.0;
    f += 0.5000*noise ( p ); p*=m*2.02;
    f += 0.2500*noise ( p ); p*=m*2.04;
    f += 0.1250*noise ( p ); p*=m*2.03;
    f += 0.0650*noise ( p ); p*=m*2.01;
    // normalize f;
    f /= 0.9375;
    return f;
}

void main(void) {
  vec2 p = -0.5 + gl_FragCoord.xy / resolution.xy;
  p.x *= resolution.x / resolution.y;

  float r = sqrt( dot(p,p) ); // radius

  // abs is to fix the -pi/pi discontinuity in atan and noise artifact  
  float a = atan( p.y, abs(p.x) ); // angle

  vec3 color = vec3(0.,0.,0.140);
  float anim = time*0.7;

  // red burn
  float f = 1.0 - smoothstep(0.2,0.45, r);
  color = mix(color, vec3(0.47,0.11,0.09), f);

  // shine
  f = smoothstep(0.4, 0.3, 2.0 * length(p - vec2(0.1,0.1)));
  color += vec3(1.0,0.85,0.68) * f ;

  // angular distortion
  float aa = a + 0.2 * fbm (15.0*p);

  // heat
  f = smoothstep(0.2, .45, r);
  color = mix(color, vec3(0.210,0.093,0.020), f*fbm(vec2(10.0*r-anim,10.0*aa)));

  // dissipation
  f = smoothstep(0.40, .5, r);
  color = mix(color, vec3(0.0,0.0,0.140),f);

  // radius of the sun
  float rs = fbm(vec2(20.0*r-anim,15.0*aa));

  // sun
  f = 1.0 - smoothstep(0.29,0.3+(rs*0.02), r);
  color = mix(color, vec3(0.9,0.8,0.490), f);

  // corona
  f = 1.0 - smoothstep(0.2, .42, r);
  color = mix(color, vec3(0.965,0.750,0.008), f*rs);

  // moon
  f = smoothstep(0.29,0.3,r);
  color *= f;

  // flare
  f = smoothstep(3.5, 0.2, 25.0 * length(p - vec2(0.2,0.2)));
  color += vec3(.9,0.7,0.0) * 0.3 * f ;

  // atmosphere
  color = mix(color, vec3(.9,0.8,0.6), smoothstep(0.4,1.0,r)*0.2*fbm(vec2(4.1*r-anim,25.*(a+0.2 * fbm (3.0*p)))));

  glFragColor = vec4(color,1.0);
}
