#version 420

// original https://www.shadertoy.com/view/XsKBWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    The Problem of Apollonius is a famous geometry problem from antiquity, 
    named after Apollonius of Perga. It can be stated as 

        "Given three circles, find a fourth circle that is simultaneously 
         tangent to the initial three circles." 

    The problem is equivalent to finding the the simultaneous solution of 
    three quadratic equations:

        (x - x_1)² + (y - y_1)² = (r - s_1*r_1)²
        (x - x_2)² + (y - y_2)² = (r - s_2*r_2)²
        (x - x_3)² + (y - y_3)² = (r - s_3*r_3)²

    for some combination of signs s_1, s_2 and s_3. 

    The signs decide if the tangency is *external* (i.e. the solution 
    circle touches the other circle on the outside), or if it is internal 
    (i.e. the solution circle touches the other circle on the inside. 

    Through the last couple millennia a myriad of solution strategies has
    been introduced, many of them geometric (solved with a compass and
    straight edge). The solution used here is a purely arithmetic one. 

    For more information on this solution strategy, see
    
        https://www.sharelatex.com/read/mxqspwvsbhny

    ---

    In this shader we show all 4 solution pairs at the same time in four
    separate panels. This is less cluttered than showing all 8 solutions
    at the same time. The two solutions in each panel is related to each
    other by a simple sign change, turning every externally tangent
    circle into internally tangent, and vice-versa. 
    
    ---

    Some caveats:

        1. The number of unique solutions is at most 8. If some circles
           overlap, or if the radius of one or more circles become 
           zero (a point) or infinite (a line), multiple solutions 
           become the same. 
        
        2. The solution might result in a negative radius. This still
           results in a drawable circle if one uses the absolute value,
           but externally tangent circles becomes internally tangent, 
           and vice-versa. 

        3. Due to the quadratic nature of the equations there are always
           two solutions of the radius (as long as they are not complex). 
           This means that flipping all the tangency signs gives the same
           pair of solutions, only with their order interchanged and the
           sign flipped. 
*/

// declarations
float sdDisk(vec2 p, float r);
float sdCircle(vec2 p, float r, float t);

vec3 compose(vec3 old, vec3 col, float d);

float perpdot(vec2 u, vec2 v);
void solveApollonius(in vec2 P1,  in vec2 P2,  in vec2 P3, 
                     in float s1, in float s2, in float s3, 
                     in float R1, in float R2, in float R3, 
                     out vec2 p1, out vec2 p2, 
                     out float r1, out float r2);

#define ANIMATE

//
void main(void) {
    // constants
    vec2 C1 = vec2(-0.45, -0.45);
    vec2 C2 = vec2( 0.5, -0.55);
    vec2 C3 = vec2( 0.0,  0.55);
    
    #ifdef ANIMATE
    C1 = C1 - 0.2*vec2(sin(time), cos(time));
    #endif 
    
    float R1 = 0.3;
    float R2 = 0.4;
    float R3 = 0.5;

    // split into 4 panels, 2x2
    vec2 res = 0.5*resolution.xy;
    vec2 coord = mod(gl_FragCoord.xy, res);

    // integers to identify subwindows
    uvec2 xy = uvec2(2.0*(gl_FragCoord.xy/resolution.xy));

    // aspect-ratio corrected position in each panel
    vec2 uv = (2.0 * coord - res)/res.yy;
    uv *= 1.2;
    

    // background color
    vec3 col = vec3(1.0);
    
    // base circles
    col = compose(col, vec3(0.0), sdCircle(uv - C1, R1, 0.01));
    col = compose(col, vec3(0.0), sdCircle(uv - C2, R2, 0.01));
    col = compose(col, vec3(0.0), sdCircle(uv - C3, R3, 0.01));
    
    // apollonius circles
    vec2 p1, p2;
    float r1, r2;
    if (xy == uvec2(0, 0)) {
        // blue: externally tangent to all circles
        // red:  internally tangent to all circles
        solveApollonius(C1, C2, C3, 1.0, 1.0, 1.0, R1, R2, R3, p1, p2, r1, r2);
    } else if (xy == uvec2(1, 0)) {
        // blue: first circle internally tangent, rest externally tangent
        // red:  first circle extnally tangent, rest internally tangent
        solveApollonius(C1, C2, C3, -1.0, 1.0, 1.0, R1, R2, R3, p1, p2, r1, r2);
    } else if (xy == uvec2(0, 1)) {
        // blue: second circle internally tangent, rest externally tangent
        // red:  second circle extnally tangent, rest internally tangent
        solveApollonius(C1, C2, C3, 1.0, -1.0, 1.0, R1, R2, R3, p1, p2, r1, r2);
    } else if (xy == uvec2(1, 1)) {
        // blue: third circle internally tangent, rest externally tangent
        // red:  third circle extnally tangent, rest internally tangent
        solveApollonius(C1, C2, C3, 1.0, 1.0, -1.0, R1, R2, R3, p1, p2, r1, r2);
    }
    col = compose(col, vec3(1.0, 0.0, 0.0), sdCircle(uv - p1, abs(r1), 0.01)); 
    col = compose(col, vec3(0.0, 0.0, 1.0), sdCircle(uv - p2, abs(r2), 0.01)); 
    
    
    // borders for each subwindow
    if (coord.x < 1.0 || 
        coord.y < 1.0 || 
        coord.x >= res.x-2.0 || 
        coord.y >= res.y-2.0 ||
        gl_FragCoord.x < 3.0 || 
        gl_FragCoord.y < 3.0 || 
        gl_FragCoord.x >= resolution.x-3.0 || 
        gl_FragCoord.y >= resolution.y-3.0) {
        col = vec3(0.0);   
    }
    
    glFragColor = vec4(col,1.0);
}

//
float sdDisk(vec2 p, float r) {
    return length(p) - r;
}

float sdCircle(vec2 p, float r, float t) {
    return abs(length(p) - r) - t;
}

vec3 compose(vec3 old, vec3 col, float d) {
    float w = 1.5*fwidth(d);
    float s = smoothstep(-w/2.0, w/2.0, d);
    return old*s + col*(1.0 - s);
}

float perpdot(vec2 u, vec2 v) {
     return u.x*v.y - u.y*v.x;   
}

// TODO: optimize by shifting origin using P3.
void solveApollonius(in vec2 P1,  in vec2 P2,  in vec2 P3, 
                     in float s1, in float s2, in float s3, 
                     in float R1, in float R2, in float R3, 
                     out vec2 p1, out vec2 p2, 
                     out float r1, out float r2) {
    // see https://www.sharelatex.com/read/mxqspwvsbhny
    float A1 = (dot(P1, P1) - R1*R1)/2.0 - (dot(P3, P3) - R3*R3)/2.0;
    float A2 = (dot(P2, P2) - R2*R2)/2.0 - (dot(P3, P3) - R3*R3)/2.0;
    
    float B1 = (s1*R1 - s3*R3);
    float B2 = (s2*R2 - s3*R3);
    
    float D = perpdot(P1, P2) + perpdot(P2, P3) + perpdot(P3, P1);
    
    float M = (A1*(P2.y - P3.y) - A2*(P1.y - P3.y))/D;
    float N = (B1*(P2.y - P3.y) - B2*(P1.y - P3.y))/D;
    float P = (-A1*(P2.x - P3.x) + A2*(P1.x - P3.x))/D;
    float Q = (-B1*(P2.x - P3.x) + B2*(P1.x - P3.x))/D;
    
    float a = N*N + Q*Q - 1.0;
    float b = 2.0*(M*N + P*Q - N*P3.x - Q*P3.y + s3*R3);
    float c = M*M + P*P - 2.0*M*P3.x - 2.0*P*P3.y + dot(P3, P3) - R3*R3;
    
    r1 = (-b - sqrt(b*b - 4.0*a*c))/(2.0*a);
    r2 = (-b + sqrt(b*b - 4.0*a*c))/(2.0*a);
    
    p1 = vec2(M+N*r1, P + Q*r1);
    p2 = vec2(M+N*r2, P + Q*r2);
}
