#version 420

// original https://www.shadertoy.com/view/wd2cDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define SOFT .005
#define PIXELATED 0

#define ss(a,b,c) smoothstep(a,b,c)

float circle(vec2 uv, float r, vec2 c, float softness)
{
    return ss(r+softness, r-softness, length(uv - c));
}

vec2 rot(vec2 uv, float a)
{
    vec2 i = vec2(cos(a),sin(a));
    return vec2(uv.x*i.x - uv.y*i.y, uv.y*i.x + uv.x*i.y);
}

float window(float center, float val, float width, float fall)
{
    return ss(width + fall, width, length(center - val));
}

// map square coordinates of center c, radial range and angular range.
// map to [-.5, 5]
vec2 mapCrown(vec2 uv, vec2 c, vec2 radLim)
{
    float radius = (radLim.x + radLim.y)/2.;
    float radrange = (radLim.y - radLim.x);
    vec2 nuv = uv - c;
    vec2 puv  =  vec2(length(nuv), atan(nuv.y, nuv.x) );
    
    uv = vec2((puv.x - radLim.x)/radrange - .5,
              puv.y/PI);
    
    return uv;
}

// generate a yinyang (yy) on .x and a round mask on .y
// fits in [-.5, .5] when scale 1.
vec2 yinyang(vec2 uv, float softness, float scale)
{
    
    float r = .25*scale;
    float whole = max(
                        // upper ball
                        circle(uv, r, vec2(0., r), softness),
                          (uv.x > 0.)?0.:1.-circle(uv, r,vec2(0., -r), softness)
        
                     );
    whole +=  circle(uv, .06125*scale , vec2(0.,-r), softness);
    whole -=  circle(uv, .06125*scale , vec2(0.,r), softness);
    float br = .5*scale ;
    float mask = ss(br+softness, br-softness, length(uv));
    whole = mix(.0, whole, ss(br+softness, br-softness, length(uv)));
    
    return vec2(whole, mask);
    
}

// generates big yy with a curve string of small yys on its edge
vec2 chaos(vec2 uv, float softness, float scale, float scaleDiv)
{
    vec2 yy = vec2(0.);
    
    
    // first YY
    yy += yinyang(uv, softness, scale);
    
    // uv for mapping small YY's in the big YY edge
    vec2 nuv = rot(uv, PI/2.) - vec2(-0.25*scale, .0);
    vec2 nuv2 = rot(uv, PI/2.) - vec2(0.25*scale, .0);
        
    // crown thickness
    float thick = .5/scaleDiv;
    
    vec2 rads = scale*vec2(.25 - thick, .25 + thick);
    
    // morph UV to form an S shape on YY edge
    uv = mix(mapCrown(nuv,  vec2(.0), rads.xy),
             mapCrown(rot(nuv2,PI), vec2(.0), rads.yx) * vec2(1., -1.),
             ss( 0.01, .0, sign(uv.x)) );
    
    // angle of section in crown 
    // Calculated trying to aproximate section to a square
    // r2 - r1 = angle*(r2 + r1)/2
    float angle = 2.*(rads.y-rads.x)/(rads.y+rads.x);
    
    // repetition of angular coord
    uv.y = fract(uv.y*floor(PI/angle)) - .5;
    
    // string phase shift 
    uv.y = (uv.y >= 0.)?uv.y-.5:uv.y+.5;
    
    // scale param is 1. cause uv has been scaled here already 
    vec2 yyString = yinyang(uv, softness, 1.);
    yy = mix(yy, yyString,  yyString.y);
    
    
    // fill space out of YY
    yy.x = (yy.y > 0.)?yy.x: (uv.x < 0.)?1.:0.;
    
    return yy;
}

