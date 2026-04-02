#version 420

// original https://www.shadertoy.com/view/wtyGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsl2rgb(vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
  return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

float random (vec2 p) {
    return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453123);
}

vec4 firework(vec2 p, float n) {

    float dur = 3.; 
    float id = floor(time/dur-n) + n*8.;
    float t = smoothstep(0., 1., fract(time/dur-n));
    float t1 = max(0.0, 0.5 - t); 
    float t2 = max(0.0, t - 0.5); 
    p.y += t1; 
    p.y -= random(vec2(n*35.+id, n*45.+id))*0.3; 

    p.x += n - 0.5 + mix(0., sin(id)*0.4, t1);
    
    vec4 c=vec4(0.0);
    if ( dot(p,p) > 0.002 + t2 *0.1 ) 
        return c; 
    vec3 rgb = hsl2rgb(vec3(id*0.3, .8, .7)); 
    for (float i = 0.; i < 77.; i += 1.) {

        float angle = i + t*sin(i*4434.);
        float dist = 0.15 + 0.2 * random(vec2(i*351. + id, i*135. + id)); 

        vec2 pt = p + vec2(dist*sin(angle), dist*cos(angle)); 
        pt = mix(p, pt, t2); 

        float r = .03 * (1. - t) * t2 +
                  .002*t*t*(1. - max(.0, t - .9)*10.); 

        float d = 1. - smoothstep(sqrt(dot(pt, pt)), .0, r); 
        c += vec4(rgb, 1.) * d;
    }
    return c;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
  vec4 col = vec4(0.0);
  uv.x *= resolution.x/resolution.y; 
  for (float n = 0.; n < 6.; n += 1.) 
      col += firework(uv, n/6.) - 0.05;
  glFragColor = col;
}
