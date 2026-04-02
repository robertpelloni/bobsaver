#version 420

// original https://www.shadertoy.com/view/tsdyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* Created by bal-khan
*/

vec3 h;
float ie;

// rotation function
void rot(inout vec2 p, float a) {p = vec2(cos(a)*p.x+sin(a)*p.y, -sin(a)*p.x+cos(a)*p.y);}

// capsule distance
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdc( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// skeleton parts
vec3 _head   = vec3(.0, 1.75, -1.),
     _torso  = vec3(.0,1.0,-1.5),
     _laharm = vec3(+.850,1.0,-1.5),
     _raharm = vec3(-.850,1.0,-1.5),
     _lharm  = vec3(+1.08750,.375,-2.),
     _rharm  = vec3(-1.08750,.375,-2.),
     _lfharm = vec3(+1.0,+.10, -1.1),
     _rfharm = vec3(-1.0,+.10,-1.1),
     _pelvis = vec3(+0.0,-.0,-2.5),
     _laleg  = vec3(+0.25,-0.15,-2.5),
     _raleg  = vec3(-0.25,-0.15,-2.5),
     _lleg   = vec3(+.250,-1.0,-2.5),
     _rleg   = vec3(-.250,-1.0,-2.5),
     _lfoot  = vec3(+.250,-2.0,-2.5),
     _rfoot  = vec3(-.250,-2.0,-2.5);

// displace parts and then draw capsules beetween them
float    body(vec3 p)
{
    float r = 1e5;
    
    r = length(p-_head)-.5;
    r = min(r,
              sdc(p, _head, _torso, .25)
              );
    vec3 a_laharm = _laharm+1.0*vec3(.0,.0, .25*cos(time*4.+1.57)*+.0);
    vec3 a_lharm = _lharm+vec3(.0,.0+-.25+.25*cos(time*4.),.0+.25+.25*sin(time*4.) );
    vec3 a_lfharm = _lfharm+vec3(.0,.0+.0+.125*cos(time*4.+1.57), +.25+.25*sin(time*4.)+.0)*1.0;
    
    vec3 a_raharm = _raharm+1.0*vec3(.0,.0, .25*cos(time*4.+1.57+1.57)*+.0);
    vec3 a_rharm = _rharm+vec3(.0,.0+-.25+.25*cos(time*4.+1.57),.0+.25+.25*sin(time*4.+1.57) );
    vec3 a_rlharm = _rfharm+vec3(.0,.0+.0+.125*cos(time*4.+1.57+1.57), +.25+.25*sin(time*4.+1.57)+.0)*1.0;

    r = min(r,
              sdc(p, _torso, a_laharm, .25)
              );
    r = min(r,
              sdc(p, _torso, a_raharm, .25)
              );
    r = min(r,
              sdc(p, a_lharm, a_laharm, .25)
              );
    r = min(r,
              sdc(p, a_rharm, a_raharm, .25)
              );
    r = min(r,
              sdc(p, a_lharm, a_lfharm, .25)
              );
    r = min(r,
              sdc(p, a_rharm, a_rlharm, .25)
              );
    r = min(r,
              sdc(p, _torso, _pelvis, .25)
              );
    vec3 a_rleg = _rleg+vec3(.0,.0, .75*cos(time*5.)+.5);
    vec3 a_lleg = _lleg+vec3(.0,.0, .75*sin(time*5.)+.5);
    vec3 a_lfoot = _lfoot+vec3(.0,.0, 1.*sin(time*5.+.0)-.5);
    vec3 a_rfoot = _rfoot+vec3(.0,.0, 1.*cos(time*5.+.0)-.5);
    r = min(r,
              sdc(p, _raleg, a_rleg, .25)
              );
    r = min(r,
              sdc(p, a_rleg, a_rfoot, .25)
              );
    r = min(r,
              sdc(p, _laleg, a_lleg, .25)
              );
    r = min(r,
              sdc(p, a_lleg, a_lfoot, .25)
              );
    
    
    return r;
}

float map(vec3 p)
{
    float r, rr, rrr, bod; // r is return value, other floats are intermediary distances

    vec3 pp = p; // old p
    p.zyx = (fract(p.zyx*.025)-.5)*20.; // repeat space
    vec3 idp = floor(((pp.zyx*.025)-.0)*1.)*200.; // get id of each cell

    // use ids to rotate differently in each cell space
    rot(p.yx,  ie*sin(idp.z+time*-.5)*.3333);
    p += vec3(-3., 4., -2.0)*.3333; // add some vector, don't forget to not displace over cell boundary
    rot(p.zx,  ie*sin(idp.y+time*.25)*1.25 +1.57);
    p += -vec3(3., 2., -2.0)*.3333;
    rot(p.yz,  ie*sin(idp.x-time*2./3.)*1.333 +1.57*2.);
    p += vec3(3., 2., -2.0)*.3333;
    pp.y=p.y; // store repeated space y value in ppp.y var
    float idb = step(pp.y, .0); // if y > 0 then 1 else 0, I use this to color bottom/top sphere differently
    p.y = abs(p.y)-2.1; // create symmetry on y axis of the repeated space
    rr = length(vec3(p.x, pp.y, p.z))-5.5; // create a ball
    
    rr = max(rr
             ,
            pp.y+1.5 // cut the ball and keep the top part
            );

    rr = max(rr
             ,
            -(max(abs(p.x), max(abs(pp.y+2.2), abs(p.z+1.) ) )-2.25) // dig a cube into the ball
            );
    
    rr = abs(rr)+.0751; // make the ball transparent
    
    bod = body(p); // create bodies
    r = bod;
    r = min(r, rr);

    // Create the bottom sphere part
    rrr = max( -(pp.y) + sin(length(p.xz+vec2(.0,2.1))*5.+time*10.)*.25 // cut with waves centered on foot
              ,
              length(vec3(p.x, pp.y, p.z) )-5.3 // ball distance
             );
    rrr = abs(rrr)+.10751; // make it transparent
    r = min(r, rrr);
    
    float ball = length(vec3(p.x, abs(pp.y)-2., p.z+.25))-.25; // this is the ball between hands
    ball = abs(ball)+.01251; // make it transparent
    r = min(r, ball);
    
    // here is coloring
    // ids of repeated space are also used for coloring
    
    // wavy sphere color
    h += (vec3(.09, .475, .607) )/max(.05, rrr*rrr*3. );
    // cubicle sphere color
    h += (1.-vec3(.3+-.205*(mod(idp.x-1.5, 3.)+0.0), .425+-.06125*(mod(idp.y-1.5, 3.)+0.0), .3+idb*.25+-.125*(mod(idp.z-1.5, 3.)+0.0)))/max(.05, rr*rr*3. + .61*.0);
    // body color
    h += (1.-vec3(.32681-idb*.25, .25+-.5*idb, .3))/max(.05, bod*bod*400. + .01);
    // little hand spheres color
    h += (vec3(.25, .25+.2*idb, .25))/max(.01, ball*ball*.051+.01);
    return r;
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 f ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 o = glFragColor;

    ie = clamp(log(time*.125+1.),.0,1.); // start at 0 and progress to 1, used to animate rotations

    h = vec3(.0); // final color
    vec2 R = resolution.xy, uv = (gl_FragCoord.xy-R*.5)/R.y;

    // classic ray stuff
    vec3 ro = vec3( 20.*(1.0+sin(time*.5)), 20.*(1.+cos(time*.5)), -10.+time*30.0 );
    vec3 rd = normalize(vec3(uv, 1.));
    vec3 p;
    vec2 d = vec2(1e2, .0);

    for (float i = .0; i< 100.; i++)
    {
        p = ro + rd * d.y;
        d.x = map(p);
        d.y += d.x;
        if ( d.x < .0001 )
            break;
    }
    o.xyz = h*.0025;
    o.w = 1.0;
    o /= length(uv)+1.9; // Strong vignette counteract overall very bright scene

    glFragColor = o;
}
