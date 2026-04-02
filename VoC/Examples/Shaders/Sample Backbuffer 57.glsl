#version 420

// original https://www.shadertoy.com/view/tdscz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uvb = uv;
    float time = time+70.;
    vec3 bak = texture(backbuffer,uv).rgb;
    uv += vec2(sin(time*0.011),cos(time*0.011))*0.03;
    uv *= sin(time*0.01+ sin((sin(uv.x*5.-time*0.01) + sin(uv.y*4.+time*0.01)) )*0.1);
    uv += vec2(sin(time*0.013),cos(time*0.013))*0.1;
    uv *= sin(time*0.008);
    uv += bak.rg*0.15*sin(uv*8.+time*0.01);
    //uv.x += time*0.001;
    uv += uv.yx*0.015*sin(uv*8.+time*0.008);
    uv = uv+sin(uv*50.+time*0.05)*0.01;
    vec3 col = vec3(0.);
    col += sin(uv.x*10.+time*0.01);
    col += cos(uv.y*5.+time*0.02);
    col = vec3(sin(col.r*3.+time*0.02),cos(col.b*2.+time*0.05),sin(col.g-time*0.01));
    col = sin((uv.x+uv.y)*3.+time*0.005)*col*0.2;
    col = sin(uv.x*300.+col*20.);
    col *= uv.y;
    col += sin(uv.x*100.+time*0.3)+1.;
    col += sin(uv.y*4.+time*0.1);
    uv.y += sin(uv.x*20.+time*0.04)*0.1+sin(uv.x*70.)*0.1;
    col = sin(col*0.9)*sin(uv.y*8.);
    col = sin(col)*0.5+0.5;
    float bw = (col.r+col.b+col.g)/3.;
    
    col = mix(col,vec3(sin(bw*2.5+time*0.01),sin(bw*3.+time*0.02),sin(bw*0.1+time*0.008)),sin(time*0.01)*0.5+0.9);
    
    col += sin(uvb.y*9.+time*-0.1+sin(uv.y*40.1*sin(uv.x-time*0.01)))*sin(uv.y+time*0.05);
    uv = mix(uv,uvb,sin(((uv.x*-10.)-sin(uvb.y*20.)*0.5+0.5)+uv.y*9.+time*0.3));
    col *= sin((uv.x*2.+uv.y)*120.)*0.1+1.;
    col *= 0.5;
    col = mix(col,bak,0.985);
    //col += clamp(sin(uv.x*uv.y*0.1+3.4),1.,0.1);
    //col = mod(col,3.);
    //col /= sin(sin(uv.y+time*0.001+col*0.05)*200.+time*0.1);
    float tt = time*10.;
    vec2 ux = uvb;
    ux *= 10.01;
    //ux = mix(ux,uv*0.01,0.2);
    vec3 pal = vec3(sin(ux.x+tt*0.025)*0.5+0.5,sin(ux.x+tt*0.02)*0.5+0.5,sin(ux.x+tt*0.04)*0.5+0.5);
    uv += vec2(sin(time*0.02),cos(time*0.02))*0.01;
    bak = texture(backbuffer,mix(uv.xy,ux*0.1,0.4)).rgb;
    //col = pal;
    col = mix(col,pal,0.005);
    col = mix(col,bak,0.01);
    glFragColor = vec4(col,0.);
}
