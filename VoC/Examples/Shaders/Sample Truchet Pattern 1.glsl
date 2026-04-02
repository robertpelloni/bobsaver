#version 420

// original https://www.shadertoy.com/view/ssV3Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU (2.*PI)
#define blur_strength 0.

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec3 white = vec3(0.867,0.867,0.867);
vec3 black = vec3(0.133,0.157,0.192);
vec3 blue = vec3(0.188,0.278,0.369);
vec3 red = vec3(0.941,0.329,0.329);

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

/*
float square(vec2 st, vec2 center, float halfWidth) {
    vec2 p = st - center;
    return step(p.x, halfWidth)
        * step(-halfWidth, p.x)
        * step(p.y, halfWidth)
        * step(-halfWidth,p.y);
}
*/

// distance field... sooo much easier to work with omg...
float square(vec2 st, vec2 center, float halfWidth) {
    vec2 p = st - center;
    vec2 q = abs(p) - vec2(halfWidth);
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);
}

vec2 circlePolarCoords(vec2 st, vec2 center, float radius) {
    st = st - center;
    float angle = atan(st.x, st.y);
    return vec2(angle/TAU, length(st));
}

float circleOutline(vec2 st, vec2 center, float radius, float thickness) {
    float distToEdge = abs(radius - length(st - center));
    //return 1.0 - step(thickness, distToEdge);
    return 1.0 - smoothstep(thickness, thickness+0.002, distToEdge);
}

void main(void)
{
    float ma = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / vec2(ma, ma);
    
    // rotate
    //uv *= rot(-time*0.05);
    // zoom
    //uv *= mix(0.7, 1.3, 0.5 * 0.5 * sin((time+PI)*0.1));
    uv *= .7;
    // pan
    uv += vec2(time*0.02,-time*0.02);
    
    // Repitition
    uv *= 5.0;
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    vec3 col = blue;
    
    /*
     * Stripes used to give a bit more texture.
     */
    float stripe_str = 0.6;
    float stripesX = ceil(sin(gv.x*PI*60.));
    float stripesY = ceil(sin(gv.y*PI*60.));
    col = mix(col, stripe_str*blue, stripesX);
    
    // Recessed vignette
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    float d = square(uv0-.5, vec2(0), .5);
    col = mix(col*0.8, col, smoothstep(0., .07, abs(d)) );
    
    /*
     * Truchet tiles
     */
    float n = hash12(id);
    // Randomly rotate by some multiple of PI/2
    //float n = hash12(id+time*0.00001);
    
    n *= TAU;
    n = floor(n / (PI/2.)) * (PI/2.);
    
    gv -= 0.5;
    gv *= rot(n);
     
    vec3 redstripes = mix(red, 0.6*red, stripesY);
    //col = mix(col, redstripes, circle(gv, vec2(-.5,.5), 0.5));
    
    // Shading
    col = mix(col, col*0.8, circleOutline(gv, vec2(-.5,.5), 0.5, 0.13));
    col = mix(col, col*0.8, circleOutline(gv, vec2(.5,-.5), 0.5, 0.13));
    
    col = mix(col, white, circleOutline(gv, vec2(-.5,.5), 0.5, 0.1));
    col = mix(col, white, circleOutline(gv, vec2(.5,-.5), 0.5, 0.1));
    
    vec3 balackstripes = mix(black, stripe_str*black, stripesY);
    col = mix(col, balackstripes, circleOutline(gv, vec2(-.5,.5), 0.5, 0.05));
    col = mix(col, balackstripes, circleOutline(gv, vec2(.5,-.5), 0.5, 0.05));
    
    /*
     * Spinning things
     */
    vec2 cid = floor(uv+vec2(.5));
    vec2 cv = fract(uv+vec2(.5));
    float cn = hash12(cid);
    float dir = sign(cn-0.5);
    
    if (cn > 0.2 && cn < 0.8) {
        /*
         * Spinny circle
         */
        vec2 pv = circlePolarCoords(cv, vec2(.5), 0.2);
        float discAngle = fract(pv.x + dir*time * 0.15);
        float concentric = ceil(sin(pv.y*200.));
        concentric = mix(1.5, 1.6, step(0., sin(pv.y*200.)));
        //concentric = 1.3;
        vec3 disc = white * concentric;
        disc = mix(disc, red * concentric, smoothstep(discAngle, discAngle+.002, .75));
        disc = mix(disc, blue * concentric, smoothstep(discAngle, discAngle+.002, .5));
        disc = mix(disc, black * concentric, smoothstep(discAngle, discAngle+.002, .25));

        // wheel rim
        col = mix(col, col*0.8, smoothstep(pv.y, pv.y+.002, 0.27));
        col = mix(col, white, smoothstep(pv.y, pv.y+.002, 0.24));
        // wheel shading
        disc = mix(disc, disc*.2, pv.y*4.);
        // wheel
        col = mix(col, disc, smoothstep(pv.y, pv.y+.002, 0.2));
    } else {
        /*
         * Spinny square
         */
        vec2 center = vec2(.5);
        vec2 bv = cv - center;
        bv *= rot(dir*time*5.8);
        
        float d = square(bv, vec2(0), 0.14);
        
        float lines = mix(1.1, 1.2, step(0., sin(abs(d)*TAU * 30.)));
        vec3 box = white;
        box = mix(box, black * lines, smoothstep(bv.x, bv.x+.002, abs(bv.y)));
        box = mix(box, red * lines, smoothstep(abs(bv.x), abs(bv.x)+.002, bv.y));
        box = mix(box, blue * lines, smoothstep(abs(bv.y), abs(bv.y)+.002, abs(bv.x)));
        box = mix(box, white * lines, smoothstep(abs(bv.y), abs(bv.y)+.002, bv.x));
        
        
        // square rim
        col = mix(col, col*0.8, 1.0 - smoothstep(.0, .002, square(bv, vec2(0), 0.21)));
        col = mix(col, white, 1.0 - smoothstep(0., .002, square(bv, vec2(0), 0.18)));
        // square shading
        box = mix(box*.5, box, abs(d*10.));
        // square
        col = mix(col, box, smoothstep(d, d+.002, 0.));
    }
    
    
    glFragColor = vec4(col,1.0);
}
