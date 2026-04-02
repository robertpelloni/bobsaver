#version 420

/*
* No Man's Sky inspired shader by Jaksa
*/

const float PERIOD = 5.0;
const int ITER = 64;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float x) {
    
    return fract(sin(123.321*x)*321.113);
}

float seed(float x) {
    vec2 quad = floor( 2.0* gl_FragCoord.xy / resolution.xy );
    return hash(x + floor(time/PERIOD) + 31.0*quad.x + 29.0*quad.y);
}

float h(vec2 p) {
    float h = -6.0;
    float octave = 1.3 * seed(1.0);
    p /= 3.0;
    for (int i = 0; i < 6; i++) {
        h -= octave * (sin(p.x) + sin(p.y));
        p = p * 2.1 + 10.0*seed(1.0) - vec2(seed(4.0)*p.y, -seed(5.0)*p.x);
        octave /= 2.5;
    }
    return h;
}

float h2(vec2 p) {
    return h(vec2(p.x + 3.*h(p), p.y + 2.*h(p)));
}

float dist(vec3 p) {
    return p.y - h2(p.xz);
}

vec2 grad(vec2 p, float delta) {
    vec2 d = vec2(delta, 0);
    return (vec2(h2(p + d.xy), h2(p + d.yx)) - h2(p))/d.x;
}

vec3 sunCol(vec3 dir) {
    vec2 sunPos = vec2(seed(2.0)*2.0 - 1.0, .5 - seed(3.0)*.5);
    vec3 s = .05/length(sunPos - dir.xy) * vec3(1);
    s += seed(1.0)/3.0;
    s *= pow(length(s), 3.0);
    return s;
}

vec3 sky(vec3 dir) {
    vec3 s = vec3(seed(1.0), seed(2.0), seed(3.0));
    s += .6-abs(dir.y);
    s += sunCol(dir);
    return s;
}

vec3 groundCol(vec2 p) {
    vec3 s = vec3(seed(4.0), seed(5.0), seed(6.0)) ;
    s *= .2;
    s += 0.2 * h(p/4.) + 1.0;
    //s = vec3(0);
    s += vec3(.4, .2, .1) ;
    return s;
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position = mod(position, .5);
    position = position * 2.0 - .5;
    position.y /= resolution.x / resolution.y;
    
    
    
    vec3 o = vec3(0, 0, time);
    vec3 dir = normalize(vec3(position.xy, 1.0));
    float t = 1.0;
    vec3 p = o;
    float cost = 0.0;
    for (int i = 0; i < ITER; i++) {
        p = o + dir * t;
        float d = dist(p);
        // float step = mix(0.4, 1.0, float(i)/float(ITER));
        float step = 0.4;
        t += d*step;
        cost += 1./64.;
        if (abs(d) < 0.001) break;
        if (t > 100.0) break;
    }
    
    vec2 g = grad(p.xz, 0.01);
    g += grad(p.xz, 0.5);
    g += grad(p.xz, 1.5);
    g += grad(p.xz, 5.0);
    
    // TODO use fresnel equation
    float b = (g.x + g.y)/4.0;
    b = max(0.0, b) + .1;
    vec3 skyCol = sky(dir);
    vec3 col = mix(groundCol(p.xz) + .1, vec3(0.1), b);
    
    float fade = 1.0 - t/(200.0 - 150.0*seed(7.0));
    col = mix(skyCol, col, fade);
    col = max(vec3(0.0), col);
    
    float sp = 1.0 - dot(g, dir.xz);
    sp = pow(sp, 3.0);
    sp /= length(g)*8.+4.0;
    sp = clamp(0.0, .5, sp);
    sp = sp*mix(0.02, 1.0, seed(8.0));
    col += sp;
    
    col += cost*.3*skyCol - .2;
    
    // TODO add water
    
    if (t > 100.0) col = sky(dir);
    
    // TODO add particles
        
    glFragColor = vec4(col, 1.0 );
    //glFragColor = vec4(vec3(cost), 1.0 );

}