// super pose 1 chaos small YYs with the big YY of another chaos
vec2 connectYYs(vec2 uv, float softness, float startScale, float scaleDiv)
{
    float endScale = startScale/scaleDiv;
    vec2 yy = chaos(uv, softness, startScale, scaleDiv);
    
    //TODO: Make extra YYs follow edge curvature
    // extra YYs
    vec2 yy1 = chaos(uv+vec2(.0,  startScale *1.004), softness, startScale, scaleDiv);
    vec2 yy2 = chaos(uv+vec2(.0, -startScale *1.004), softness, startScale, scaleDiv);
    yy = mix(yy, yy1, yy1.y);
    yy = mix(yy, yy2, yy2.y);
    

    vec2 nuv = rot(uv, PI/2.);
    vec2 newYY = chaos(nuv, softness, endScale, scaleDiv);
    
    // extra strings
    vec2 newYY1 = chaos(nuv+vec2(0., endScale), softness, endScale, scaleDiv);
    vec2 newYY2 = chaos(nuv+vec2(0., -endScale), softness, endScale, scaleDiv);
    newYY = mix(newYY, newYY1, newYY1.y);
    newYY = mix(newYY, newYY2, newYY2.y);
    
    yy = mix(yy, newYY, newYY.y);
    
    return yy;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    
    #if (PIXELATED == 1)
    float f = 40.;
    uv = floor(uv*f)/f;
    #endif
    
    // rotate everything
    //uv = rot(uv,mix( 0., time, ss(1., 10., time)) );
    
    vec2 muv = mouse*resolution.xy.xy/resolution.xy;
    
    float period = 8.;
    float startScale = 4000.;
    float scaleDiv = 150.;
    
    float tt;
    float t;
    float t1;
    float t2;
    float t3;
    
    // total time [0,1]
    tt = fract(time/period);
    //tt = mix(0.,tt,ss( 0., 3., time));
    //tt = muv.x;
    //tt = gl_FragCoord.xy.x/resolution.x;
    
    #define SECTION_W 1.
    #define DD 3.
    tt *= 4.;
    
    // section time, the .9 mult is a workaround to make zoom more seamless
    t  = .9*(clamp( tt, 0.*SECTION_W, 1.*SECTION_W) - 0.*SECTION_W)/SECTION_W;
    t1 = .9*(clamp( tt, 1.*SECTION_W, 2.*SECTION_W) - 1.*SECTION_W)/SECTION_W;
    t2 = .9*(clamp( tt, 2.*SECTION_W, 3.*SECTION_W) - 2.*SECTION_W)/SECTION_W;
    t3 = .9*(clamp( tt, 3.*SECTION_W, 4.*SECTION_W) - 3.*SECTION_W)/SECTION_W;
       
    // Came to this experimenting trying to make zoom more linear
    t  = sqrt(1. - (1.-t )*(1.-t ));
    t1 = sqrt(1. - (1.-t1)*(1.-t1));
    t2 = sqrt(1. - (1.-t2)*(1.-t2));
    t3 = sqrt(1. - (1.-t3)*(1.-t3));
    
    // the .2* is a workaround to make zoom more seamless
    vec2 uv0 = uv*mix(startScale, .2*startScale/scaleDiv, t );
    vec2 uv1 = uv*mix(startScale, .2*startScale/scaleDiv, t1);
    vec2 uv2 = uv*mix(startScale, .2*startScale/scaleDiv, t2);
    vec2 uv3 = uv*mix(startScale, .2*startScale/scaleDiv, t3);
    
    vec2 yy = vec2(0.);
    vec2 newYY;
    
    float crossfade = .0001;
    float softness = .0001;
    
    vec2 yy0 = connectYYs(uv0, softness, startScale, scaleDiv)*window(1.*SECTION_W/2., tt, SECTION_W/2., crossfade);

    uv1 = rot(uv1, PI/2.);
    vec2 yy1 = connectYYs(uv1, softness, startScale, scaleDiv)*window(3.*SECTION_W/2., tt, SECTION_W/2., crossfade);
    
    uv2 = rot(uv2, PI);
    vec2 yy2 = connectYYs(uv2, softness, startScale, scaleDiv)*window(5.*SECTION_W/2., tt, SECTION_W/2., crossfade);

    uv3 = rot(uv3, 3.*PI/2.);
    vec2 yy3 = connectYYs(uv3, softness, startScale, scaleDiv)*window(7.*SECTION_W/2., tt, SECTION_W/2., crossfade);
    
    
    // Stitching the 4 parts to make it a loop
    yy = yy0 + yy1 + yy2 + yy3;
    
    // delineate yy
    if(time < period/4.)
        yy *= yy.y;
    
    glFragColor = vec4(yy.x);
    
}
