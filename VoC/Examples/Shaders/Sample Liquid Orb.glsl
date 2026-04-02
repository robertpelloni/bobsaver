#version 420

// original https://www.shadertoy.com/view/ws3Gz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// from: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float rand(float n){return fract(sin(n) * 43758.5453123);}
float noise1D(float p){
    float fl = floor(p);
    float fc = fract(p);
    return (mix(rand(fl), rand(fl + 1.0), fc)-.5)*2.;
}

// from: https://github.com/BrianSharpe/Wombat/blob/master/Perlin3D.glsl
float perlin( vec3 P )
{
    // establish our grid cell and unit position
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 Pf_min1 = Pf - 1.0;

    // clamp the domain
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    // calculate the hash
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
    const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );
    vec3 lowz_mod = vec3( 1.0 / ( SOMELARGEFLOATS + Pi.zzz * ZINC ) );
    vec3 highz_mod = vec3( 1.0 / ( SOMELARGEFLOATS + Pi_inc1.zzz * ZINC ) );
    vec4 hashx0 = fract( Pt * lowz_mod.xxxx );
    vec4 hashx1 = fract( Pt * highz_mod.xxxx );
    vec4 hashy0 = fract( Pt * lowz_mod.yyyy );
    vec4 hashy1 = fract( Pt * highz_mod.yyyy );
    vec4 hashz0 = fract( Pt * lowz_mod.zzzz );
    vec4 hashz1 = fract( Pt * highz_mod.zzzz );

    // calculate the gradients
    vec4 grad_x0 = hashx0 - 0.49999;
    vec4 grad_y0 = hashy0 - 0.49999;
    vec4 grad_z0 = hashz0 - 0.49999;
    vec4 grad_x1 = hashx1 - 0.49999;
    vec4 grad_y1 = hashy1 - 0.49999;
    vec4 grad_z1 = hashz1 - 0.49999;
    vec4 grad_results_0 = inversesqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
    vec4 grad_results_1 = inversesqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );

    // Classic Perlin Interpolation
    vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
    vec4 blend2 = vec4( blend.xy, vec2( 1.0 - blend.xy ) );
    float final = dot( res0, blend2.zxzx * blend2.wwyy );
    return ( final * 1.1547005383792515290182975610039 );  // scale things to a strict -1.0->1.0 range  *= 1.0/sqrt(0.75)
}

float perlin(vec2 pos, float time)
{
    return (perlin(vec3(pos, time))+1.)*.5;
}

float noise(vec2 pos, float dist, float rotation, float time)
{
    time *= 1.+dist/100.;
    pos += vec2(time*rotation, 0.)*.5;
    //pos -= vec2(mouse*resolution.xy.x/resolution.x, mouse*resolution.xy.y/resolution.y);
    return perlin(pos*dist + vec2(dist), time*2.);
}

vec3 fbm(vec2 pos, float time)
{
    vec3 n = vec3(.05);

    pos += perlin(pos*.5, time)*.1;
    
    n += noise(pos, 1., .01, time)      * vec3(.25, 1., .5);
    n += noise(pos, 5., .025, time)*.85 * vec3(.75, 1., 1.);
    n += noise(pos, 10., .05, time)*.5  * vec3(.25, 1., 1.);
    n += noise(pos, 20., .1, time)*.25  * vec3(1., 0., .2);
    n += noise(pos, 75., .15, time)*.1  * vec3(1.,1., 1.);
    
    return n;
}

float circle(vec2 pos, float radius)
{
    return smoothstep(30./resolution.y, -30./resolution.y, length(pos)- radius);
}

float highlight(float circle, vec2 pos, float radius)
{
    float h = smoothstep(0., radius, length(pos));
    h -= 1.-circle;
    return h*(.4+(sin(time)+1.)*.1);
}

// from: https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
vec3 hueShift( vec3 color, float hueAdjust ){

    const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
    const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
    const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

    const vec3  kYIQToR     = vec3 (1.0, 0.956, 0.621);
    const vec3  kYIQToG     = vec3 (1.0, -0.272, -0.647);
    const vec3  kYIQToB     = vec3 (1.0, -1.107, 1.704);

    float   YPrime  = dot (color, kRGBToYPrime);
    float   I       = dot (color, kRGBToI);
    float   Q       = dot (color, kRGBToQ);
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    vec3    yIQ   = vec3 (YPrime, I, Q);

    return vec3( dot (yIQ, kYIQToR), dot (yIQ, kYIQToG), dot (yIQ, kYIQToB) );

}

void main(void)
{
    // position
    vec2 pos = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    
    // distortions
    pos.x += noise1D(time)*.05;
    pos.y += noise1D(time+10.)*.05;
    pos += perlin(pos*2., time)*.1;
    pos *= 1.1;
    
    // variables
    float radius = .9 + sin(time*4.)*.1;
    float time = time;
    
    // fisheye
    pos *= .5 + pow(length(pos), 10.);

    // forms
    vec3 noise = fbm(pos, time);
    vec3 circ = vec3(circle(pos, radius));
    vec3 hl = vec3(highlight(circ.r, pos, radius));
    
    // post processing
    vec3 res = clamp(circ - noise, vec3(0.), vec3(1.));
    res.rgb = res.bgr;
    res *= 2.;
    res += hl*vec3(1., .2, .5);
    res = hueShift(res, 5. + sin(time));
    
    // output
    glFragColor = vec4(res, 1.);
}
