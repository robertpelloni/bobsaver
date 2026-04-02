#version 420

// original https://www.shadertoy.com/view/tdXBRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a, b, t) smoothstep(a,b,t)

// inspired from https://www.youtube.com/watch?v=eKtsY7hYTPg

struct ray {
    vec3     o, // origin
            d; // direction
};

    ray GetRay(vec2 uv, vec3 camPos, vec3 lookAt, float zoom) {
        ray a;
        a.o = camPos;

        vec3 forward = normalize(lookAt-camPos);
        vec3 right = cross(vec3(0,1,0), forward);
        vec3 up = cross(forward, right);
        vec3 centerScreen = a.o + forward * zoom;
        vec3 intersection = centerScreen + uv.x * right + uv.y * up;

        a.d = normalize(intersection-a.o);

        return a;
    }

// project a ray and calculate which is the closest point
// on that ray to an input point
vec3 ClosestPoint(ray r, vec3 p) {
    return r.o + max(0.0, dot(p-r.o, r.d))*r.d;
}

// calculate the distance from a point to a ray
// first finds the closest point of the ray to the point
// then calculate the distance
float DistRay(ray r, vec3 p) {
    return length(p - ClosestPoint(r, p));
}

float Bokeh(ray r, vec3 p, float size, float blur) {
    float d = DistRay(r, p);

    // smoothstep from the center
    float c = S(size, size*(1.-blur), d);
    // ring outside the circle, 70% the width of the circle
    float ring = S(size*.7, size, d);
    // mix(inColor, outColor, ring)
    c *= mix(.7, 1., ring);
    
    return c;
}

float  hue2rgb(float p, float q, float t){
    if(t < 0.) t += 1.;
    if(t > 1.) t -= 1.;
    if(t < 1./6.) return p + (q - p) * 6. * t;
    if(t < 1./2.) return q;
    if(t < 2./3.) return p + (q - p) * (2./3. - t) * 6.;
    return p;
}

vec3 HslToRgb(float h, float s, float l){
    vec3 rgb = vec3(1.);

    if(s == 0.){
        return rgb; // achromatic
    }else{
        float q = l < 0.5 ? l * (1. + s) : l + s - l * s;
        float p = 2. * l - q;
        rgb.r = hue2rgb(p, q, h + 1./3.);
        rgb.g = hue2rgb(p, q, h);
        rgb.b = hue2rgb(p, q, h - 1./3.);
    }

    return rgb;
}

void main(void)
{
    float time = time * 0.5;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
    vec3 camPos = vec3(.0, .0, .0);
    vec3 lookat = vec3(.0, .0, 1.0);
    // this is the camera ray :)
    ray r = GetRay(uv, camPos, lookat, 2.);
    
    // draw!
    float snowflakes = .0;
    vec3 col = vec3(.7,.4,.0);
    vec3 frag = vec3(.0);
    for (float i = 0.; i < 80.; i++) {
        // the position is a weird lissajous curve
        vec3 p = vec3(
            (sin(time+i)+cos(time+i+0.5))*2.,
            cos(time + i * cos(time*0.1)),
            (
                (sin(time+i)*
                 sin(time+i+0.5)*15.
                )+7.)
        );
        // choosing the side of color wheel, the number
        // is used to offset color position
        float side = fract(i/2.) >= 0.5 ? 0. : 0.5;
        vec3 color = HslToRgb(
                (i/80.) + sin(time*.4) + side,
                1.2,
                0.6);
        
        // the circle size vary
        float circleSize = (abs(cos(i))+.2)*.15;
        
        // blending max
        frag = max(frag, Bokeh(r, p, circleSize, .1) * color);
    }
    
    // Output to screen
    glFragColor = vec4(1.-frag,1.);
}
