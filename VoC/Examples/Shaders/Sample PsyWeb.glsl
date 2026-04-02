#version 420

// original https://www.shadertoy.com/view/3dBXWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415
#define ss(a,b,c) smoothstep(a,b,c)

const float period = 5.;

vec2 rotate(vec2 p, vec2 piv, float angle)
{
    p -= piv;
    return vec2(p.x*cos(angle)-p.y*sin(angle) + piv.x,
                p.y*cos(angle)+p.x*sin(angle) + piv.y);
}

// Returns value in [0,1] 
// mode changes how value changes
float window( int mode, float t)
{
    // 0 is linear

    if(mode == 1) // fast end maintain 1
        t *= t;
    else if(mode == 2)// fast start maintain 1
        t = 1. - (1. - t)*(1. - t);
    else if(mode == 3) // cos smooth rise and fall
        t = .5 + .5*cos( -PI + 2.*PI*t);
    else if(mode == 4) // constant with smooth edges
    {
        t = .5 + .5*cos( -PI + 2.*PI*t);
        t = clamp(t*10.,0.,1.);
    }
    return t;
    
}

void main(void)
{
    // Time controls
    float t0 = window( 3, mod(time, 5.)/5.);
    float t1 = window( 3, mod(time, 10.)/10.);
    float t2 = window( 0, mod(time, 2.)/2.);
    float t3 = window( 3, mod(time, 1.)/1.);
    float t4 = window( 2, clamp(mod(time,6.) - .7, 0.,5.)/5.);
    float t5 = window( 2, clamp(mod(time,3.) - 1.5, 0.,1.8)/1.8);

    
    // Normalized pixel coordinates (from 0 to 1)
//    float r = resolution.x/resolution.y;
    vec2 uv = (gl_FragCoord.xy -.5* resolution.xy ) /resolution.y;
    
    vec2 wc = vec2(.4,-0.2); // web center
    // move web center
    uv += wc;
    
    
    float wavy = .1*sin(30.*length(uv));
    float spiralCW = length(uv);
    uv = rotate(uv, vec2(0), time*.4
                
                + t0*wavy
                + t1*spiralCW
               ); 
    
    vec2 pol = vec2(length(uv), (atan(uv.y,uv.x))/(2.*PI) + .5 );
    
    // angular repetition
    vec2 polOld = pol;
    // angle window
    float aw = .0588;
    pol.y = mod(pol.y, aw);
    
    
    // radial strip
    float t6 = window(4, clamp(mod(time, 10.)/5. - 1.,0.,1.));
    float d = .003 + t6*.025 + .0005/pol.x;
    float p = .5;
    float strip = smoothstep(d, d*p - .001, pol.y) 
                + smoothstep(aw - d, aw - d*p, pol.y);
    
    float web = strip;

    // arcs curvature
    float modul = (pol.y - 0.*t1*.1*sin(polOld.y*21.2)) * (pol.y - .065) * (.2/(pol.x));
    float pulse = 1. - smoothstep(.05, .3 ,abs(pol.x - mix(0.,2.,(t4 + t5)*2.5 - 2.  )));
    
    
    float rpwindow = window( 3, clamp(mod(time,10.), 0.,5.)/5.);
    //radial period
    float rp = window(2, pol.x*.6)*.9;
    
    // pulse distortion
    float pd = .1 + .5*window( 0, mod(time, 10.)/10.);
    
    // arc thickness 
    float t = 300.*pow(pol.y/aw -.5, 10.4);
    float arcs = smoothstep(.99 - t6*.9 - t,
                            .998 - t,
                            sin(
                                (rp + pulse*pd - pol.x*modul*140.)
                               *(60.+ floor(polOld.y/aw)*2.)
                                
                                + time*10.
                            )
                           );
    float wa = max(web, arcs);

    vec3 col = mix(
                    vec3( window(3, pol.y/aw) *2.*(.5+.5*sin(pol.x*40.*polOld.y) + t1) )*t1*.2,
                    mix(
                        mix(
                        vec3(pol.y+.9, pol.x + 4.*pulse, t1)*.8,
                        vec3(pol.x*3. + pulse, pol.y*2., t3),
                        arcs - web),
                        vec3(1),
                        1.-t1*1.-t1),
                    wa);
//  vec3 col = vec3(web);

    glFragColor = vec4(col,1.);
    //glFragColor = vec4(web);
}
