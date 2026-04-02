#version 420

// original https://www.shadertoy.com/view/4ssfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Can't remenber who I taken this from 
float hex(vec2 p) {
    float dx = abs(p.x*2.);
    float dy = abs(p.y*2.);
    return max(dx+dy*.57, max(dx, dy*1.15));
}

#define H0(uv) (step(hex(uv), 5.) )
#define H1(uv) (step(hex(uv), 4.) )
#define H2(uv) (step(hex(uv), 3.) )
#define H3(uv) (step(hex(uv), 2.) )
#define H4(uv) (step(hex(uv), 1.) )

void main(void)
{
    float    t = time;
    t = mod(t, 11.75);
    vec2 R = resolution.xy,
          uv  = vec2(gl_FragCoord.xy-R/2.) / R.y;
    vec2 U;

    uv.x += step(0., t-1.65)*step(t, 3.75)*(t*.1-1.66*.1);
    if (t > 3.75)
        uv.x += ((3.75-1.65)*.1);

    uv.y += step(0., t-3.75)*step(t, 5.75)*step(mod((uv.x+.5)*5., 1.), .5) * (-(t*.1-3.75*.1));
    if (t > 5.75)
        uv.y -= (5.75-3.75)*.1;

    uv.x += step(0., t-5.75)*step(t, 7.75)*step(mod((uv.y+.5)*5., 1.), .5) * (-(t*.1-5.75*.1));
    if (t >= 7.75)
        uv.x -= step(mod((uv.y+.5)*5., 1.), .5)*(7.75-5.75)*.1;

    uv.y -= step(0., t-7.75)*step(t, 9.75)*step(mod((uv.x)*5., 1.), .5)*(-(t*.1-7.75*.1));
    if (t > 9.75)
        uv.y -= step(mod((uv.x)*5., 1.), .5)*(9.75-7.75)*.1;

    uv.x -= step(0., t-9.75)*step(t, 11.75)*step(mod(uv.y*5., 1.), .5 )*((t*.1-9.75*.1));
    if (t >= 11.75)
        uv.x -= step(mod(uv.y*5., 1.), .5 )*(11.75-9.75)*.1;
    
    U = (uv-.5)*5.;

    uv = fract((uv-.5)*5.)-.5;
    vec2 to = +floor((U)*90.)/9.;
    U = uv.xy;
    U.yx *= mat2(
                +sin(t*step(t, 1.66)),
                +cos(t*step(t, 1.66)),
                -cos(t*step(t, 1.66)),
                +sin(t*step(t, 1.66))
    );

    U.yx *= mat2(
                -sin(t*step(t, 1.66)),
                -cos(t*step(t, 1.66)),
                +cos(t*step(t, 1.66)),
                -sin(t*step(t, 1.66))
    );
    
    uv.yx *= mat2(
                +sin(t*step(t, 1.66)),
                +cos(t*step(t, 1.66)),
                -cos(t*step(t, 1.66)),
                +sin(t*step(t, 1.66))
    );

    uv.yx *= mat2(
                -sin(t*step(t, 1.66)),
                -cos(t*step(t, 1.66)),
                +cos(t*step(t, 1.66)),
                -sin(t*step(t, 1.66))
    );
    U+=to;
        vec3    col = vec3(
        abs(sin(+ceil(fract(U.y) )*.25*ceil(U.x)*.25+0.00)),
        abs(sin(+ceil(fract(U.y) )*.25*ceil(U.x)*.25+1.04)),
        abs(sin(+ceil(fract(U.y) )*.25*ceil(U.x)*.25+2.08))
                        );

    vec4 o;
    o.x = H0(uv*5.);
    o.x -= H1(uv*5.);
    o.x += H2(uv*5.);
    o.x -= H3(uv*5.);
    o.x += H4(uv*5.);
    o.xyz = o.x * col;
    glFragColor=o;
}
