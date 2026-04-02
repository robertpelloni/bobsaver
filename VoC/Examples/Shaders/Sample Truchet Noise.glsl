#version 420

// original https://www.shadertoy.com/view/tlGGRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//a rainbow colormap from Matlab
float interpolate(float val, float y0, float x0, float y1, float x1) 
{
    return (val-x0)*(y1-y0)/(x1-x0) + y0;
}

float base(float val) 
{
    if ( val <= -0.75 ) return 0.0;
    else if ( val <= -0.25 ) return interpolate( val, 0.0, -0.75, 1.0, -0.25 );
    else if ( val <= 0.25 ) return 1.0;
    else if ( val <= 0.75 ) return interpolate( val, 1.0, 0.25, 0.0, 0.75 );
    else return 0.0;
}

vec3 jet_colormap(float v)
{
    return vec3(base(v - 0.5),base(v),base(v + 0.5));
}

vec3 jet_range(float v, float a, float b)
{
    return jet_colormap(2.*clamp((v-a)/(b-a),0.,1.) - 1.);
}

float hash(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec3 truchet(vec2 p)
{
    float rnd = hash(floor(p.x) + floor(p.y)*1.55463);
    bool cond = (rnd>0.5)?(mod(p.x,1.)+mod(p.y,1.)>1.):(mod(p.x,1.)+mod(p.y,1.)<1.);
    return cond?jet_colormap(0.8*sin(5.*((1.-rnd)*p.x+rnd*p.y))):vec3(1.);
}

vec3 truchet_noise(vec2 p)
{
    float scale =1.;
    float amp = 1.;
    float norm = 0.;
    vec3 col = vec3(0);
    for(int i = 0; i < 5; i++)
    {
        vec3 trc = truchet(scale*p+2.*pow(scale,0.3)*vec2(sin(time),cos(time)));
        col += amp*trc;
        norm += amp;
        if(length(trc) > 1.5) break; //if white
        scale*= 1.7;
        amp*=0.55;
    }
    return col/norm;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.x;

    // Output to screen
    glFragColor = vec4(1.05*truchet_noise(10.*uv),1.0);
}
