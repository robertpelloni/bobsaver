#version 420

// original https://www.shadertoy.com/view/lsfBRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653589793

float bits(vec2 p){
    p = floor(p + .5);
    float res = 0.;
    for (int i = 0; i < 100; ++i) {
        if(dot(p,p)<.5)
            return res;
        res += 1.;
        p.x -= step(1., mod(p.x+p.y+.5, 2.));
        p = mat2(-.5,-.5,.5,-.5)*p;
    }
    return -1.; // this shouldn't happen
}

void main(void)
{
    const vec4 bg_col = vec4(.3,.3,.7,1.);
    const vec4 fg_col = vec4(.7,.7,.7,1.);
    const vec4 mv_col = vec4(.2,.8,.2,1.);
    const float step_t = 1.;
    const float col_t = .2;
    const float wait_t = .1;
    const float num_steps = 20.;

    float period = num_steps*step_t*4.;
    float t = mod(time, period);
    float mode = float(t>period/2.);
    t = mod(t,period/2.);
    t=min(t,period/2.-t);
    float b = floor(t/step_t);
    float bt = fract(t/step_t);
    float logscale = b+(b>num_steps-1.5 ? (1.-pow(1.-bt,2.))*.5 : b<.5 ? bt*bt*.5+.5 : bt);
    float scale = pow(2.,logscale/2.)*3.;
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5 + vec2(.12,.17)) / resolution.y * scale;

    float fg, mv;
    
    if (mode < .5) {
        vec2 offset = vec2(cos(PI*.75*b),sin(PI*.75*b))*pow(2.,b*.5);
        fg = float(bits(uv)<b+.5);
        mv = float(bits(mix(uv,uv-offset,smoothstep(col_t+wait_t,1.-col_t-wait_t,bt)))<b+.5);
    } else {
        // This block of code is bad, but I should go to sleep now.
        float tt=smoothstep(.1,.4,bt);
        mat2 ip = mat2(cos(PI*.75*tt),-sin(PI*.75*tt),sin(PI*.75*tt),cos(PI*.75*tt))*pow(2.,-tt*.5);
        vec2 uvc = mat2(.5,.5,.5,-.5)*uv;
        uvc = floor(uvc+.5);
        uvc = mat2(1.,1.,1.,-1.)*uvc;
        vec2 wi = ip*uvc;
        float tt2=1.-smoothstep(.4,.7,bt);
        if(b>10.)
            tt2=1.; // terrible aliasing otherwise
        mat2 ip2 = mat2(cos(PI*.25*tt2),-sin(PI*.25*tt2),sin(PI*.25*tt2),cos(PI*.25*tt2))*pow(2.,-tt2*.5);
        vec2 wr=(tt2==1.?ip:ip2*ip)*(uv-uvc);
        fg = float((tt2==1. || all(lessThanEqual(abs(mat2(1.,1.,1.,-1.)*wr),vec2(.5)))) && bits(wi+wr)<b+.5);
        float mvt = smoothstep(.7,.9,bt);
        float xr=uv.x+mod(floor(uv.y+.5)+.5,2.)-.5;
        xr=mod(xr,2.);
        mv = float(xr>.5 && xr<=.5+mvt && bits(uv)<b+1.5);
    }

    glFragColor =
        mix(mix(mix(bg_col,fg_col,fg),
                mv_col,
                mv*.7*smoothstep(wait_t,col_t+wait_t,bt)),
            fg_col,
            smoothstep(1.-col_t-wait_t,1.-wait_t,bt*mv));
}
