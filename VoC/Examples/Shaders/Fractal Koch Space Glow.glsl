#version 420

// original https://www.shadertoy.com/view/NtlSWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 * Modified based on KIFS learnings from Art of Code on YouTube.
 * https://youtu.be/il_Qg9AqQkE
 **/
#define PI 3.14159

float sdfLine(vec2 P, vec2 A, vec2 B, float r) {
    vec2 pa = P-A, ba = B-A;
    float h = min(1.0,
              max(0.0,
                  dot(pa, ba)/
                  dot(ba, ba)));
    return length(pa-ba*h) - r;
}

vec3 lightSpace(vec2 uv) {
    
    vec2 A = vec2(-1., -1.);
        A.y += sin(time * .8) * .85;

    vec2 B = vec2(1., 1.);
       B.y += sin(time * .7) * .45;
    
    //uv.y = abs(uv.y);
    
    vec3 col = vec3(0.);
    
    A.x -= 0.5;
    B.x -= 0.5;

    float strokeWidth = 3. * 1./resolution.x; // Scale by N units of the X resolution
    float line1 = sdfLine(uv, A, B, strokeWidth);

    /* BLUE */
    //line1 = smoothstep(.0, .03, line1);
    col += (1.-line1) * vec3(.25, .55, 1.);
    
    A.x *= -.7;
    B.x *= -.8;

    /* GREEN */
    float line2 = sdfLine(uv, A, B, strokeWidth);
    //col = mix(col, vec3(.0, .95, .33), line2);
    //line2 = smoothstep(.0, .03, line2);
    col += (1.-line2) * vec3(.0, .95, .33);

    //A.x -= .5;
    A.y *= -1.;
    //B.x -= 1.3;
    B.y *= -.5;

    /* PINK */
    float line3 = sdfLine(uv, A, B, strokeWidth);
    //col = mix(col, vec3(.8, .05, .4), line3);
    //line3 = smoothstep(.0, .03, line3);
    col += (1.-line3) * vec3(.8, .05, .4);

    // Output to screen
    return col * .6;
}

vec2 N(float angle) {
    return vec2(abs(sin(angle)), cos(angle));
}

vec3 foldSpace( vec2 uv ) {

    // Reflection angle changes over time
    float angle = 6./7.*PI;
    vec2 n = N(angle);
    float recip = 1./resolution.y;
    
    vec3 col = vec3(0);
    
    // Reflect x across y
    uv.x = abs(uv.x);
    // Move up to adjust for reflection angle `n`
    uv.y += tan(angle) * .5;
    
    //uv.y = abs(uv.y);
 
    
    // Move the reflection origin to the right
    float d = dot(uv - vec2(0.5, 0), n);
    
    // Calculate the distance from `uv` to the reflection line
    uv -= n * max(0., d) * 2.;
    
    // Offset X to counter the increment in the first
    // iteration of the loop.
    uv.x += .5;
    
    n = N(-time * 0.26 * PI + PI);
        
    float scale = 1.;
    for (int i=0; i<5; i++) {
        uv *= 3.;
        scale *= 3.;
        uv.x -= 1.5;  

        uv.x = abs(uv.x);
        uv.x -= .5;
        uv -= n * min(0., dot(uv, n)) * 2.;
        
        // paint the fold lines
        //col.rgb += .1 * smoothstep(2.*recip, .0, abs(dot(uv,n))/scale);
        col += .25 * clamp(lightSpace(uv), .0, .7);
    }
 
    // Paint the Koch line
    //d = length(uv - vec2(clamp(uv.x, -1., 1.), 0.));
    //col += .5 * smoothstep(4.*recip, .0, d/scale);

    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;

    vec3 col = vec3(0.);

    // Initial zoom
    uv *= .95; //1.05
    
    // Fun vertical offset
    uv.y += .25;
    
    // Reflectomatic
    uv.y = abs(uv.y);
    
    // Paint the background
    col += lightSpace(uv);
    
    // Fold and paint more!
    col += foldSpace(vec2(uv.x, uv.y-.25));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
