#version 420

// original https://www.shadertoy.com/view/WsKGD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float SIZE = 2.;

vec2 foldUVs(vec2 uvs) {
    if (uvs.x < 0.) uvs *= -1.;
    uvs.x -= .5;
    //mat2 m = mat2(0,1,-1,0);
    //float ang = 6.28*mouse*resolution.xy.x/resolution.x;
    float ang = 3.141592*1./2.;
    mat2 m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    uvs *= m;
    uvs *= SIZE;
    return uvs;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv *= 1.;
    float scale = 1.;
    
    float ang = 0.;
    mat2 m = mat2(0.);
    float s = 0.;
    float t = 1.;

    uv.y -= mix(.0, -1., t);//.5;
    ang = mix(.0, -3.141592/2., t);//3.141592*1./2.;
    m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    uv *= m;
    s = mix(1., 1./SIZE, t);
    uv *= s; //SIZE;
    scale *= s;
    
    //t = mouse*resolution.xy.x / resolution.x;
    t = fract(time);
    //float t = 0.1;
    
    //uv.y -= mix(.0, -1., t);//.5;
    //float a = mix(.5, -.5, t) * 3.141592;
    //vec2 disp = vec2(cos(a),sin(a))*.5 - vec2(.0, .5);
    vec2 disp = vec2(0., mix(.0, -1., t));
    uv -= disp;
    ang = mix(.0, -3.141592/2., t);//3.141592*1./2.;
    m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    uv *= m;
    s = mix(1., 1./SIZE, t);
    uv *= s; //SIZE;
    scale *= s;
    
    vec3 col = vec3(0);    
    float d = 1000.;
    for (float i=0.; i<16.; i++) {
        d = min(d, length(uv - vec2(clamp(uv.x,-.5,.5), 0.))/scale);
        //if (abs(uv.y)<.002*scale && uv.x>0. && uv.x<.5) col = vec3(1,0,0);
          //if (abs(uv.x)<.002*scale && uv.y>0. && uv.y<.5) col = vec3(0,1,0);
        uv = foldUVs(uv);
        scale *= SIZE;
    }
    //col.x = d*10.;
    col.x = smoothstep(2./resolution.y,0.0,d);
    //col.y = uv.y;
    
    glFragColor = vec4(col,1.0);
}
