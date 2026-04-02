#version 420

// original https://www.shadertoy.com/view/WtBSzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float manhattan_dist(vec2 a, vec2 b) {
    return abs(a.x-b.x)+abs(a.y-b.y);

}

float manhattan_dist2(vec2 a, vec2 b) {
    return abs(a.x-b.x)-abs(a.y-b.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 R = resolution.xy,
         uv = gl_FragCoord.xy/R.xy,
         c = vec2(0.5*R.x/R.y, 0.5);    // center

    uv = fract(uv*vec2(4., 3.));        // partition space in 4x3
    uv.x *= R.x/R.y;

    float md = manhattan_dist2(uv, c);
    float d = manhattan_dist(uv, c);
    //    d = distance(uv, c);
    
    float mp = sin(2.*time+abs(sin(0.2*time+5.*md*md)*md)*20.);  // manhattan pattern
    float mp2 = sin(2.*time+abs(sin(0.2*time+5.*md*md)*md)*40.); // another manhattan pattern
    float ep = sin(10.*time-d*70.);                               // circular (euclidian) pattern
    mp = smoothstep(-0.1, 0.1, mp);
    mp2 = 1.-smoothstep(-0.1, 0.1, mp2);
    ep = smoothstep(-0.1, 0.1, ep);

 
    vec3 col = mix(mp*vec3(0.05, 0.7, 0.6), mp2*vec3(0.8, 0.2, 0.05), ep);
    // vec3 col = mix(mp*vec3(0.02, 0.42, 0.4), mp2*vec3(0.8, 0.1, 0.15), ep);
    
    // Output to screen
    col = pow(col, vec3(1./2.2));
    glFragColor = vec4(col,1.0);
}
