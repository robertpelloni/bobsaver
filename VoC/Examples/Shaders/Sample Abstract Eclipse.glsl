#version 420

// original https://www.shadertoy.com/view/XlcGWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float fbm(vec2 st)
    {
    float f = noise(st)*1.;st*=2.02;
     f += noise(st)*0.5;st*=2.04;
     f += noise(st)*0.25;st*=2.03;
     f += noise(st)*0.125;st*=2.04;
     f += noise(st)*0.0625;///st*=2.01;
    
return f;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 st = uv;
    st.x*=resolution.x/resolution.y;
     vec3 color = vec3(0.0);

    vec2 pos = vec2(st*10.0);

    color = vec3( noise(pos)*.5+.5 );
    vec3 color1 = vec3(0.022,0.144,0.145);
    vec3 color2 = vec3(0.064,0.008,0.100);
    
    float sun = 1./pow(length(st-0.5), 1./2.)/4.;
    color = color1*step(0.5, st.x)*(1.0-st.x);
    color += color2*step(0.5, 1.0-st.x)*(st.x);
    
    color = mix(color1, color2, st.x-0.120);
    color = mix(color, vec3(0.765,0.723,0.661), sun-0.3);
    
    
    sun = 1.0-length(vec2(st.x/3., st.y-0.598));
    color1 = vec3(0.525,0.787,0.945);
    color2 = vec3(0.870,0.685,0.660);
    vec3 color3 = vec3(0.990,0.985,0.781);
    color = mix(color1, color2, pow(sun, 3.));//sin(st.y*6.168+-1.316)*0.5+0.5);
    //sun = 1.0-length(vec2(st.x/2., st.y-0.708));
    //color = mix(color, color3, pow(sun, 2.)/1.3);
        color+=pow(st.y, 2.)/8.;
    vec3 color4 = vec3(0.258,0.602,0.820);
    color2 = vec3(0.940,0.231,0.403);
    color2 = mix(color2, color3, st.y+0.10);
    color = mix(color4, color1, st.y)+pow(st.y, 2.)/8.;
    color =mix(color,  color2, pow(sun, 2.200)*1.);
    //color = color*2.0-0.328;
    st.x+=7.696;
    //st.y*=1.816;
    
    st.x/=2.;
    color *= mix(color, vec3(3.), fbm(st*4.+fbm(st*2.)/2.)*(noise(st*2.)));
    
    st = gl_FragCoord.xy / resolution.xy;
    st=st*2.0-1.0;
    st.x*=resolution.x/resolution.y;
    
    st/=1.2;
    
    
    color += clamp(vec3(
     1./pow(length(st+vec2(0.010,-0.0)), 2.+sin(atan(st.y,st.x)*50.+3.14159+time )/40.  )  *0.06   ), 0.0, 3.7);
    
    color -= clamp(vec3(
     1./pow(length(st+vec2(0.010,-0.0)), 2.)*0.05   ), .0, 4.0)/(1.+sin(time*1.)/10.)+vec3(0.035,0.436,0.440)+sin(time*3.)/40.;
    
    
    
    glFragColor = vec4(color, 1.0);
}
