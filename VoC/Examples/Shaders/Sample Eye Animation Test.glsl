#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4dKcRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    An attempt to mimic the animation of Link's expressions in Wind Waker.
    The whole thing is reasonably simple, but this code is an absolute mess.
    It's mostly just a few keyframes (drawn via bezier curves and intersecting parabolas mostly),
        basic lerp'd stuff.

    As per usual, you're free to use this work in whatever you want, but I'd appreciate if
        you credited me (my Shadertoy name and a link to this work is fine).
**/

/** TODO: 
    Maybe add in more eyebrow shapes so we can actually tween
    Antialiasing would probably be nice
    Add in the original colour gradient
    Extra, non-blink related, eyelid shapes    
**/

// Shape map:
// 0: standard eye
// 1-3: blink stages

float blinkStageDuration = 1./7.;
float blinkDuration = .45;
vec2 lPupilCenter = vec2(.23, .19);
vec2 lEyeSize = vec2(0.09, 0.105);

float rEyeOffset = 0.53;
vec2 rPupilCenter = vec2(.76, .19);
vec2 rEyeSize = vec2(0.09, 0.105);

vec3 focusPoint;
float pupilDilation = 1.0;
vec3 skinColour = vec3(247.0, 219.0, 156.0)/255.;

// Bezier drawing tech taken from https://www.shadertoy.com/view/MtS3Dy
float det(vec2 a, vec2 b) { return a.x*b.y-b.x*a.y; }
vec2 get_distance_vector(vec2 b0, vec2 b1, vec2 b2) {
  float a=det(b0,b2), b=2.0*det(b1,b0), d=2.0*det(b2,b1); // ð›¼,ð›½,ð›¿(ð‘)
  float f=b*d-a*a; // ð‘“(ð‘)
  vec2 d21=b2-b1, d10=b1-b0, d20=b2-b0;
  vec2 gf=2.0*(b*d21+d*d10+a*d20);
  gf=vec2(gf.y,-gf.x); // âˆ‡ð‘“(ð‘)
  vec2 pp=-f*gf/dot(gf,gf); // ð‘â€²
  vec2 d0p=b0-pp; // ð‘â€² to origin
  float ap=det(d0p,d20), bp=2.0*det(d10,d0p); // ð›¼,ð›½(ð‘â€²)
  // (note that 2*ap+bp+dp=2*a+b+d=4*area(b0,b1,b2))
  float t=clamp((ap+bp)/(2.0*a+b+d), 0.0, 1.0); // ð‘¡Ì…
  return mix(mix(b0,b1,t),mix(b1,b2,t),t); // ð‘£ð‘– = ð‘(ð‘¡Ì…)
}
float approx_distance(vec2 p, vec2 b0, vec2 b1, vec2 b2) {
  return length(get_distance_vector(b0-p, b1-p, b2-p));
}

bool paintIrises( in vec2 uv)
{
    vec2 tempUV = uv;
    if (tempUV.x > 0.5) tempUV.x -= rEyeOffset;
    float toSquare = tempUV.x * 1.8 - .42;
    if ((tempUV.y >= .9 * toSquare*toSquare + .04) &&
        (tempUV.y <= -1.0* toSquare*toSquare + .34))
    {
        return true;   
    }

     return false;  
}

bool paintPupil (in vec2 uv, in vec2 pupilCenter, in vec2 eyeSize)
{
    vec2 dist = uv - pupilCenter - focusPoint.xy;
    vec2 part = vec2(dist.x/eyeSize.x / pupilDilation, dist.y/eyeSize.y / pupilDilation); // (x/a, y/b)
    float equation = part.x * part.x + part.y * part.y;
    if(equation < 1.0){ 
        return true;
    }
    
    return false;
}

bool restrictPupil (in vec2 uv, in int shape1, in int shape2, in float tween){
    vec2 tempUV = uv;
    if (tempUV.x > 0.5) tempUV.x -= rEyeOffset;
    float toSquare = tempUV.x * 1.8 - .42;
    vec3 A,B,C,D;
    if (shape1 == 0){
        A.y = 0.9;
        B.y = 0.04;
        C.y = -1.0;
        D.y = 0.34;
    } else if (shape1 == 1){
        A.y = .7;
        B.y = 0.06;
        C.y = -0.7;
        D.y = 0.3;
    } else if (shape1 == 2){
        A.y = 0.5;
        B.y = 0.1;
        C.y = -0.4;
        D.y = 0.24;
    } else if (shape1 == 3){
        A.y = 0.3;
        B.y = 0.2;
        C.y = -0.1;
        D.y = 0.2;
    }
    
    if (shape2 == 0){
        A.z = 0.9;
        B.z = 0.04;
        C.z = -1.0;
        D.z = 0.34;
    } else if (shape2 == 1){
        A.z = 0.7;
        B.z = 0.06;
        C.z = -0.7;
        D.z = 0.3;
    } else if (shape2 == 2){
        A.z = 0.5;
        B.z = 0.1;
        C.z = -0.4;
        D.z = 0.24;
    } else if (shape2 == 3){
        A.z = 0.3;
        B.z = 0.2;
        C.z = -0.1;
        D.z = 0.2;
    }
    
    A.x = mix(A.y, A.z, tween);
    B.x = mix(B.y, B.z, tween);
    C.x = mix(C.y, C.z, tween);
    D.x = mix(D.y, D.z, tween);
    
    if ((tempUV.y <= A.x * toSquare*toSquare + B.x) ||
            (tempUV.y >= C.x * toSquare*toSquare + D.x))
    {
        return true;   
    }
    return false;
}

