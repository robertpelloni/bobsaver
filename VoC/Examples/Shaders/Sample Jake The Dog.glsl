#version 420

// original https://www.shadertoy.com/view/wtjSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AspectRatio  (resolution.y / resolution.x);

#define SSTEP(a, b, x) smoothstep((a)-(x), (a)+(x), b)

float inCircle(in vec2 pt, in float r) {
    pt.y *= AspectRatio;
    float dp = dot(pt, pt);
    return SSTEP(dp, r*r, 0.0015*r);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    
    // Background color;
    vec3 bgColor = vec3(1.0, 0.7, 0.0);
    
    vec3 col = bgColor;

    // Time variation
    float vt1 = sin(0.125*time)*sin(-0.4*time);
    float vt2 = 0.5*(1.0 + sin((2.5-0.05*vt1)*time));
    float vt3 = sin(0.5*time);
    
    // Eyes
    float eyeSpace = 0.17;
    float eyeLevel = 0.7;
    vec2 leftEyePos = uv - vec2(0.5 - eyeSpace, eyeLevel);
    vec2 rightEyePos = uv - vec2(0.5 + eyeSpace, eyeLevel);
    
    vec3 backEyeColor = vec3(0.15, 0.15, 0.1);    
    float backEyeRadius = 0.1;
    float inLeftEye = inCircle(leftEyePos, backEyeRadius);
    float inRightEye = inCircle(rightEyePos, backEyeRadius);
    
    // back (black) eyes with contour
    col = mix(col, backEyeColor, inLeftEye + inCircle(leftEyePos, 1.05*backEyeRadius));
    col = mix(col, backEyeColor, inRightEye + inCircle(rightEyePos, 1.05*backEyeRadius));
    
    // front (white) eyes
    vec3 frontEyeColor = vec3(0.9, 0.9, 0.95);
    float frontEyeSpace = (0.3 + mix(0.0, 0.2, vt1)) * backEyeRadius;
    float frontEyeRadius = backEyeRadius - frontEyeSpace;
    col = mix(col, frontEyeColor, inLeftEye * inCircle(leftEyePos - frontEyeSpace * vec2( vt1, 0.4 + vt3), frontEyeRadius));
    col = mix(col, frontEyeColor, inRightEye * inCircle(rightEyePos - frontEyeSpace * vec2( vt1, 0.4 + vt3), frontEyeRadius));
    
    // shiny corner eyes
    frontEyeSpace *= 1.5;
    frontEyeRadius = mix(0.075, 0.75, abs(vt1)) * (backEyeRadius - frontEyeRadius);
    col = mix(col, frontEyeColor, inLeftEye * inCircle(leftEyePos + frontEyeSpace * vec2(0.75, 1.0), frontEyeRadius));
    col = mix(col, frontEyeColor, inRightEye * inCircle(rightEyePos + frontEyeSpace* vec2(0.75, 1.0), frontEyeRadius));
    
    // mouth
    {
        vec2 mouthPos = uv - vec2(0.5, 0.23 + 0.0125*vt2);
        
        vec2 pt = 2.0*mouthPos;
        pt.y -= abs(sin(pt.x * pt.x * 2.5));
        float d = dot(pt, pt);
        
        // contour
        float insideMouth = SSTEP(d, 0.1025, 0.005);
        col = mix( col, vec3(0.0), insideMouth);
        // inside
        insideMouth = SSTEP(d, 0.1, 0.005);
        vec3 mouthColor = vec3( 0.3, 0.0, 0.05);
        col = mix( col, mouthColor, insideMouth);

    
        // teeth
        pt = 50.0*(mouthPos - vec2(0.0, 0.11));
        
        float d1 = 2.25 * (2.0*(fract(0.25*pt.x + 0.5)-0.5));
        float d2 = 1.0 - sqrt(1.0 - 0.4*d1*d1);
        
        // curve teeth
        d = d2 + 3.0*(1.0 - sqrt( 1.0 - 0.025*pt.x*pt.x ));
        
        float isTeeth = insideMouth * SSTEP(d, pt.y, 0.15);
        vec3 teethColor = vec3(0.9, 0.85, 0.8);
        col = mix(col, teethColor, isTeeth);
     
        // tongue
        pt = (15.0 + 0.5*vt2)*(mouthPos - vec2(0.0, -0.125));
        d = -pt.x * sqrt( 1.5 - 2.0*pt.x*pt.x );
        float isTongue = insideMouth * SSTEP(pt.y, d, 0.05);
        vec3 tongueColor = vec3(0.95, 0.4, 0.5);
        col = mix(col, tongueColor, isTongue);
    }
    
    // doodly noodle
    {
        vec2 doodleCenter = 1.0*(uv - vec2(0.5, 0.2));

        vec2 pt = 20.0*doodleCenter;
        float ds = 9.50 * sin(pt.x) / pt.x;

        // inside
        float ds_top = inCircle(doodleCenter, 0.28);
        float ds_btm = 1.0 + pt.y - ds;
        ds = min(smoothstep( 0.0, 0.15, ds_btm), ds_top);
        col = mix( col, bgColor, ds);

        // contour
        ds_top -= inCircle(doodleCenter, 0.2788);
        ds_btm = smoothstep(0.0, 0.05, ds_btm) - smoothstep(0.05, 0.25, ds_btm);

        ds *= ds_btm + ds_top;
        col = mix( col, 0.15 * bgColor, ds);
    }   
    
    // Truffle
    vec3 truffleColor = vec3(0.2, 0.2, 0.15);
    vec2 trufflePos = uv - vec2(0.5, eyeLevel - 1.5*backEyeRadius);
    float truffleRadius = pow(abs(1.2*trufflePos.y), abs(14.0*trufflePos.y*trufflePos.y)) * 0.08;
    col = mix(col, truffleColor, inCircle( trufflePos, truffleRadius ));

    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
