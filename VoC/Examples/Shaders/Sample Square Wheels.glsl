#version 420

// original https://www.shadertoy.com/view/wlsBRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A funny little car with square wheels.
//
// https://mathcurve.com/courbes2d.gb/engrenage/engrenage2.shtml
// http://aesculier.fr/fichiersMaple/rouesdroles/rouesdroles.html
// https://en.wikipedia.org/wiki/Square_wheel

vec2 uv;
float T = 2.*asinh(1.);

float ZeroSet(float f, float linewidth)
{
    vec2 grad = vec2(dFdx(f), dFdy(f));
    float pxSize = max(length(grad), fwidth(uv.y));
    return clamp(linewidth-abs(f)/pxSize, 0., 1.);
}
float Fill(float f) {
    vec2 grad = vec2(dFdx(f), dFdy(f));
    float pxSize = max(length(grad), fwidth(uv.y));
    return clamp(max(-f, 0.)/pxSize, 0., 1.);
}
float ZeroSet(float f) { return ZeroSet(f, 2.); }
float Point(vec2 x) { return ZeroSet(length(x), 5.); }

float Segment(vec2 a, vec2 b, vec2 p)
{
    float h = clamp(dot(p-a,b-a) / dot(b-a,b-a), 0., 1.);
    float d = length(p-a - h*(b-a));
    return ZeroSet(d);
}

float wheel(float x0)
{
    float x0p = x0 - T*round(x0/T);
    vec2 q1 = vec2(x0, 0.);
    vec2 rot = normalize(vec2(1., -sinh(x0p)));
    vec2 uvp = mat2(rot.x, rot.y, rot.y, -rot.x) * (uv-q1);
    vec2 tmp = abs(uvp)-1.;
    float box = length(max(tmp,0.)) + min(max(tmp.x,tmp.y),0.);
    return box;
}

void main(void)
{
    // Set coordinates to [-1.,1.] vertically, and a little bit more
    // horizontally.
    uv = gl_FragCoord.xy/resolution.xy;
    uv = uv*2.-1.;
    uv.x *= resolution.x/resolution.y;
    // Scale and pan to taste
    uv *= 3.;
    uv.y += 1.;
    float xcar = 2.*(time - 2.1*cos(time/2.));
    uv.x += xcar;
    
    // Periodize the road
    float xp = uv.x - T*round(uv.x/T);
    // The road is piecewise given by the cosh function
    float fx = -cosh(xp);
    
    // Draw the wheels
    float x0 = xcar - T*1.25;
    float x1 = xcar + T*1.25;
    float wh0 = wheel(x0);
    float wh1 = wheel(x1);
    
    // Draw the car
    vec2 carc = vec2(xcar, 1.);
    vec2 carr = vec2(3.5, 1.7);
    float car = length((uv-carc)/carr) - 1.;
    
    vec3 col = vec3(0.95,0.94,0.9);
    //col = mix(col, vec3(0.8), ZeroSet(uv.y));
    col = mix(col, vec3(0.6, 0.8, 0.9), Fill(10.*car));
    col = mix(col, vec3(0.1, 0.5, 0.6), ZeroSet(10.*car));
    col = mix(col, vec3(0.5,0.9,0.7), Fill(wh0));
    col = mix(col, vec3(0.,0.7,0.4), ZeroSet(wh0));
    col = mix(col, vec3(0.5,0.9,0.7), Fill(wh1));
    col = mix(col, vec3(0.,0.7,0.4), ZeroSet(wh1));
    col = mix(col, vec3(0.), Point(vec2(x0,0.)-uv));
    col = mix(col, vec3(0.), Point(vec2(x1,0.)-uv));
    col = mix(col, vec3(1.,0.,0.), 0.2*ZeroSet(uv.y));
    col = mix(col, vec3(0.), 0.5*Fill(uv.y - fx));
    col = mix(col, vec3(0.), ZeroSet(fx - uv.y));
    
    // Output to screen
    glFragColor.rgb = col;
}
