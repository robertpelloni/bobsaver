#version 420

// original https://www.shadertoy.com/view/7tdXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// number of points
const float m = 50.;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
       
    // increment time (60. * time looks smooth, but bugs out faster)
    float t = floor(20. * time) - 1000.;

    // start point
    vec2 p = vec2(0.);
    
    // initialise d with "large" number
    float d = 1.;
    
    for (float i = 0.; i < m; i++) {
    t++;
    
    // next point in sequence, move further if further along the sequence
    // (bad use of h21)
    float k = 0.01;
    vec2 p2 = p + 0.2 * (i/m) * 
             (vec2(h21(vec2(k * t, k * (t + 1.))), h21(vec2(k * t, k * (t - 1.)))) - 0.5);
    
    // keep points on screen
    p2 = clamp(p2, -0.48, 0.48);
    
    // length from points / segments
    float d2 = min(0.5 * length(uv - p2), 2. * sdSegment(uv, p, p2));
    
    //float k = step(h21(vec2(t, t + 1.)), 0.5);
    p = p2; //mix(vec2(0.), p2, k);
    d = min(d, d2);
    
    // fade points 
    d += 0.0005; // + 0.0007 * cos(3. * time + i / m);
    }
    
    // draw stuff
    float s = smoothstep(-0.03,0.03,0.005 - d); //-step(d, 0.01);
    s = clamp(s, 0., 1.);
    s *= 4. * s;//4.2 * s * cos(4. * s + 10. * time) + 4.5 *s;
    vec3 col = vec3(s);
    

    glFragColor = vec4(col,1.0);
}