bool paintEyebrow (in vec2 uv, bool isRightBrow, int shape1, int shape2, float tween){
    vec2 A1, A1Start, A1End, B1, B1Start, B1End, C1, C1Start, C1End;
    vec2 A2, A2Start, A2End, B2, B2Start, B2End, C2, C2Start, C2End;
    // Map the shape of the initial eyebrow to the three points
    // defining the associated bezier curve
    if (shape1 == 0){
        A1Start = vec2(0.44, 0.35);
        B1Start = vec2(0.17, 0.52);
        C1Start = vec2(0.03, 0.41);
        
        A2Start = vec2(0.44, 0.35);
        B2Start = vec2(0.14, 0.61);
        C2Start = vec2(0.03, 0.41);
    }
    
    if (shape2 == 0){
        A1End = vec2(0.44, 0.35);
        B1End = vec2(0.17, 0.52);
        C1End = vec2(0.03, 0.41);
        
        A2End = vec2(0.44, 0.35);
        B2End = vec2(0.14, 0.61);
        C2End = vec2(0.03, 0.41);
    }
    
    if (isRightBrow){
        A1Start.x = 1. - A1Start.x;
        B1Start.x = 1. - B1Start.x;
        C1Start.x = 1. - C1Start.x;
        A2Start.x = 1. - A2Start.x;
        B2Start.x = 1. - B2Start.x;
        C2Start.x = 1. - C2Start.x;
        
        A1End.x = 1. - A1End.x;
        B1End.x = 1. - B1End.x;
        C1End.x = 1. - C1End.x;
        A2End.x = 1. - A2End.x;
        B2End.x = 1. - B2End.x;
        C2End.x = 1. - C2End.x;
    }
    
    // Lerp between the expression we started in and the one we're going to
    A1 = mix(A1Start, A1End, tween);
    B1 = mix(B1Start, B1End, tween);
    C1 = mix(C1Start, C1End, tween);
    float d = approx_distance(uv, A1, B1, C1);
    if (d < 0.0215)
    {
        return true;
    }
    
     // Lerp between the expression we started in and the one we're going to
    A2 = mix(A2Start, A2End, tween);
    B2 = mix(B2Start, B2End, tween);
    C2 = mix(C2Start, C2End, tween);
    d = approx_distance(uv, A2, B2, C2);
    if (d < 0.0255)
    {
        return true;
    }
    
    return false;
}

bool paintEyelids (in vec2 uv, bool isRightLid, int shape1, int shape2, float tween){
    
    vec2 A1, A1Start, A1End, B1, B1Start, B1End, C1, C1Start, C1End;
    // Map the shape of the initial eye to the three points
    // defining the associated bezier curve
    if (shape1 == 0){
        A1Start = vec2(0.01, 0.19);
        B1Start = vec2(0.26, 0.5);
        C1Start = vec2(0.47, 0.15);
    } else if (shape1 == 1){
           A1Start = vec2(0.01, 0.19);
        B1Start = vec2(0.3,  0.44);
        C1Start = vec2(0.47, 0.15);   
    } else if (shape1 == 2){
           A1Start = vec2(0.01, 0.19);
        B1Start = vec2(0.30, 0.32);
        C1Start = vec2(0.47, 0.15);   
    } else if (shape1 == 3){
           A1Start = vec2(0.01, 0.19);
        B1Start = vec2(0.30, 0.23);
        C1Start = vec2(0.47, 0.17);   
    }
    
    if (shape2 == 0){
        A1End = vec2(0.01, 0.19);
        B1End = vec2(0.26, 0.5);
        C1End = vec2(0.47, 0.15);
    } else if (shape2 == 1){
           A1End = vec2(0.01, 0.19);
        B1End = vec2(0.3,  0.44);
        C1End = vec2(0.47, 0.15);   
    } else if (shape2 == 2){
           A1End = vec2(0.01, 0.19);
        B1End = vec2(0.30, 0.32);
        C1End = vec2(0.47, 0.15);   
    } else if (shape2 == 3){
           A1End = vec2(0.01, 0.19);
        B1End = vec2(0.30, 0.23);
        C1End = vec2(0.47, 0.17);   
    } 
    
    if (isRightLid){
        A1Start.x = 1. - A1Start.x;
        B1Start.x = 1. - B1Start.x;
        C1Start.x = 1. - C1Start.x;
        
        A1End.x = 1. - A1End.x;
        B1End.x = 1. - B1End.x;
        C1End.x = 1. - C1End.x;
    }
    
    // Lerp between the expression we started in and the one we're going to
    A1 = mix(A1Start, A1End, tween);
    B1 = mix(B1Start, B1End, tween);
    C1 = mix(C1Start, C1End, tween);
    float d = approx_distance(uv, A1, B1, C1);
        if (d < 0.007 + 0.0025)
        {
            return true;
        }
    
    return false;
}

