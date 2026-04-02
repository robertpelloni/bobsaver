#version 420

// original https://www.shadertoy.com/view/MtBXRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

mat2 rotate(in float theta) {
    return mat2(
        cos(theta), -sin(theta), sin(theta), cos(theta)
    );
}

float noise(in vec2 uv) {
    return sin(1.5*uv.x)*sin(1.5*uv.y);
}

float fbm(vec2 uv) {
    float f = 0.0;
    f += 0.5000*noise(uv); uv = m*uv*2.02;
    f += 0.2500*noise(uv); uv = m*uv*2.03;
    f += 0.1250*noise(uv); uv = m*uv*2.01;
    f += 0.0625*noise(uv);
    return f/0.9375;
}

float fbm2(in vec2 uv) {
   vec2 p = vec2(fbm(uv + vec2(0.0,0.0)),
                 fbm(uv + vec2(5.2,1.3)));

   return fbm(uv + 4.0*p);
}

vec2 powX(in vec2 p) {
  return p + p + p + p;   
}

void main(void)
{
    // basic setup
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = -1.0 + 2.*uv;
    uv.x *= resolution.x/resolution.y;
    
    // colors
    vec3 m1 = vec3(.5, .5, 1.0);
    vec3 m2 = vec3(.5, 1.0, .5);
    vec3 m3 = vec3(1.0, .5, .5);
    
    // rotation speed
    float theta = time * .1;
    
    vec2 p = uv * rotate(theta * .5);
    vec2 p2 = uv * rotate(.835 + theta * .25);
    vec2 p3 = uv * rotate(.4175 + theta * .125);
    
    p = abs(p);
    p2 = abs(p2);
    p3 = abs(p3);
    
       vec3 base = vec3(
        .5 + .5 * cos(time)
    );
    
    vec3 c = base +
        m1 * fbm(
        powX(p) + time + fbm2(p + time * .1)
    ) + m2 * fbm(
         powX(p2) + time + fbm2(p2 + time * .1)
    ) + m3 * fbm(
         powX(p3) + time + fbm2(p3 + time * .1)
    );
    
    c = clamp(c, 0.0, 1.0);
    
    glFragColor = vec4(c * c * c *c , 1.0);
}