void main(void)
{
    vec4 lEyeShapes = vec4(0);
    vec4 rEyeShapes = vec4(0);
    float lEyeTween = 0.;
    float rEyeTween = 0.;
    
    // This doesn't *really* focus the eyes, but it makes them slide around together
    // which I guess is close enough
    focusPoint = vec3(sin(time * 1.4) * .08, cos(time * 0.6) * .07, 0.);
    pupilDilation = abs(sin(time * 0.2 + 1.4)) * 0.5 + 0.7; 
    
    // Blink every 4 seconds
    if (int(floor(time)) % 4 == 0){
        rEyeTween = fract(time);
        lEyeTween = fract(time);
        if (rEyeTween <= blinkDuration){
            blinkStageDuration *= blinkDuration;
            while (rEyeTween > blinkStageDuration){
                rEyeTween -= blinkStageDuration;
            }
            rEyeTween /= blinkStageDuration;
            if (fract(time) <= blinkStageDuration)
            {
                lEyeShapes.x = 0.;
                lEyeShapes.y = 1.;
                rEyeShapes.x = 0.;
                rEyeShapes.y = 1.;
            }
            else if (fract(time) <= 2. * blinkStageDuration)
            {
                lEyeShapes.x = 1.;
                lEyeShapes.y = 2.;
                rEyeShapes.x = 1.;
                rEyeShapes.y = 2.;
            }
            else if (fract(time) <= 3. * blinkStageDuration)
            {
                lEyeShapes.x = 2.;
                lEyeShapes.y = 3.;
                rEyeShapes.x = 2.;
                rEyeShapes.y = 3.;
            }
            else if (fract(time) <= 4. * blinkStageDuration)
            {
                lEyeShapes.x = 3.;
                lEyeShapes.y = 3.;
                rEyeShapes.x = 3.;
                rEyeShapes.y = 3.;
            }
            else if (fract(time) <= 5. * blinkStageDuration)
            {
                lEyeShapes.x = 3.;
                lEyeShapes.y = 2.;
                rEyeShapes.x = 3.;
                rEyeShapes.y = 2.;
            }
            else if (fract(time) <= 6. * blinkStageDuration)
            {
                lEyeShapes.x = 2.;
                lEyeShapes.y = 1.;
                rEyeShapes.x = 2.;
                rEyeShapes.y = 1.;
            }
            else {
                lEyeShapes.x = 1.;
                lEyeShapes.y = 0.;
                rEyeShapes.x = 1.;
                rEyeShapes.y = 0.;
            }
        }
    }
    
    //lEyeShapes.xy = vec2(3., 3.);
    //rEyeShapes.xy = vec2(3., 3.);
    //rEyeTween = 0.;
    //lEyeTween = 0.;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.x;

    // Initial colour
    vec3 pixelColour = skinColour;

    // Add in the full iris shape in flat white
    if (paintIrises(uv))
    {
        pixelColour = vec3(1.0);   
    }
    
    // Add in full pupil
    // TODO: bring in the gradient from the original game
    if (paintPupil(uv, lPupilCenter, lEyeSize) ||
        paintPupil(uv, rPupilCenter, rEyeSize)){
        pixelColour = vec3(0.0);
    }
    
    // Mask the iris and pupil to create the proper shape of the eye
    if ((uv.x < 0.5 && restrictPupil(uv, int(lEyeShapes.x), int(lEyeShapes.y), lEyeTween)) ||
        (uv.x > 0.5 && restrictPupil(uv, int(rEyeShapes.x), int(rEyeShapes.y), rEyeTween)))
    {
         pixelColour = skinColour;   
    }
    
    // Paint the eyelids on
    if (paintEyelids(uv, false, int(lEyeShapes.x), int(lEyeShapes.y), lEyeTween) ||
        paintEyelids(uv, true,  int(rEyeShapes.x), int(rEyeShapes.y), rEyeTween)){
        pixelColour = vec3(0.0);
    }
    
    // TODO: Maybe actually add in extra shapes so we can tween for real sometime
    if (paintEyebrow(uv, false, int(lEyeShapes.z), int(lEyeShapes.w), 0.) ||
        paintEyebrow(uv, true, int(lEyeShapes.z), int(lEyeShapes.w), 0.)){
        pixelColour = vec3(0.0);
    }
 

    glFragColor = vec4(pixelColour, 1.0);
}
